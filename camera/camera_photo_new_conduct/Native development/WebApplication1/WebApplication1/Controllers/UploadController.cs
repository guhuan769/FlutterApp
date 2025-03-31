using Microsoft.AspNetCore.Mvc;
using PlyFileProcessor.Services;
using System.Net;
using System.Text.Json;
using System.Collections.Concurrent;
using System.Security.Cryptography;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace PlyFileProcessor.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UploadController : ControllerBase
    {
        private readonly ILogger<UploadController> _logger;
        private readonly IPlyFileService _plyFileService;
        private readonly IMqttClientService _mqttClientService;
        private readonly string _uploadFolder;
        private readonly HashSet<string> _allowedExtensions = new HashSet<string> { ".jpg", ".jpeg" };

        // 添加会话管理
        private static ConcurrentDictionary<string, UploadSession> _activeSessions = new ConcurrentDictionary<string, UploadSession>();
        private static ConcurrentDictionary<string, string> _processedFileHashes = new ConcurrentDictionary<string, string>();

        public UploadController(
            ILogger<UploadController> logger,
            IPlyFileService plyFileService,
            IMqttClientService mqttClientService,
            IConfiguration configuration)
        {
            _logger = logger;
            _plyFileService = plyFileService;
            _mqttClientService = mqttClientService;
            _uploadFolder = configuration.GetValue<string>("UploadFolder") ?? Path.Combine(Directory.GetCurrentDirectory(), "Uploads");

            // 确保上传根目录存在
                if (!Directory.Exists(_uploadFolder))
                {
                    Directory.CreateDirectory(_uploadFolder);
            }
        }

        [HttpPost("/upload")]
        [RequestSizeLimit(100 * 1024 * 1024)] // 100MB
        [RequestFormLimits(MultipartBodyLengthLimit = 100 * 1024 * 1024)] // 100MB
        public async Task<IActionResult> UploadImage()
        {
            var taskId = Guid.NewGuid().ToString();
            var clientIp = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
            _logger.LogInformation("收到上传请求 - TaskID: {TaskId}", taskId);
            _logger.LogInformation("客户端IP: {ClientIp}", clientIp);

            // 用于跟踪处理结果的数据结构
            var savedFiles = new List<Dictionary<string, object>>();
            var failedFiles = new List<Dictionary<string, object>>();

            try
            {
                // 获取基本信息
                if (!int.TryParse(Request.Form["batch_number"], out int batchNumber))
                {
                    batchNumber = 1;
                    _logger.LogWarning("批次号未提供或格式错误，使用默认值 1");
                }

                if (!int.TryParse(Request.Form["total_batches"], out int totalBatches))
                {
                    totalBatches = 1;
                    _logger.LogWarning("总批次数未提供或格式错误，使用默认值 1");
                }

                int expectedFilesCount = 0;
                if (Request.Form.ContainsKey("expected_files_count") && 
                    int.TryParse(Request.Form["expected_files_count"], out int expected))
                {
                    expectedFilesCount = expected;
                    _logger.LogInformation("客户端预期文件数量: {ExpectedCount}", expectedFilesCount);
                }

                var uploadType = Request.Form["type"].ToString() ?? "";
                var uploadValue = Request.Form["value"].ToString() ?? "";

                // 解析项目信息
                Dictionary<string, object> projectInfo = new Dictionary<string, object>();
                if (Request.Form.ContainsKey("project_info"))
                {
                    try
                    {
                        using (JsonDocument doc = JsonDocument.Parse(Request.Form["project_info"]))
                        {
                            JsonElement root = doc.RootElement;
                            foreach (JsonProperty property in root.EnumerateObject())
                            {
                                projectInfo[property.Name] = property.Value.ToString();
                            }
                        }
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "解析项目信息JSON失败");
                        projectInfo = new Dictionary<string, object>();
                    }
                }

                _logger.LogInformation("批次: {BatchNumber}/{TotalBatches}", batchNumber, totalBatches);
                _logger.LogInformation("上传类型: {UploadType}", uploadType);
                _logger.LogInformation("上传值: {UploadValue}", uploadValue);
                _logger.LogInformation("项目信息: {ProjectInfo}", JsonSerializer.Serialize(projectInfo));

                // 创建保存目录结构
                var categoryFolder = uploadType == "model" ? "模型" : "工艺";
                var baseSavePath = Path.Combine(_uploadFolder, categoryFolder, uploadValue);
                var projectName = projectInfo.ContainsKey("name") ?
                    projectInfo["name"].ToString() : "unknown_project";
                var projectDir = Path.Combine(baseSavePath, projectName);
                var unifiedImagesDir = Path.Combine(projectDir, "all_images");

                // 确保目录存在
                EnsureDirectoriesExist(projectDir, unifiedImagesDir);

                // 如果是第一批次，清理原有文件
                if (batchNumber == 1)
                {
                    _logger.LogInformation("开始清理现有文件...");
                    CleanupExistingFiles(projectDir, unifiedImagesDir);
                    _logger.LogInformation("清理完成");
                }

                // 处理上传的文件
                var files = Request.Form.Files;
                _logger.LogInformation("实际接收到文件数量: {Count}", files.Count);

                if (files.Count == 0)
                {
                    return BadRequest(new
                    {
                        code = 400,
                        message = "没有接收到文件"
                    });
                }

                // 验证接收到的文件数量与预期是否一致
                if (expectedFilesCount > 0 && files.Count != expectedFilesCount)
                {
                    _logger.LogWarning("文件数量不匹配：预期 {Expected}，实际接收 {Actual}", 
                        expectedFilesCount, files.Count);
                }

                // 临时存储所有文件信息
                var fileInfoList = new List<(string TempPath, string OriginalName, string Type, Dictionary<string, string> Info)>();

                // 第一步：保存所有文件到临时位置
                for (int i = 0; i < files.Count; i++)
                {
                    var file = files[i];
                    var fileName = file.FileName;
                    var fileInfoKey = $"file_info_{i}";
                    Dictionary<string, string> fileInfo = new Dictionary<string, string>();

                    // 解析文件信息
                    if (Request.Form.ContainsKey(fileInfoKey))
                    {
                        try
                        {
                            using (JsonDocument doc = JsonDocument.Parse(Request.Form[fileInfoKey]))
                            {
                                JsonElement root = doc.RootElement;
                                foreach (JsonProperty property in root.EnumerateObject())
                                {
                                    fileInfo[property.Name] = property.Value.ToString();
                                }
                            }
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "解析文件信息失败: {FileInfoKey}", fileInfoKey);
                        }
                    }

                    // 获取文件类型
                    var fileType = fileInfo.ContainsKey("type") ? fileInfo["type"] : "unknown";
                    
                    // 临时文件名和路径
                    var tempFileName = $"temp_{i}_{Guid.NewGuid().ToString("N").Substring(0, 8)}_{fileName}";
                    var tempFilePath = Path.Combine(unifiedImagesDir, tempFileName);

                    try
                    {
                        // 保存临时文件
                        using (var stream = System.IO.File.Create(tempFilePath))
                        {
                            await file.CopyToAsync(stream);
                        }

                        // 添加到处理列表
                        fileInfoList.Add((tempFilePath, fileName, fileType, fileInfo));
                        _logger.LogInformation("已保存临时文件 {Index}: {FileName}", i, fileName);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "保存临时文件失败 {Index}: {FileName}", i, fileName);
                        failedFiles.Add(new Dictionary<string, object>
                        {
                            { "fileName", fileName },
                            { "error", ex.Message }
                        });
                    }
                }

                // 验证所有文件是否已保存
                if (fileInfoList.Count != files.Count)
                {
                    _logger.LogError("部分文件保存失败: 预期 {Expected}，实际保存 {Actual}", 
                        files.Count, fileInfoList.Count);
                }

                // 第二步：从11开始重命名文件并创建清单
                var imageListPath = Path.Combine(unifiedImagesDir, "image_list.txt");
                var imageListEntries = new List<string>
                {
                    "# 图片清单文件",
                    "# 格式: 序号\t原文件名\t新文件名"
                };

                int fileIndex = 11; // 从11开始命名
                
                foreach (var (tempPath, originalName, fileType, fileInfo) in fileInfoList)
                {
                    try
                    {
                        // 新文件名和路径
                        string newFileName = $"{fileIndex}.jpg";
                        string newFilePath = Path.Combine(unifiedImagesDir, newFileName);
                        
                        // 重命名临时文件
                        System.IO.File.Move(tempPath, newFilePath, true);
                        
                        // 添加到清单
                        imageListEntries.Add($"{fileIndex}\t{originalName}\t{newFileName}");
                        
                        // 根据文件类型复制到特定目录
                        string specificPath;
                        if (fileType == "project")
                        {
                            specificPath = Path.Combine(projectDir, newFileName);
                        }
                        else if (fileType == "vehicle" && fileInfo.ContainsKey("vehicleId"))
                        {
                            var vehicleDir = Path.Combine(projectDir, "vehicles", fileInfo["vehicleId"]);
                            Directory.CreateDirectory(vehicleDir);
                            specificPath = Path.Combine(vehicleDir, newFileName);
                        }
                        else if (fileType == "track" && fileInfo.ContainsKey("vehicleId") && fileInfo.ContainsKey("trackId"))
                        {
                            var trackDir = Path.Combine(projectDir, "vehicles", fileInfo["vehicleId"], "tracks", fileInfo["trackId"]);
                            Directory.CreateDirectory(trackDir);
                            specificPath = Path.Combine(trackDir, newFileName);
                        }
                        else
                        {
                            specificPath = Path.Combine(projectDir, newFileName);
                        }
                        
                        // 复制到特定目录
                        System.IO.File.Copy(newFilePath, specificPath, true);
                        
                        // 记录成功
                        savedFiles.Add(new Dictionary<string, object>
                        {
                            { "fileName", originalName },
                            { "newFileName", newFileName },
                            { "index", fileIndex },
                            { "path", specificPath }
                        });
                        
                        fileIndex++;
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "处理文件 {FileName} 失败", originalName);
                        failedFiles.Add(new Dictionary<string, object>
                        {
                            { "fileName", originalName },
                            { "error", ex.Message }
                        });
                    }
                }

                // 保存清单文件
                await System.IO.File.WriteAllLinesAsync(imageListPath, imageListEntries);
                _logger.LogInformation("已生成图片清单，包含 {Count} 条记录", imageListEntries.Count - 2);

                // 返回结果
                return Ok(new
                {
                    code = 200,
                    message = $"成功处理 {savedFiles.Count}/{files.Count} 个文件",
                    data = new
                    {
                        savedFiles,
                        failedFiles,
                        imageList = imageListEntries.Skip(2).Take(Math.Min(10, imageListEntries.Count - 2)).ToList(),
                        totalFiles = files.Count,
                        processedFiles = savedFiles.Count,
                        serverConfirmedCount = savedFiles.Count
                    },
                    sessionId = taskId
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "上传处理失败");
                return StatusCode(500, new
                {
                    code = 500,
                    error = "UPLOAD_ERROR",
                    message = ex.Message,
                    details = ex.StackTrace
                });
            }
        }

        // 确保目录存在
        private void EnsureDirectoriesExist(string projectDir, string unifiedImagesDir)
        {
            Directory.CreateDirectory(projectDir);
            Directory.CreateDirectory(unifiedImagesDir);
        }

        // 清理现有文件
        private void CleanupExistingFiles(string projectDir, string unifiedImagesDir)
        {
            // 清理统一图片目录中的文件
            if (Directory.Exists(unifiedImagesDir))
            {
                foreach (var file in Directory.GetFiles(unifiedImagesDir, "*.jpg")
                             .Concat(Directory.GetFiles(unifiedImagesDir, "*.jpeg")))
                {
                    try
                    {
                        System.IO.File.Delete(file);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "无法删除文件: {FilePath}", file);
                    }
                }
            }

            // 清理项目目录中的图片
            foreach (var file in Directory.GetFiles(projectDir, "*.jpg")
                         .Concat(Directory.GetFiles(projectDir, "*.jpeg")))
            {
                try
                {
                    System.IO.File.Delete(file);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "无法删除文件: {FilePath}", file);
                }
            }

            // 清理车辆和轨迹目录中的图片
            var vehiclesDir = Path.Combine(projectDir, "vehicles");
            if (Directory.Exists(vehiclesDir))
            {
                foreach (var vehicleDir in Directory.GetDirectories(vehiclesDir))
                {
                    // 清理车辆目录图片
                    foreach (var file in Directory.GetFiles(vehicleDir, "*.jpg")
                                 .Concat(Directory.GetFiles(vehicleDir, "*.jpeg")))
                    {
                        try
                        {
                            System.IO.File.Delete(file);
                        }
                        catch { }
                    }

                    // 清理轨迹目录图片
                    var tracksDir = Path.Combine(vehicleDir, "tracks");
                    if (Directory.Exists(tracksDir))
                    {
                        foreach (var trackDir in Directory.GetDirectories(tracksDir))
                        {
                            foreach (var file in Directory.GetFiles(trackDir, "*.jpg")
                                         .Concat(Directory.GetFiles(trackDir, "*.jpeg")))
                            {
                                try
                                {
                                    System.IO.File.Delete(file);
                                }
                                catch { }
                            }
                        }
                    }
                }
            }

            // 删除图片清单文件
            var imageListFile = Path.Combine(unifiedImagesDir, "image_list.txt");
            if (System.IO.File.Exists(imageListFile))
            {
                try
                {
                    System.IO.File.Delete(imageListFile);
                }
                catch { }
            }
        }

        [HttpGet("/check-directory")]
        public IActionResult CheckDirectory([FromQuery] string type, [FromQuery] string value, [FromQuery] string project)
        {
            try
            {
                _logger.LogInformation("检查目录结构 - 类型: {Type}, 值: {Value}, 项目: {Project}", type, value, project);
                
                // 创建保存目录结构
                var categoryFolder = type == "model" ? "模型" : "工艺";
                var baseSavePath = Path.Combine(_uploadFolder, categoryFolder, value);
                var projectDir = Path.Combine(baseSavePath, project);
                var imagesDir = Path.Combine(projectDir, "all_images");
                
                bool directoryExists = Directory.Exists(projectDir);
                bool hasWritePermission = false;
                bool directoryCreated = false;
                
                if (!directoryExists)
        {
            try
            {
                        // 创建必要的目录
                            Directory.CreateDirectory(baseSavePath);
                            Directory.CreateDirectory(projectDir);
                        Directory.CreateDirectory(imagesDir);
                        directoryCreated = true;
                        
                        // 创建临时文件测试写入权限
                        var testFilePath = Path.Combine(projectDir, "write_test.tmp");
                        System.IO.File.WriteAllText(testFilePath, "write test");
                            System.IO.File.Delete(testFilePath);
                        hasWritePermission = true;
            }
            catch (Exception ex)
            {
                        _logger.LogError(ex, "创建目录失败");
                        return Ok(new
                        {
                            directory_exists = false,
                            directory_created = false,
                            has_write_permission = false,
                            message = $"创建目录失败: {ex.Message}"
                        });
            }
                }
                else
        {
            try
            {
                        // 验证写入权限
                        var testFilePath = Path.Combine(projectDir, "write_test.tmp");
                        System.IO.File.WriteAllText(testFilePath, "write test");
                        System.IO.File.Delete(testFilePath);
                        hasWritePermission = true;
            }
            catch (Exception ex)
            {
                        _logger.LogWarning(ex, "验证写入权限失败");
                        hasWritePermission = false;
                        }
                    
                    // 确保统一图片目录存在
                    if (!Directory.Exists(imagesDir))
                {
                    try
                    {
                            Directory.CreateDirectory(imagesDir);
                    }
                    catch (Exception ex)
                    {
                            _logger.LogError(ex, "创建统一图片目录失败");
                    }
                }
                }
                
                return Ok(new
                {
                    directory_exists = directoryExists,
                    directory_created = directoryCreated,
                    has_write_permission = hasWritePermission
                });
                    }
                    catch (Exception ex)
                    {
                _logger.LogError(ex, "检查目录结构失败");
                return StatusCode(500, new
                {
                    error = "CHECK_DIRECTORY_ERROR",
                    message = ex.Message
                });
                        }
                    }

        private string GetClientIpAddress()
        {
            return HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        }
    }

    // 上传会话类
    public class UploadSession
    {
        public string SessionId { get; set; }
        public Dictionary<string, FileStatus> Files { get; set; } = new Dictionary<string, FileStatus>();
        public DateTime LastActivity { get; set; } = DateTime.Now;
        public string ProjectName { get; set; } = "unknown_project";
    }

    // 文件状态类
    public class FileStatus
    {
        public string FileName { get; set; }
        public string FilePath { get; set; }
        public bool IsSuccess { get; set; }
        public DateTime ProcessTime { get; set; } = DateTime.Now;
        public string ErrorMessage { get; set; } = "";
    }
}