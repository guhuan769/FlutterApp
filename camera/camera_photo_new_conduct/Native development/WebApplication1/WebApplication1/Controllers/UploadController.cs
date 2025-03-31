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
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
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

                // 获取重试计数（如果有）
                if (!int.TryParse(Request.Form["retry_count"], out int retryCount))
                {
                    retryCount = 0;
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

                // 使用锁确保目录创建的原子性
                var lockObject = new object();
                lock (lockObject)
                {
                    // 检查并创建必要的目录
                    try
                    {
                        if (!Directory.Exists(_uploadFolder))
                        {
                            Directory.CreateDirectory(_uploadFolder);
                            _logger.LogInformation("创建上传根目录: {UploadFolder}", _uploadFolder);
                        }

                        if (!Directory.Exists(baseSavePath))
                        {
                            Directory.CreateDirectory(baseSavePath);
                            _logger.LogInformation("创建分类目录: {BaseSavePath}", baseSavePath);
                        }

                        if (!Directory.Exists(projectDir))
                        {
                            Directory.CreateDirectory(projectDir);
                            _logger.LogInformation("创建项目目录: {ProjectDir}", projectDir);
                        }

                        // 创建统一存放图片的目录
                        var unifiedImagesDir = Path.Combine(projectDir, "all_images");
                        if (!Directory.Exists(unifiedImagesDir))
                        {
                            Directory.CreateDirectory(unifiedImagesDir);
                            _logger.LogInformation("创建统一图片目录: {UnifiedImagesDir}", unifiedImagesDir);
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "创建目录结构失败");
                        return StatusCode(500, new
                        {
                            code = 500,
                            error = "DIRECTORY_CREATE_ERROR",
                            message = "创建目录结构失败，请重试",
                            details = ex.Message
                        });
                    }
                }

                // 处理上传的文件
                var files = Request.Form.Files;
                if (files.Count == 0)
                {
                    _logger.LogWarning("没有接收到文件");
                    return BadRequest(new
                    {
                        code = 400,
                        message = "没有接收到文件"
                    });
                }

                _logger.LogInformation("接收到 {FileCount} 个文件", files.Count);
                
                // 处理文件上传
                for (int i = 0; i < files.Count; i++)
                {
                    var file = files[i];
                    var fileInfoJson = Request.Form[$"file_info_{i}"].ToString();
                    Dictionary<string, string> fileInfo = new Dictionary<string, string>();
                    
                    try
                    {
                        if (!string.IsNullOrEmpty(fileInfoJson))
                        {
                            using (JsonDocument doc = JsonDocument.Parse(fileInfoJson))
                            {
                                JsonElement root = doc.RootElement;
                                foreach (JsonProperty property in root.EnumerateObject())
                                {
                                    fileInfo[property.Name] = property.Value.ToString();
                                }
                            }
                        }
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "解析文件信息JSON失败: {FileInfoJson}", fileInfoJson);
                    }

                    // 获取文件类型和相对路径
                    var fileType = fileInfo.ContainsKey("type") ? fileInfo["type"] : "unknown";
                    var relativePath = fileInfo.ContainsKey("relativePath") ? fileInfo["relativePath"] : file.FileName;
                    
                    // 构建文件保存路径
                    string savePath;
                    string uniqueFileName = $"{DateTime.Now.ToString("yyyyMMddHHmmssfff")}_{Guid.NewGuid().ToString("N").Substring(0, 8)}_{Path.GetFileName(file.FileName)}";
                    
                    // 统一目录的保存路径
                    var unifiedImagePath = Path.Combine(projectDir, "all_images", uniqueFileName);
                    
                    try
                    {
                        // 保存到统一目录
                        using (var stream = new FileStream(unifiedImagePath, FileMode.Create))
                        {
                            await file.CopyToAsync(stream);
                        }
                        
                        // 判断文件类型，确定是否需要额外保存到特定目录
                        if (fileType == "project")
                        {
                            // 项目级别照片直接保存在项目目录
                            savePath = Path.Combine(projectDir, uniqueFileName);
                        }
                        else if (fileType == "vehicle" && fileInfo.ContainsKey("vehicleId"))
                        {
                            // 创建车辆目录
                            var vehicleDir = Path.Combine(projectDir, "vehicles", fileInfo["vehicleId"]);
                            if (!Directory.Exists(vehicleDir))
                            {
                                Directory.CreateDirectory(vehicleDir);
                            }
                            savePath = Path.Combine(vehicleDir, uniqueFileName);
                        }
                        else if (fileType == "track" && fileInfo.ContainsKey("vehicleId") && fileInfo.ContainsKey("trackId"))
                        {
                            // 创建轨迹目录
                            var trackDir = Path.Combine(projectDir, "vehicles", fileInfo["vehicleId"], "tracks", fileInfo["trackId"]);
                            if (!Directory.Exists(trackDir))
                            {
                                Directory.CreateDirectory(trackDir);
                            }
                            savePath = Path.Combine(trackDir, uniqueFileName);
                        }
                        else
                        {
                            // 默认保存到项目根目录
                            savePath = Path.Combine(projectDir, uniqueFileName);
                        }
                        
                        // 同时保存到特定目录
                        using (var stream = new FileStream(savePath, FileMode.Create))
                        {
                            using (var unifiedStream = new FileStream(unifiedImagePath, FileMode.Open))
                            {
                                await unifiedStream.CopyToAsync(stream);
                            }
                        }
                        
                        _logger.LogInformation("文件 {FileName} 已保存到 {SavePath} 和统一目录", file.FileName, savePath);
                        
                        // 记录成功保存的文件
                        savedFiles.Add(new Dictionary<string, object>
                        {
                            { "fileName", file.FileName },
                            { "savedPath", savePath },
                            { "unifiedPath", unifiedImagePath },
                            { "fileSize", file.Length },
                            { "fileType", fileType },
                            { "fileInfo", fileInfo }
                        });
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "保存文件 {FileName} 失败", file.FileName);
                        
                        // 记录失败的文件
                        failedFiles.Add(new Dictionary<string, object>
                        {
                            { "fileName", file.FileName },
                            { "error", ex.Message },
                            { "fileInfo", fileInfo }
                        });
                    }
                }

                // 返回处理结果
                return Ok(new
                {
                    code = 200,
                    message = "文件上传成功",
                    data = new { 
                        savedFiles, 
                        failedFiles,
                        serverConfirmedCount = savedFiles.Count
                    },
                    sessionId = taskId  // 返回任务ID作为会话标识
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "处理文件上传时发生错误");
                return StatusCode(500, new
                {
                    code = 500,
                    error = "UPLOAD_ERROR",
                    message = "处理文件上传时发生错误，请重试",
                    details = ex.Message
                });
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