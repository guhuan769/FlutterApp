using Microsoft.AspNetCore.Mvc;
using PlyFileProcessor.Services;
using System.Net;
using System.Text.Json;
using System.Collections.Concurrent;
using System.Security.Cryptography;

namespace PlyFileProcessor.Controllers
{
    [ApiController]
    [Produces("application/json")]
    public class UploadController : ControllerBase
    {
        private readonly ILogger<UploadController> _logger;
        private readonly IPlyFileService _plyFileService;
        private readonly IMqttClientService _mqttClientService;
        private readonly string _uploadFolder = "uploaded_images";
        private readonly HashSet<string> _allowedExtensions = new HashSet<string> { ".jpg", ".jpeg" };

        // 添加会话管理
        private static ConcurrentDictionary<string, UploadSession> _activeSessions = new ConcurrentDictionary<string, UploadSession>();
        private static ConcurrentDictionary<string, string> _processedFileHashes = new ConcurrentDictionary<string, string>();

        public UploadController(
            ILogger<UploadController> logger,
            IPlyFileService plyFileService,
            IMqttClientService mqttClientService)
        {
            _logger = logger;
            _plyFileService = plyFileService;
            _mqttClientService = mqttClientService;

            // 确保上传目录存在
            Directory.CreateDirectory(_uploadFolder);
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
            var clientIp = GetClientIpAddress();
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

                // 解析项目信息 - 改进的JSON解析
                Dictionary<string, object> projectInfo = new Dictionary<string, object>();
                if (Request.Form.ContainsKey("project_info"))
                {
                    try
                    {
                        // 使用JsonDocument处理复杂JSON结构
                        using (JsonDocument doc = JsonDocument.Parse(Request.Form["project_info"]))
                        {
                            JsonElement root = doc.RootElement;

                            foreach (JsonProperty property in root.EnumerateObject())
                            {
                                string propertyName = property.Name;

                                switch (property.Value.ValueKind)
                                {
                                    case JsonValueKind.String:
                                        projectInfo[propertyName] = property.Value.GetString();
                                        break;
                                    case JsonValueKind.Number:
                                        projectInfo[propertyName] = property.Value.GetDouble().ToString();
                                        break;
                                    case JsonValueKind.True:
                                        projectInfo[propertyName] = "true";
                                        break;
                                    case JsonValueKind.False:
                                        projectInfo[propertyName] = "false";
                                        break;
                                    case JsonValueKind.Array:
                                        // 将数组序列化为JSON字符串
                                        projectInfo[propertyName] = JsonSerializer.Serialize(property.Value);
                                        break;
                                    case JsonValueKind.Object:
                                        // 将嵌套对象序列化为JSON字符串
                                        projectInfo[propertyName] = JsonSerializer.Serialize(property.Value);
                                        break;
                                }
                            }
                        }
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "解析项目信息JSON失败，将使用空对象");
                        projectInfo = new Dictionary<string, object>();
                    }
                }

                _logger.LogInformation("批次: {BatchNumber}/{TotalBatches}", batchNumber, totalBatches);
                _logger.LogInformation("上传类型: {UploadType}", uploadType);
                _logger.LogInformation("上传值: {UploadValue}", uploadValue);
                _logger.LogInformation("项目信息: {ProjectInfo}", JsonSerializer.Serialize(projectInfo));

                if (retryCount > 0)
                {
                    _logger.LogInformation("重试上传: 第 {RetryCount} 次尝试", retryCount);
                }

                // 创建或获取上传会话
                var sessionId = Request.Form.ContainsKey("session_id") ?
                    Request.Form["session_id"].ToString() :
                    $"{uploadType}_{uploadValue}_{DateTime.Now:yyyyMMddHHmmss}";

                var session = _activeSessions.GetOrAdd(sessionId, new UploadSession
                {
                    SessionId = sessionId,
                    ProjectName = projectInfo.ContainsKey("name") ? projectInfo["name"].ToString() : "unknown_project",
                    LastActivity = DateTime.Now
                });

                // 创建保存目录结构
                var categoryFolder = uploadType == "model" ? "模型" : "工艺";
                var baseSavePath = Path.Combine(_uploadFolder, categoryFolder, uploadValue);
                var projectName = projectInfo.ContainsKey("name") ?
                    projectInfo["name"].ToString() : "unknown_project";
                var projectDir = Path.Combine(baseSavePath, projectName);

                Directory.CreateDirectory(baseSavePath);
                Directory.CreateDirectory(projectDir);

                // 创建统一存放图片的目录
                var unifiedImagesDir = Path.Combine(projectDir, "all_images");
                Directory.CreateDirectory(unifiedImagesDir);

                // 创建/更新图片清单文件
                var imageListPath = Path.Combine(unifiedImagesDir, "image_list.txt");
                var imageList = new List<string>();

                // 首先读取已有的清单文件（如果存在）
                if (System.IO.File.Exists(imageListPath))
                {
                    try
                    {
                        var existingLines = await System.IO.File.ReadAllLinesAsync(imageListPath);
                        var existingEntries = new Dictionary<string, int>();

                        foreach (var line in existingLines)
                        {
                            var parts = line.Split('\t');
                            if (parts.Length == 2 && int.TryParse(parts[0], out int num))
                            {
                                existingEntries[parts[1]] = num;
                                imageList.Add(line);
                            }
                        }

                        _logger.LogInformation("已从现有清单中读取 {Count} 个文件条目", existingEntries.Count);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "读取现有图片清单文件失败，将创建新清单");
                        imageList.Clear();
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
                        message = "没有接收到文件",
                        session_id = sessionId
                    });
                }

                _logger.LogInformation("接收到 {FileCount} 个文件", files.Count);

                for (int i = 0; i < files.Count; i++)
                {
                    try
                    {
                        var file = files[i];
                        if (file.Length == 0)
                        {
                            _logger.LogWarning("文件 {FileName} 为空", file.FileName);
                            failedFiles.Add(new Dictionary<string, object> {
                                { "name", file.FileName },
                                { "error", "文件为空" }
                            });
                            continue;
                        }

                        // 获取文件扩展名并验证
                        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
                        if (!_allowedExtensions.Contains(extension))
                        {
                            _logger.LogWarning("文件 {FileName} 的扩展名 {Extension} 不允许", file.FileName, extension);
                            failedFiles.Add(new Dictionary<string, object> {
                                { "name", file.FileName },
                                { "error", $"不支持的文件类型: {extension}" }
                            });
                            continue;
                        }

                        // 计算文件哈希，用于重复检测
                        string fileHash = ComputeFileHash(file);

                        // 检查是否已处理过相同的文件
                        if (_processedFileHashes.TryGetValue(fileHash, out string existingFilePath))
                        {
                            _logger.LogInformation("文件 {FileName} 哈希 {FileHash} 已存在于 {ExistingPath}",
                                file.FileName, fileHash, existingFilePath);

                            // 将此文件记录为已处理
                            savedFiles.Add(new Dictionary<string, object> {
                                { "name", file.FileName },
                                { "hash", fileHash },
                                { "path", existingFilePath },
                                { "duplicate", true },
                                { "status", "success" }
                            });

                            continue;
                        }

                        // 获取文件唯一标识符（如果客户端提供）
                        string fileUniqueId = ExtractFileUniqueId(Request.Form, i);

                        // 检查会话中是否已处理过此文件
                        if (session.Files.ContainsKey(fileUniqueId))
                        {
                            var existingFile = session.Files[fileUniqueId];
                            if (existingFile.IsSuccess)
                            {
                                _logger.LogInformation("文件唯一ID {UniqueId} 已成功处理，跳过处理", fileUniqueId);

                                savedFiles.Add(new Dictionary<string, object> {
                                    { "name", file.FileName },
                                    { "unique_id", fileUniqueId },
                                    { "path", existingFile.FilePath },
                                    { "already_processed", true },
                                    { "status", "success" }
                                });

                                continue;
                            }
                            else
                            {
                                _logger.LogInformation("文件唯一ID {UniqueId} 之前处理失败，重新尝试", fileUniqueId);
                            }
                        }

                        // 验证图片文件
                        try
                        {
                            using var stream = file.OpenReadStream();
                            using var image = Image.Load(stream);
                            _logger.LogInformation("文件 {FileName} 验证成功，尺寸: {Width}x{Height}",
                                file.FileName, image.Width, image.Height);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "无效的图片文件 {FileName}", file.FileName);
                            failedFiles.Add(new Dictionary<string, object> {
                                { "name", file.FileName },
                                { "error", "无效的图片文件" },
                                { "details", ex.Message }
                            });

                            // 记录到会话
                            session.Files[fileUniqueId] = new FileStatus
                            {
                                FileName = file.FileName,
                                IsSuccess = false,
                                ProcessTime = DateTime.Now,
                                ErrorMessage = $"无效的图片文件: {ex.Message}"
                            };

                            continue;
                        }

                        // 获取文件信息
                        var fileInfoKey = $"file_info_{i}";
                        Dictionary<string, string> fileInfo = new Dictionary<string, string>();

                        if (Request.Form.ContainsKey(fileInfoKey))
                        {
                            try
                            {
                                fileInfo = JsonSerializer.Deserialize<Dictionary<string, string>>(Request.Form[fileInfoKey])
                                    ?? new Dictionary<string, string>();
                            }
                            catch (JsonException ex)
                            {
                                _logger.LogError(ex, "解析文件信息JSON失败: {FileInfoKey}", fileInfoKey);
                                fileInfo = new Dictionary<string, string>();
                            }
                        }

                        // 根据不同类型确定保存路径
                        string savePath;
                        string prefix = ""; // 为统一目录中的文件添加前缀
                        var fileType = fileInfo.GetValueOrDefault("type", "project");

                        switch (fileType)
                        {
                            case "vehicle":
                                // 车辆照片保存在vehicles/车辆名称目录下
                                var vehicleName = fileInfo.GetValueOrDefault("vehicleName", "unknown_vehicle");
                                var vehicleDir = Path.Combine(projectDir, "vehicles", vehicleName);
                                Directory.CreateDirectory(vehicleDir);
                                savePath = Path.Combine(vehicleDir,
                                    Path.GetFileName(fileInfo.GetValueOrDefault("relativePath", file.FileName)));
                                prefix = $"vehicle_{vehicleName}_"; // 添加前缀
                                _logger.LogInformation("文件 {FileName} 将保存为vehicle: {VehicleName}",
                                    file.FileName, vehicleName);
                                break;

                            case "track":
                                // 轨迹照片保存在vehicles/车辆名称/tracks/轨迹名称目录下
                                var trackVehicleName = fileInfo.GetValueOrDefault("vehicleName", "unknown_vehicle");
                                var trackName = fileInfo.GetValueOrDefault("trackName", "unknown_track");
                                var trackDir = Path.Combine(projectDir, "vehicles", trackVehicleName, "tracks", trackName);
                                Directory.CreateDirectory(trackDir);
                                savePath = Path.Combine(trackDir,
                                    Path.GetFileName(fileInfo.GetValueOrDefault("relativePath", file.FileName)));
                                prefix = $"track_{trackVehicleName}_{trackName}_"; // 添加前缀
                                _logger.LogInformation("文件 {FileName} 将保存为track: {VehicleName}/{TrackName}",
                                    file.FileName, trackVehicleName, trackName);
                                break;

                            default: // "project" 或其他类型
                                // 项目照片保存在项目根目录
                                savePath = Path.Combine(projectDir,
                                    Path.GetFileName(fileInfo.GetValueOrDefault("relativePath", file.FileName)));
                                prefix = "project_"; // 添加前缀
                                _logger.LogInformation("文件 {FileName} 将保存到项目根目录", file.FileName);
                                break;
                        }

                        // 创建必要的目录
                        Directory.CreateDirectory(Path.GetDirectoryName(savePath));

                        // 保存文件到原始路径
                        using (var stream = new FileStream(savePath, FileMode.Create))
                        {
                            await file.CopyToAsync(stream);
                            _logger.LogInformation("文件 {FileName} 已保存到 {SavePath}", file.FileName, savePath);
                        }

                        // 保存文件到统一目录，添加前缀
                        var originalFileName = Path.GetFileName(fileInfo.GetValueOrDefault("relativePath", file.FileName));
                        var unifiedFileName = $"{prefix}{originalFileName}";
                        var unifiedSavePath = Path.GetFullPath(Path.Combine(unifiedImagesDir, unifiedFileName));

                        using (var stream = new FileStream(unifiedSavePath, FileMode.Create))
                        {
                            await file.CopyToAsync(stream);
                            _logger.LogInformation("文件 {FileName} 已保存到统一目录 {SavePath}", file.FileName, unifiedSavePath);
                        }

                        // 检查文件是否已在清单中
                        var existingIndex = imageList.FindIndex(line => line.EndsWith($"\t{unifiedFileName}"));

                        if (existingIndex == -1)
                        {
                            // 文件不在清单中，添加新条目
                            imageList.Add($"{imageList.Count + 1}\t{unifiedFileName}");
                            _logger.LogInformation("文件 {FileName} 已添加到图片清单", unifiedFileName);
                        }
                        else
                        {
                            _logger.LogInformation("文件 {FileName} 已存在于图片清单中", unifiedFileName);
                        }

                        // 记录处理后的文件信息
                        _processedFileHashes[fileHash] = savePath;

                        // 记录到会话
                        session.Files[fileUniqueId] = new FileStatus
                        {
                            FileName = file.FileName,
                            FilePath = savePath,
                            IsSuccess = true,
                            ProcessTime = DateTime.Now
                        };

                        // 记录成功信息
                        savedFiles.Add(new Dictionary<string, object> {
                            { "name", file.FileName },
                            { "hash", fileHash },
                            { "unique_id", fileUniqueId },
                            { "path", savePath },
                            { "unified_path", unifiedSavePath },
                            { "size", file.Length },
                            { "type", fileType },
                            { "status", "success" }
                        });
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "处理文件失败 {FileName}", files[i].FileName);

                        // 文件唯一ID
                        string fileUniqueId = ExtractFileUniqueId(Request.Form, i);

                        // 记录到会话
                        session.Files[fileUniqueId] = new FileStatus
                        {
                            FileName = files[i].FileName,
                            IsSuccess = false,
                            ProcessTime = DateTime.Now,
                            ErrorMessage = ex.Message
                        };

                        failedFiles.Add(new Dictionary<string, object> {
                            { "name", files[i].FileName },
                            { "unique_id", fileUniqueId },
                            { "error", ex.Message },
                            { "error_type", ex.GetType().Name },
                            { "status", "failed" }
                        });
                    }
                }

                // 确保清单排序正确
                if (imageList.Count > 0)
                {
                    // 执行彻底解决方案 - 保证收集所有相关目录中的图片
                    await PerformComprehensiveImageProcessing(unifiedImagesDir, projectDir, imageList);
                }
                else
                {
                    // 扫描目录中的所有图片，确保没有遗漏
                    await PerformComprehensiveImageProcessing(unifiedImagesDir, projectDir, new List<string>());
                }

                // 写入上传状态文件，但保持API返回简单
                var statusInfo = new Dictionary<string, object> {
                    { "batch_number", batchNumber },
                    { "total_batches", totalBatches },
                    { "saved_files", savedFiles.Count },
                    { "total_files", files.Count },
                    { "success_rate", $"{savedFiles.Count}/{files.Count} ({(files.Count > 0 ? Math.Round(100.0 * savedFiles.Count / files.Count, 1) : 0)}%)" },
                    { "upload_status", savedFiles.Count == files.Count ? "上传完成" : "上传部分完成" },
                    { "session_id", sessionId },
                    { "timestamp", DateTime.Now.ToString("O") },
                    { "retry_count", retryCount },
                    { "success_details", savedFiles },
                    { "failure_details", failedFiles }
                };

                var statusFilePath = Path.Combine(projectDir, $"upload_status_{batchNumber}.json");
                await System.IO.File.WriteAllTextAsync(
                    statusFilePath,
                    JsonSerializer.Serialize(statusInfo, new JsonSerializerOptions { WriteIndented = true })
                );
                _logger.LogInformation("已生成上传状态文件: {StatusFilePath}", statusFilePath);

                _logger.LogInformation("成功保存 {SavedCount}/{TotalCount} 个文件",
                    savedFiles.Count, files.Count);

                // 更新会话最后活动时间
                session.LastActivity = DateTime.Now;
                _activeSessions[sessionId] = session;

                // 如果是最后一个批次，检查PLY文件
                if (batchNumber == totalBatches)
                {
                    _logger.LogInformation("处理最后一个批次，检查PLY文件");
                    var hasPly = await _plyFileService.CheckAndProcessPlyFilesAsync(taskId, projectName, unifiedImagesDir);

                    return Ok(new Dictionary<string, object> {
                        { "code", 200 },
                        { "message", "所有批次上传完成" },
                        { "task_id", taskId },
                        { "session_id", sessionId },
                        { "saved_files", savedFiles.Count },
                        { "server_confirmed_count", savedFiles.Count }, // 明确的服务器确认数量
                        { "ply_files_found", hasPly },
                        { "success_rate", $"{savedFiles.Count}/{files.Count}" },
                        { "status", savedFiles.Count == files.Count ? "完全成功" : "部分成功" },
                        { "batch_time", DateTime.Now.ToString("O") }
                    });
                }
                else
                {
                    // 返回当前批次处理结果
                    return Ok(new Dictionary<string, object> {
                        { "code", 200 },
                        { "message", $"批次 {batchNumber}/{totalBatches} 上传成功" },
                        { "task_id", taskId },
                        { "session_id", sessionId },
                        { "saved_files", savedFiles.Count },
                        { "server_confirmed_count", savedFiles.Count }, // 明确的服务器确认数量
                        { "success_rate", $"{savedFiles.Count}/{files.Count}" },
                        { "status", savedFiles.Count == files.Count ? "完全成功" : "部分成功" }
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "上传处理错误");
                return StatusCode(500, new Dictionary<string, object> {
                    { "code", 500 },
                    { "message", $"处理错误: {ex.Message}" },
                    { "error_type", ex.GetType().Name },
                    { "saved_files", savedFiles.Count }, // 即使有错误，也返回成功保存的文件数
                    { "server_confirmed_count", savedFiles.Count }
                });
            }
        }

        [HttpGet("/upload/session/{sessionId}")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public IActionResult GetSessionStatus(string sessionId)
        {
            if (_activeSessions.TryGetValue(sessionId, out var session))
            {
                int successCount = session.Files.Count(f => f.Value.IsSuccess);
                int totalCount = session.Files.Count;

                return Ok(new Dictionary<string, object> {
                    { "session_id", sessionId },
                    { "files_count", totalCount },
                    { "success_count", successCount },
                    { "server_confirmed_count", successCount }, // 服务器确认数量
                    { "success_rate", totalCount > 0 ? $"{successCount}/{totalCount} ({Math.Round(100.0 * successCount / totalCount, 1)}%)" : "0/0 (0%)" },
                    { "last_activity", session.LastActivity },
                    { "project_name", session.ProjectName },
                    { "status", successCount == totalCount && totalCount > 0 ? "完全成功" : successCount > 0 ? "部分成功" : "未完成" }
                });
            }

            return NotFound(new Dictionary<string, object> {
                { "code", 404 },
                { "message", "会话不存在" }
            });
        }

        [HttpGet("/status")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        public IActionResult GetStatus()
        {
            var status = new Dictionary<string, object> {
                { "status", "running" },
                { "timestamp", DateTime.Now.ToString("O") },
                { "mqtt_connected", _mqttClientService.IsConnected },
                { "worker_threads", Environment.ProcessorCount * 2 },
                { "ply_watch_dir", _plyFileService.GetPlyCheckPath() },
                { "server_ip", string.Join(", ", Dns.GetHostAddresses(Dns.GetHostName())
                    .Where(i => i.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork)
                    .Select(i => i.ToString())) },
                { "upload_folder", Path.GetFullPath(_uploadFolder) },
                { "dotnet_version", Environment.Version.ToString() },
                { "os_version", Environment.OSVersion.ToString() },
                { "active_sessions", _activeSessions.Count }
            };

            _logger.LogInformation("状态请求: {@Status}", status);
            return Ok(status);
        }

        [HttpGet("/test")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        public IActionResult Test()
        {
            return Ok(new Dictionary<string, object> {
                { "message", "API服务运行正常" },
                { "time", DateTime.Now },
                { "server", Environment.MachineName }
            });
        }

        // 辅助方法: 获取客户端IP地址
        private string GetClientIpAddress()
        {
            string ip = HttpContext.Connection.RemoteIpAddress?.ToString();

            if (Request.Headers.ContainsKey("X-Forwarded-For"))
            {
                ip = Request.Headers["X-Forwarded-For"];
            }

            return ip ?? "unknown";
        }

        // 辅助方法: 计算文件哈希
        private string ComputeFileHash(IFormFile file)
        {
            try
            {
                using (var stream = file.OpenReadStream())
                using (var sha256 = SHA256.Create())
                {
                    byte[] hashBytes = sha256.ComputeHash(stream);
                    return BitConverter.ToString(hashBytes).Replace("-", "").ToLowerInvariant();
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "计算文件哈希失败: {FileName}", file.FileName);
                return Guid.NewGuid().ToString(); // 失败时返回随机值
            }
        }

        // 辅助方法: 提取文件唯一ID
        private string ExtractFileUniqueId(IFormCollection form, int fileIndex)
        {
            var uniqueIdKey = $"file_unique_id_{fileIndex}";
            if (form.ContainsKey(uniqueIdKey))
            {
                return form[uniqueIdKey].ToString();
            }

            // 如果客户端没有提供唯一ID，生成一个
            return Guid.NewGuid().ToString();
        }

        // 处理所有图片的综合方法
        private async Task PerformComprehensiveImageProcessing(string unifiedImagesDir, string projectDir, List<string> existingList)
        {
            _logger.LogInformation("开始综合图片处理...");

            // 1. 收集所有图片源（包括project目录和vehicles下的所有目录）
            var allImagePaths = new List<string>();

            // 收集项目根目录中的图片
            allImagePaths.AddRange(Directory.GetFiles(projectDir, "*.jpg", SearchOption.TopDirectoryOnly));
            allImagePaths.AddRange(Directory.GetFiles(projectDir, "*.jpeg", SearchOption.TopDirectoryOnly));

            // 收集vehicles目录下的所有图片
            var vehiclesDir = Path.Combine(projectDir, "vehicles");
            if (Directory.Exists(vehiclesDir))
            {
                // 获取vehicles下所有子目录
                foreach (var vehicleDir in Directory.GetDirectories(vehiclesDir))
                {
                    // 收集vehicle目录中的图片
                    allImagePaths.AddRange(Directory.GetFiles(vehicleDir, "*.jpg", SearchOption.TopDirectoryOnly));
                    allImagePaths.AddRange(Directory.GetFiles(vehicleDir, "*.jpeg", SearchOption.TopDirectoryOnly));

                    // 收集tracks目录中的图片
                    var tracksDir = Path.Combine(vehicleDir, "tracks");
                    if (Directory.Exists(tracksDir))
                    {
                        foreach (var trackDir in Directory.GetDirectories(tracksDir))
                        {
                            allImagePaths.AddRange(Directory.GetFiles(trackDir, "*.jpg", SearchOption.TopDirectoryOnly));
                            allImagePaths.AddRange(Directory.GetFiles(trackDir, "*.jpeg", SearchOption.TopDirectoryOnly));
                        }
                    }
                }
            }

            _logger.LogInformation("共收集到 {Count} 张源图片", allImagePaths.Count);

            // 2. 确保这些图片都已复制到all_images目录
            var currentImagesInUnified = new HashSet<string>(
                Directory.GetFiles(unifiedImagesDir, "*.jpg")
                .Concat(Directory.GetFiles(unifiedImagesDir, "*.jpeg"))
                .Select(path => Path.GetFileName(path))
            );

            // 3. 根据所有图片源创建新的清单
            var newImageList = new List<string>();
            var imageListPath = Path.Combine(unifiedImagesDir, "image_list.txt");

            // 处理已有清单项目
            var existingEntries = new Dictionary<string, string>();
            foreach (var entry in existingList)
            {
                var parts = entry.Split('\t');
                if (parts.Length >= 2)
                {
                    var originalFileName = parts[1];
                    existingEntries[originalFileName] = entry;
                }
            }

            // 4. 对所有源图片路径进行排序和重命名处理
            var processedSourceImages = new Dictionary<string, string>(); // 原文件名 -> 新文件名
            int newNameIndex = 11; // 从11开始编号

            foreach (var imagePath in allImagePaths)
            {
                var fileName = Path.GetFileName(imagePath);
                var prefixedName = GetPrefixedFileName(imagePath, projectDir);

                // 检查是否已经处理过这个文件
                if (processedSourceImages.ContainsKey(prefixedName))
                {
                    continue; // 跳过重复文件
                }

                // 生成新的数字文件名
                var extension = Path.GetExtension(fileName);
                var newName = $"{newNameIndex}{extension}";
                processedSourceImages[prefixedName] = newName;

                // 复制到统一目录
                var destinationPath = Path.Combine(unifiedImagesDir, prefixedName);
                if (!System.IO.File.Exists(destinationPath))
                {
                    try
                    {
                        System.IO.File.Copy(imagePath, destinationPath, false);
                        _logger.LogInformation("复制源图片到统一目录: {Source} -> {Dest}", imagePath, destinationPath);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "复制源图片失败: {Source}", imagePath);
                    }
                }

                newNameIndex++;
            }

            // 5. 生成新的清单和执行重命名
            var finalList = new List<string>();
            int index = 1;

            foreach (var entry in processedSourceImages)
            {
                var originalName = entry.Key;
                var newName = entry.Value;

                finalList.Add($"{index}\t{originalName}\t{newName}");

                // 执行重命名
                string originalFilePath = Path.Combine(unifiedImagesDir, originalName);
                string newFilePath = Path.Combine(unifiedImagesDir, newName);

                if (System.IO.File.Exists(originalFilePath))
                {
                    try
                    {
                        // 如果新文件已存在，先删除它
                        if (System.IO.File.Exists(newFilePath))
                        {
                            System.IO.File.Delete(newFilePath);
                        }

                        // 复制并删除源文件
                        System.IO.File.Copy(originalFilePath, newFilePath);
                        System.IO.File.Delete(originalFilePath);

                        _logger.LogInformation("重命名文件: {Original} -> {New}", originalName, newName);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "重命名文件失败: {Original} -> {New}", originalName, newName);
                    }
                }

                index++;
            }

            // 6. 保存清单文件
            await System.IO.File.WriteAllLinesAsync(imageListPath, finalList);
            _logger.LogInformation("已更新图片清单文件，共包含 {Count} 个文件", finalList.Count);

            // 7. 最终清理 - 删除所有非数字命名的文件
            PerformThoroughCleanup(unifiedImagesDir);
        }

        // 获取带前缀文件名的辅助方法
        private string GetPrefixedFileName(string imagePath, string projectDir)
        {
            // 根据图片路径确定前缀
            string prefix = "project_"; // 默认为项目前缀
            string fileName = Path.GetFileName(imagePath);

            if (imagePath.Contains(Path.Combine("vehicles")))
            {
                // 解析路径结构，提取车辆和轨迹信息
                var pathParts = imagePath.Split(Path.DirectorySeparatorChar);
                int vehiclesIndex = Array.IndexOf(pathParts, "vehicles");

                if (vehiclesIndex >= 0 && vehiclesIndex + 1 < pathParts.Length)
                {
                    var vehicleName = pathParts[vehiclesIndex + 1];

                    if (imagePath.Contains(Path.Combine("tracks")))
                    {
                        // 这是一个轨迹照片
                        int tracksIndex = Array.IndexOf(pathParts, "tracks");
                        if (tracksIndex >= 0 && tracksIndex + 1 < pathParts.Length)
                        {
                            var trackName = pathParts[tracksIndex + 1];
                            prefix = $"track_{vehicleName}_{trackName}_";
                        }
                    }
                    else
                    {
                        // 这是一个车辆照片
                        prefix = $"vehicle_{vehicleName}_";
                    }
                }
            }

            return $"{prefix}{fileName}";
        }

        // 更彻底的清理方法
        private void PerformThoroughCleanup(string directory)
        {
            try
            {
                _logger.LogInformation("开始彻底清理目录: {Directory}", directory);

                // 获取并处理所有需要保留的文件 - 只有纯数字命名的文件会被保留
                var filesToKeep = new HashSet<string>();
                var filesToDelete = new List<string>();

                foreach (var filePath in Directory.GetFiles(directory, "*.jpg")
                                        .Concat(Directory.GetFiles(directory, "*.jpeg")))
                {
                    var fileName = Path.GetFileName(filePath);

                    // 检查文件名是否是纯数字（如11.jpg）
                    if (int.TryParse(Path.GetFileNameWithoutExtension(fileName), out _))
                    {
                        filesToKeep.Add(fileName);
                        _logger.LogInformation("保留文件: {FileName}", fileName);
                    }
                    else
                    {
                        filesToDelete.Add(filePath);
                        _logger.LogInformation("计划删除文件: {FileName}", fileName);
                    }
                }

                // 删除所有非数字命名的文件
                int deletedCount = 0;
                foreach (var filePath in filesToDelete)
                {
                    try
                    {
                        System.IO.File.Delete(filePath);
                        deletedCount++;
                        _logger.LogInformation("已删除文件: {FileName}", Path.GetFileName(filePath));
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "删除文件失败: {FileName}", Path.GetFileName(filePath));
                    }
                }

                _logger.LogInformation("清理完成。保留 {KeepCount} 个文件，删除 {DeleteCount} 个文件",
                    filesToKeep.Count, deletedCount);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "清理目录时发生错误");
            }
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