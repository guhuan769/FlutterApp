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

                // 添加：如果是第一个批次，并且项目目录已存在，则删除已存在的项目
                if (batchNumber == 1 && Directory.Exists(projectDir))
                {
                    try
                    {
                        _logger.LogInformation("发现同名项目目录已存在，正在删除: {ProjectDir}", projectDir);
                        Directory.Delete(projectDir, true); // 递归删除目录及其内容
                        _logger.LogInformation("已成功删除同名项目目录");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "删除同名项目目录失败: {ProjectDir}", projectDir);
                        // 如果删除失败，可以考虑返回错误，或继续处理（覆盖现有文件）
                        // 这里选择继续处理，因为后续文件处理会覆盖相同文件
                    }
                }

                Directory.CreateDirectory(baseSavePath);
                Directory.CreateDirectory(projectDir);
                
                // 添加：创建统一存放图片的目录
                var unifiedImagesDir = Path.Combine(projectDir, "all_images");
                Directory.CreateDirectory(unifiedImagesDir);
                
                // 创建/更新图片清单文件
                var imageListPath = Path.Combine(unifiedImagesDir, "image_list.txt");
                var imageList = new List<string>();

                // 添加：首先读取已有的清单文件（如果存在）
                if (System.IO.File.Exists(imageListPath))
                {
                    try 
                    {
                        var existingLines = await System.IO.File.ReadAllLinesAsync(imageListPath);
                        // 解析已有编号和文件名
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
                        string prefix = ""; // 添加：为统一目录中的文件添加前缀
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
                        
                        // 添加：保存文件到统一目录，添加前缀
                        var originalFileName = Path.GetFileName(fileInfo.GetValueOrDefault("relativePath", file.FileName));
                        var unifiedFileName = $"{prefix}{originalFileName}";
                        var unifiedSavePath = Path.GetFullPath(Path.Combine(unifiedImagesDir, unifiedFileName));
                        
                        using (var stream = new FileStream(unifiedSavePath, FileMode.Create))
                        {
                            await file.CopyToAsync(stream);
                            _logger.LogInformation("文件 {FileName} 已保存到统一目录 {SavePath}", file.FileName, unifiedSavePath);
                        }
                        
                        // 添加：检查文件是否已在清单中
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

                        savedFiles.Add(savePath);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "处理文件失败 {FileName}", files[i].FileName);
                    }
                }
                
                // 修改：确保清单排序正确
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
                
                // 添加：写入上传状态文件，但保持API返回简单
                var statusInfo = new
                {
                    batch_number = batchNumber,
                    total_batches = totalBatches,
                    saved_files = savedFiles.Count,
                    total_files = files.Count,
                    success_rate = $"{savedFiles.Count}/{files.Count} ({(files.Count > 0 ? Math.Round(100.0 * savedFiles.Count / files.Count, 1) : 0)}%)",
                    upload_status = savedFiles.Count == files.Count ? "上传完成" : "上传部分完成",
                    timestamp = DateTime.Now.ToString("O")
                };
                
                var statusFilePath = Path.Combine(projectDir, $"upload_status_{batchNumber}.json");
                await System.IO.File.WriteAllTextAsync(
                    statusFilePath, 
                    JsonSerializer.Serialize(statusInfo, new JsonSerializerOptions { WriteIndented = true })
                );
                _logger.LogInformation("已生成上传状态文件: {StatusFilePath}", statusFilePath);

                _logger.LogInformation("成功保存 {SavedCount}/{TotalCount} 个文件",
                    savedFiles.Count, files.Count);

                // 如果是最后一个批次，检查PLY文件
                if (batchNumber == totalBatches)
                {
                    _logger.LogInformation("处理最后一个批次，检查PLY文件");
                    var hasPly = await _plyFileService.CheckAndProcessPlyFilesAsync(taskId, projectName, unifiedImagesDir);
                    if (!hasPly)
                    {
                        return StatusCode(500, new { code = 500, message = $"ply文件生成失败。" });
                    }
                    //if (hasPly) 
                    //{
                    // 保持原始的简单返回格式，但在文件系统中保存详细信息
                    return Ok(new
                        {
                            code = 200,
                            message = "所有批次上传完成",
                            task_id = taskId,
                            saved_files = savedFiles.Count,
                            ply_files_found = hasPly,
                            success_rate = $"{savedFiles.Count}/{files.Count}"  // 添加这一项关键数据
                        });
                    //}
                    //else
                    //{
                    //     return StatusCode(500, new { code = 500, message = $"ply文件生成失败。" });
                    //}
                }
                else
                {
                    // 保持原始的简单返回格式，但在文件系统中保存详细信息
                    return Ok(new
                    {
                        code = 200,
                        message = $"批次 {batchNumber}/{totalBatches} 上传成功",
                        task_id = taskId,
                        saved_files = savedFiles.Count,
                        success_rate = $"{savedFiles.Count}/{files.Count}"  // 添加这一项关键数据
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

        // 添加：获取上传状态接口
        [HttpGet("/upload/status/{projectName}/{batchNumber}")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public IActionResult GetUploadStatus(string projectName, int batchNumber)
        {
            try
            {
                // 查找项目目录
                var projectDirs = Directory.GetDirectories(_uploadFolder, projectName, SearchOption.AllDirectories);
                if (projectDirs.Length == 0)
                {
                    return NotFound(new { code = 404, message = $"未找到项目: {projectName}" });
                }
                
                // 使用找到的第一个项目目录
                var projectDir = projectDirs[0];
                var statusFilePath = Path.Combine(projectDir, $"upload_status_{batchNumber}.json");
                
                if (!System.IO.File.Exists(statusFilePath))
                {
                    return NotFound(new { code = 404, message = $"未找到批次 {batchNumber} 的上传状态" });
                }
                
                var statusJson = System.IO.File.ReadAllText(statusFilePath);
                return Content(statusJson, "application/json");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "获取上传状态失败");
                return StatusCode(500, new { code = 500, message = $"获取上传状态失败: {ex.Message}" });
            }
        }

        private object GetFileStructureInfo(string projectDir)
        {
            try
            {
                var structure = new List<object>();
                
                // 获取vehicles目录
                var vehiclesDir = Path.Combine(projectDir, "vehicles");
                if (Directory.Exists(vehiclesDir))
                {
                    // 获取所有车辆目录
                    foreach (var vehicleDir in Directory.GetDirectories(vehiclesDir))
                    {
                        var vehicleName = Path.GetFileName(vehicleDir);
                        var vehiclePhotoCount = Directory.GetFiles(vehicleDir, "*.jpg", SearchOption.TopDirectoryOnly).Length 
                                             + Directory.GetFiles(vehicleDir, "*.jpeg", SearchOption.TopDirectoryOnly).Length;
                        
                        // 获取轨迹信息
                        var tracksDir = Path.Combine(vehicleDir, "tracks");
                        var tracksList = new List<object>();
                        
                        if (Directory.Exists(tracksDir))
                        {
                            foreach (var trackDir in Directory.GetDirectories(tracksDir))
                            {
                                var trackName = Path.GetFileName(trackDir);
                                var trackPhotoCount = Directory.GetFiles(trackDir, "*.jpg", SearchOption.TopDirectoryOnly).Length
                                                   + Directory.GetFiles(trackDir, "*.jpeg", SearchOption.TopDirectoryOnly).Length;
                                
                                tracksList.Add(new {
                                    name = trackName,
                                    photo_count = trackPhotoCount
                                });
                            }
                        }
                        
                        structure.Add(new {
                            name = vehicleName,
                            photo_count = vehiclePhotoCount,
                            tracks = tracksList
                        });
                    }
                }
                
                // 获取项目根目录照片
                var projectPhotoCount = Directory.GetFiles(projectDir, "*.jpg", SearchOption.TopDirectoryOnly).Length
                                     + Directory.GetFiles(projectDir, "*.jpeg", SearchOption.TopDirectoryOnly).Length;
                
                return new {
                    vehicles = structure,
                    project_photos = projectPhotoCount
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "获取文件结构信息失败");
                return new { error = "获取文件结构信息失败" };
            }
        }

        // 添加一个新的综合性图片处理方法，确保捕获所有图片
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

        // 添加获取带前缀文件名的辅助方法
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

        // 修改为更彻底的清理方法
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
}