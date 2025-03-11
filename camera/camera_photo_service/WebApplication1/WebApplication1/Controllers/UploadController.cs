using Microsoft.AspNetCore.Mvc;
using PlyFileProcessor.Services;
using System.Net;
using System.Text.Json;

namespace PlyFileProcessor.Controllers
{
    // 移除原来的[Route("[controller]")]，直接使用顶级路由
    [ApiController]
    [Produces("application/json")]
    public class UploadController : ControllerBase
    {
        private readonly ILogger<UploadController> _logger;
        private readonly IPlyFileService _plyFileService;
        private readonly IMqttClientService _mqttClientService;
        private readonly string _uploadFolder = "uploaded_images";
        private readonly HashSet<string> _allowedExtensions = new HashSet<string> { ".jpg", ".jpeg" };

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

        /// <summary>
        /// 处理文件上传请求
        /// </summary>
        /// <remarks>
        /// 上传图片文件并处理PLY文件。
        /// 
        /// 示例请求:
        /// 
        ///     POST /upload
        ///     Content-Type: multipart/form-data
        ///     
        ///     batch_number: 1
        ///     total_batches: 1
        ///     type: model
        ///     value: some_value
        ///     project_info: {"name":"project_name"}
        ///     files[]: [binary_data]
        ///     
        /// </remarks>
        /// <returns>上传结果信息</returns>
        /// <response code="200">上传成功</response>
        /// <response code="400">请求无效</response>
        /// <response code="500">服务器错误</response>
        [HttpPost("/upload")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        [RequestSizeLimit(100 * 1024 * 1024)] // 100MB
        [RequestFormLimits(MultipartBodyLengthLimit = 100 * 1024 * 1024)] // 100MB
        public async Task<IActionResult> UploadImage()
        {
            try
            {
                var taskId = Guid.NewGuid().ToString();
                _logger.LogInformation("收到上传请求 - TaskID: {TaskId}", taskId);

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

                var uploadType = Request.Form["type"].ToString() ?? "";
                var uploadValue = Request.Form["value"].ToString() ?? "";

                Dictionary<string, string> projectInfo = new Dictionary<string, string>();
                if (Request.Form.ContainsKey("project_info"))
                {
                    try
                    {
                        projectInfo = JsonSerializer.Deserialize<Dictionary<string, string>>(Request.Form["project_info"])
                            ?? new Dictionary<string, string>();
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "解析项目信息JSON失败");
                        projectInfo = new Dictionary<string, string>();
                    }
                }

                _logger.LogInformation("批次: {BatchNumber}/{TotalBatches}", batchNumber, totalBatches);
                _logger.LogInformation("上传类型: {UploadType}", uploadType);
                _logger.LogInformation("上传值: {UploadValue}", uploadValue);
                _logger.LogInformation("项目信息: {ProjectInfo}", JsonSerializer.Serialize(projectInfo));

                // 创建保存目录结构
                var categoryFolder = uploadType == "model" ? "模型" : "工艺";
                var baseSavePath = Path.Combine(_uploadFolder, categoryFolder, uploadValue);
                var projectName = projectInfo.GetValueOrDefault("name", "unknown_project");
                var projectDir = Path.Combine(baseSavePath, projectName);

                Directory.CreateDirectory(baseSavePath);
                Directory.CreateDirectory(projectDir);

                // 处理上传的文件
                var savedFiles = new List<string>();
                var files = Request.Form.Files;

                if (files.Count == 0)
                {
                    _logger.LogWarning("没有接收到文件");
                    return BadRequest(new { code = 400, message = "没有接收到文件" });
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
                            continue;
                        }

                        // 获取文件扩展名并验证
                        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
                        if (!_allowedExtensions.Contains(extension))
                        {
                            _logger.LogWarning("文件 {FileName} 的扩展名 {Extension} 不允许", file.FileName, extension);
                            continue;
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

                        // 修改这里：根据不同类型确定保存路径
                        string savePath;
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
                                _logger.LogInformation("文件 {FileName} 将保存为track: {VehicleName}/{TrackName}",
                                    file.FileName, trackVehicleName, trackName);
                                break;

                            default: // "project" 或其他类型
                                     // 项目照片保存在项目根目录
                                savePath = Path.Combine(projectDir,
                                    Path.GetFileName(fileInfo.GetValueOrDefault("relativePath", file.FileName)));
                                _logger.LogInformation("文件 {FileName} 将保存到项目根目录", file.FileName);
                                break;
                        }

                        // 创建必要的目录
                        Directory.CreateDirectory(Path.GetDirectoryName(savePath));

                        // 保存文件
                        using (var stream = new FileStream(savePath, FileMode.Create))
                        {
                            await file.CopyToAsync(stream);
                            _logger.LogInformation("文件 {FileName} 已保存到 {SavePath}", file.FileName, savePath);
                        }

                        savedFiles.Add(savePath);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "处理文件失败 {FileName}", files[i].FileName);
                    }
                }

                _logger.LogInformation("成功保存 {SavedCount}/{TotalCount} 个文件",
                    savedFiles.Count, files.Count);

                // 如果是最后一个批次，检查PLY文件
                if (batchNumber == totalBatches)
                {
                    _logger.LogInformation("处理最后一个批次，检查PLY文件");
                    var hasPly = await _plyFileService.CheckAndProcessPlyFilesAsync(taskId, projectName);

                    if (hasPly) 
                    {
                        return Ok(new
                        {
                            code = 200,
                            message = "所有批次上传完成",
                            task_id = taskId,
                            saved_files = savedFiles.Count,
                            ply_files_found = hasPly
                        });
                    }
                    else
                    {
                         return StatusCode(500, new { code = 500, message = $"ply文件生成失败。" });
                    }
                }
                else
                {
                    return Ok(new
                    {
                        code = 200,
                        message = $"批次 {batchNumber}/{totalBatches} 上传成功",
                        task_id = taskId,
                        saved_files = savedFiles.Count
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "上传处理错误");
                return StatusCode(500, new { code = 500, message = $"处理错误: {ex.Message}" });
            }
        }

        /// <summary>
        /// 获取服务器状态
        /// </summary>
        /// <remarks>
        /// 获取服务器当前运行状态，包括MQTT连接状态、系统信息等。
        /// 
        /// 示例请求:
        /// 
        ///     GET /status
        ///     
        /// </remarks>
        /// <returns>服务器状态信息</returns>
        /// <response code="200">成功获取状态</response>
        [HttpGet("/status")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        public IActionResult GetStatus()
        {
            var status = new
            {
                status = "running",
                timestamp = DateTime.Now.ToString("O"),
                mqtt_connected = _mqttClientService.IsConnected,
                worker_threads = Environment.ProcessorCount * 2,
                ply_watch_dir = _plyFileService.GetPlyCheckPath(),
                // 添加更多状态信息
                server_ip = string.Join(", ", Dns.GetHostAddresses(Dns.GetHostName())
                    .Where(i => i.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork)
                    .Select(i => i.ToString())),
                upload_folder = Path.GetFullPath(_uploadFolder),
                dotnet_version = Environment.Version.ToString(),
                os_version = Environment.OSVersion.ToString()
            };

            _logger.LogInformation("状态请求: {@Status}", status);
            return Ok(status);
        }

        /// <summary>
        /// 测试API服务是否正常运行
        /// </summary>
        /// <remarks>
        /// 简单的测试端点，用于确认API服务是否正常运行。
        /// 
        /// 示例请求:
        /// 
        ///     GET /test
        ///     
        /// </remarks>
        /// <returns>测试结果信息</returns>
        /// <response code="200">服务运行正常</response>
        [HttpGet("/test")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        public IActionResult Test()
        {
            return Ok(new
            {
                message = "API服务运行正常",
                time = DateTime.Now,
                server = Environment.MachineName
            });
        }
    }
}