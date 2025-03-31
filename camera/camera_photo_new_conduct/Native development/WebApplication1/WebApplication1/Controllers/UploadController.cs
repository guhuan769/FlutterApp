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
using System.Linq;
using System.Text.RegularExpressions;

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
                List<Dictionary<string, object>> vehicles = new List<Dictionary<string, object>>();
                
                if (Request.Form.ContainsKey("project_info"))
                {
                    try
                    {
                        using (JsonDocument doc = JsonDocument.Parse(Request.Form["project_info"]))
                        {
                            JsonElement root = doc.RootElement;
                            foreach (JsonProperty property in root.EnumerateObject())
                            {
                                if (property.Name == "vehicles")
                                {
                                    // 尝试解析vehicles字符串为JSON数组
                                    try
                                    {
                                        string vehiclesJson = property.Value.ToString();
                                        using (JsonDocument vehiclesDoc = JsonDocument.Parse(vehiclesJson))
                                        {
                                            JsonElement vehiclesArray = vehiclesDoc.RootElement;
                                            if (vehiclesArray.ValueKind == JsonValueKind.Array)
                                            {
                                                foreach (JsonElement vehicleElement in vehiclesArray.EnumerateArray())
                                                {
                                                    var vehicleInfo = new Dictionary<string, object>();
                                                    foreach (JsonProperty vehicleProp in vehicleElement.EnumerateObject())
                                                    {
                                                        if (vehicleProp.Name != "tracks")
                                                        {
                                                            vehicleInfo[vehicleProp.Name] = vehicleProp.Value.ToString();
                                                        }
                                                        else
                                                        {
                                                            // 处理tracks数组
                                                            List<Dictionary<string, object>> tracks = new List<Dictionary<string, object>>();
                                                            if (vehicleProp.Value.ValueKind == JsonValueKind.Array)
                                                            {
                                                                foreach (JsonElement trackElement in vehicleProp.Value.EnumerateArray())
                                                                {
                                                                    var trackInfo = new Dictionary<string, object>();
                                                                    foreach (JsonProperty trackProp in trackElement.EnumerateObject())
                                                                    {
                                                                        trackInfo[trackProp.Name] = trackProp.Value.ToString();
                                                                    }
                                                                    tracks.Add(trackInfo);
                                                                }
                                                            }
                                                            vehicleInfo["tracks"] = tracks;
                                                        }
                                                    }
                                                    vehicles.Add(vehicleInfo);
                                                }
                                            }
                    }
                }
                catch (Exception ex)
                {
                                        _logger.LogError(ex, "解析vehicles JSON失败");
                                    }
                    }
                    else
                    {
                                    projectInfo[property.Name] = property.Value.ToString();
                                }
                            }
                        }
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "解析项目信息JSON失败");
                        projectInfo = new Dictionary<string, object>();
                    }
                }

                // 添加解析后的vehicles到projectInfo
                projectInfo["parsed_vehicles"] = vehicles;

                _logger.LogInformation("批次: {BatchNumber}/{TotalBatches}", batchNumber, totalBatches);
                _logger.LogInformation("上传类型: {UploadType}", uploadType);
                _logger.LogInformation("上传值: {UploadValue}", uploadValue);
                _logger.LogInformation("项目信息: {ProjectInfo}", JsonSerializer.Serialize(projectInfo));
                _logger.LogInformation("已解析的车辆数量: {VehicleCount}", vehicles.Count);
                
                foreach (var vehicle in vehicles)
                {
                    _logger.LogInformation("车辆: {VehicleId} - {VehicleName}", 
                        vehicle.ContainsKey("id") ? vehicle["id"] : "无ID", 
                        vehicle.ContainsKey("name") ? vehicle["name"] : "无名称");
                    
                    if (vehicle.ContainsKey("tracks") && vehicle["tracks"] is List<Dictionary<string, object>> tracksList)
                    {
                        foreach (var track in tracksList)
                        {
                            _logger.LogInformation("轨迹: {TrackId} - {TrackName}", 
                                track.ContainsKey("id") ? track["id"] : "无ID",
                                track.ContainsKey("name") ? track["name"] : "无名称");
                        }
                    }
                }

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
                    
                    // 如果是track或vehicle类型，尝试从已解析的vehicles中获取额外信息
                    if ((fileType == "track" || fileType == "vehicle") && vehicles.Count > 0)
                    {
                        if (fileType == "track" && fileInfo.ContainsKey("trackId") && fileInfo.ContainsKey("vehicleId"))
                        {
                            // 记录轨迹信息
                            var vehicleId = fileInfo["vehicleId"];
                            var trackId = fileInfo["trackId"];
                            
                            var vehicle = vehicles.FirstOrDefault(v => v.ContainsKey("id") && v["id"].ToString() == vehicleId);
                            if (vehicle != null && vehicle.ContainsKey("tracks") && vehicle["tracks"] is List<Dictionary<string, object>> tracksList)
                            {
                                var track = tracksList.FirstOrDefault(t => t.ContainsKey("id") && t["id"].ToString() == trackId);
                                if (track != null)
                                {
                                    _logger.LogInformation("找到相关轨迹信息: 车辆[{VehicleName}]的轨迹[{TrackName}]", 
                                        vehicle.ContainsKey("name") ? vehicle["name"] : "未命名", 
                                        track.ContainsKey("name") ? track["name"] : "未命名");
                                    
                                    // 可以添加额外的轨迹信息到fileInfo中
                                    if (track.ContainsKey("name") && !fileInfo.ContainsKey("trackName"))
                                        fileInfo["trackName"] = track["name"].ToString();
                                }
                            }
                        }
                        else if (fileType == "vehicle" && fileInfo.ContainsKey("vehicleId"))
                        {
                            // 记录车辆信息
                            var vehicleId = fileInfo["vehicleId"];
                            var vehicle = vehicles.FirstOrDefault(v => v.ContainsKey("id") && v["id"].ToString() == vehicleId);
                            if (vehicle != null)
                            {
                                _logger.LogInformation("找到相关车辆信息: [{VehicleName}]", 
                                    vehicle.ContainsKey("name") ? vehicle["name"] : "未命名");
                                
                                // 可以添加额外的车辆信息到fileInfo中
                                if (vehicle.ContainsKey("name") && !fileInfo.ContainsKey("vehicleName"))
                                    fileInfo["vehicleName"] = vehicle["name"].ToString();
                            }
                        }
                    }
                    
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

                // 获取现有图片的最大索引号
                int fileIndex = 11; // 默认从11开始命名
                if (batchNumber > 1)
                {
                    // 如果不是第一批次，获取当前所有图片的最大索引
                    try
                    {
                        _logger.LogInformation("开始查找现有最大索引...");
                        var allImageFiles = Directory.GetFiles(unifiedImagesDir, "*.jpg");
                        List<int> indices = new List<int>();
                        
                        foreach (var file in allImageFiles)
                        {
                            string fileName = Path.GetFileNameWithoutExtension(file);
                            // 使用正则表达式提取文件名的数字部分
                            var match = Regex.Match(fileName, @"_(\d+)$|(\d+)$");
                            if (match.Success)
                            {
                                string indexStr = match.Groups[1].Value;
                                if (string.IsNullOrEmpty(indexStr))
                                    indexStr = match.Groups[2].Value;
                                
                                if (int.TryParse(indexStr, out int index))
                                {
                                    indices.Add(index);
                                    _logger.LogDebug("找到索引: {Index} 来自文件: {FileName}", index, fileName);
                                }
                            }
                        }
                        
                        if (indices.Count > 0)
                        {
                            fileIndex = indices.Max() + 1;
                            _logger.LogInformation("找到现有最大索引: {MaxIndex}，新文件从 {FileIndex} 开始", indices.Max(), fileIndex);
                    }
                    else
                    {
                            _logger.LogInformation("未找到有效的索引，使用默认值 {FileIndex}", fileIndex);
                    }
                }
                catch (Exception ex)
                {
                        _logger.LogError(ex, "获取现有图片索引失败，使用默认值 {DefaultIndex}", fileIndex);
                    }
                }
                else
                {
                    _logger.LogInformation("首批次上传，使用初始索引值 {FileIndex}", fileIndex);
                }

                // 更新或创建图片清单
                var imageListPath = Path.Combine(unifiedImagesDir, "image_list.txt");
                List<string> imageListEntries;
                
                if (System.IO.File.Exists(imageListPath) && batchNumber > 1)
                {
                    // 如果不是第一批次且清单文件存在，则读取现有内容
                    try
                    {
                        imageListEntries = System.IO.File.ReadAllLines(imageListPath).ToList();
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "读取现有图片清单失败，创建新清单");
                        imageListEntries = new List<string>
                        {
                            "# 图片清单文件",
                            "# 格式: 序号\t原文件名\t新文件名"
                        };
                    }
                }
                else
                {
                    // 创建新清单
                    imageListEntries = new List<string>
                    {
                        "# 图片清单文件",
                        "# 格式: 序号\t原文件名\t新文件名"
                    };
                }
                
                foreach (var (tempPath, originalName, fileType, fileInfo) in fileInfoList)
        {
            try
            {
                        // 确定文件类型前缀
                        string typePrefix = "";
                        if (fileType == "project")
                        {
                            typePrefix = "P_";
                        }
                        else if (fileType == "vehicle" && fileInfo.ContainsKey("vehicleId"))
                        {
                            // 为车辆图片添加车辆ID
                            typePrefix = $"V_{fileInfo["vehicleId"]}_";
                        }
                        else if (fileType == "track" && fileInfo.ContainsKey("vehicleId") && fileInfo.ContainsKey("trackId"))
                        {
                            // 为轨迹图片添加车辆ID和轨迹ID
                            typePrefix = $"T_{fileInfo["vehicleId"]}_{fileInfo["trackId"]}_";
                        }
                        
                        // all_images目录中的文件命名 - 加上类型前缀
                        string newFileName = $"{typePrefix}{fileIndex}.jpg";
                        string newFilePath = Path.Combine(unifiedImagesDir, newFileName);
                        
                        // 重命名临时文件
                        System.IO.File.Move(tempPath, newFilePath, true);
                        
                        // 添加到清单
                        imageListEntries.Add($"{fileIndex}\t{originalName}\t{newFileName}");
                        
                        // 根据文件类型复制到特定目录 - 使用原始文件名
                        string specificPath;
                        string originalFileName = Path.GetFileName(originalName);
                        
                        if (fileType == "project")
                        {
                            specificPath = Path.Combine(projectDir, originalFileName);
                        }
                        else if (fileType == "vehicle" && fileInfo.ContainsKey("vehicleId"))
                        {
                            var vehicleDir = Path.Combine(projectDir, "vehicles", fileInfo["vehicleId"]);
                            Directory.CreateDirectory(vehicleDir);
                            specificPath = Path.Combine(vehicleDir, originalFileName);
                        }
                        else if (fileType == "track" && fileInfo.ContainsKey("vehicleId") && fileInfo.ContainsKey("trackId"))
                        {
                            var trackDir = Path.Combine(projectDir, "vehicles", fileInfo["vehicleId"], "tracks", fileInfo["trackId"]);
                            Directory.CreateDirectory(trackDir);
                            specificPath = Path.Combine(trackDir, originalFileName);
                        }
                        else
                        {
                            specificPath = Path.Combine(projectDir, originalFileName);
                        }
                        
                        // 复制到特定目录
                        System.IO.File.Copy(newFilePath, specificPath, true);
                        
                        // 记录成功
                        savedFiles.Add(new Dictionary<string, object>
                        {
                            { "fileName", originalName },
                            { "newFileName", newFileName },
                            { "originalCopy", originalFileName },
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
                // 修改为更结构化的格式，按车辆和轨迹分组
                List<string> structuredImageList = new List<string>
                {
                    "# 图片清单文件 - 按类型分组",
                    "# 生成时间: " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"),
                    "",
                    "# 项目图片 (P_)",
                    "# 序号\t原文件名\t新文件名"
                };

                // 按前缀分组整理图片清单
                var projectImages = imageListEntries.Skip(2)
                    .Where(line => line.Contains("\tP_"))
                    .ToList();
                
                if (projectImages.Any())
                {
                    structuredImageList.AddRange(projectImages);
                }
                else
                {
                    structuredImageList.Add("# (暂无项目图片)");
                }

                // 按车辆分组
                var vehicleGroups = vehicles.Select(v => v["id"].ToString()).Distinct().ToList();
                foreach (var vehicleId in vehicleGroups)
                {
                    string vehicleName = "未命名车辆";
                    var vehicleObj = vehicles.FirstOrDefault(v => v["id"].ToString() == vehicleId);
                    if (vehicleObj != null && vehicleObj.ContainsKey("name"))
                    {
                        vehicleName = vehicleObj["name"].ToString();
                    }
                    
                    structuredImageList.Add("");
                    structuredImageList.Add($"# 车辆图片: {vehicleName} (ID: {vehicleId})");
                    structuredImageList.Add("# 序号\t原文件名\t新文件名");
                    
                    // 添加该车辆的图片
                    var vehicleImages = imageListEntries.Skip(2)
                        .Where(line => line.Contains($"\tV_{vehicleId}_"))
                        .ToList();
                    
                    if (vehicleImages.Any())
                    {
                        structuredImageList.AddRange(vehicleImages);
                    }
                    else
                    {
                        structuredImageList.Add("# (暂无此车辆图片)");
                    }
                    
                    // 按轨迹分组
                    var vehicle = vehicles.FirstOrDefault(v => v["id"].ToString() == vehicleId);
                    if (vehicle != null && vehicle.ContainsKey("tracks") && vehicle["tracks"] is List<Dictionary<string, object>> tracks)
                    {
                        foreach (var track in tracks)
                        {
                            if (track.ContainsKey("id"))
                            {
                                var trackId = track["id"].ToString();
                                string trackName = "未命名轨迹";
                                if (track.ContainsKey("name"))
                                {
                                    trackName = track["name"].ToString();
                                }
                                
                                structuredImageList.Add("");
                                structuredImageList.Add($"# 轨迹图片: {trackName} (车辆: {vehicleName}, 轨迹ID: {trackId})");
                                structuredImageList.Add("# 序号\t原文件名\t新文件名");
                                
                                // 添加该轨迹的图片
                                var trackImages = imageListEntries.Skip(2)
                                    .Where(line => line.Contains($"\tT_{vehicleId}_{trackId}_"))
                                    .ToList();
                                
                                if (trackImages.Any())
                                {
                                    structuredImageList.AddRange(trackImages);
                                }
                                else
                                {
                                    structuredImageList.Add("# (暂无此轨迹图片)");
                                }
                            }
                        }
                    }
                }

                // 其他未分类图片
                var otherImages = imageListEntries.Skip(2)
                    .Where(line => !line.Contains("\tP_") && 
                                  !vehicleGroups.Any(v => line.Contains($"\tV_{v}_")) && 
                                  !vehicleGroups.Any(v => 
                                  {
                                      var vehicle = vehicles.FirstOrDefault(vehicle => vehicle["id"].ToString() == v);
                                      if (vehicle != null && vehicle.ContainsKey("tracks") && vehicle["tracks"] is List<Dictionary<string, object>> tracksList)
                                      {
                                          return tracksList.Any(t => t.ContainsKey("id") && 
                                                                line.Contains($"\tT_{v}_{t["id"]}_"));
                                      }
                                      return false;
                                  }))
                    .ToList();
                
                if (otherImages.Any())
                {
                    structuredImageList.Add("");
                    structuredImageList.Add("# 其他未分类图片");
                    structuredImageList.Add("# 序号\t原文件名\t新文件名");
                    structuredImageList.AddRange(otherImages);
                }

                // 同时保存原始顺序的清单和结构化清单
                await System.IO.File.WriteAllLinesAsync(imageListPath, imageListEntries);
                _logger.LogInformation("已生成图片清单，包含 {Count} 条记录", imageListEntries.Count - 2);
                
                // 保存结构化清单
                var structuredImageListPath = Path.Combine(unifiedImagesDir, "image_list_structured.txt");
                await System.IO.File.WriteAllLinesAsync(structuredImageListPath, structuredImageList);
                _logger.LogInformation("已生成结构化图片清单，包含 {Count} 个分组", vehicleGroups.Count + 1);

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