using Microsoft.AspNetCore.Mvc;
using System;
using System.IO;
using System.Threading.Tasks;
using System.Linq;
using Microsoft.Extensions.Logging;
using System.Collections.Concurrent;
using System.Collections.Generic;

namespace BackendInterface.Controllers
{
    /// <summary>
    /// 照片上传和管理控制器
    /// </summary>
    [ApiController]
    [Route("[controller]")]
    public class PhotoController : ControllerBase
    {
        private readonly ILogger<PhotoController> _logger;
        private readonly string _uploadFolder;
        // 用于存储上传状态的并发字典
        private static readonly ConcurrentDictionary<string, UploadStatus> _uploadStatuses = new ConcurrentDictionary<string, UploadStatus>();

        /// <summary>
        /// 构造函数
        /// </summary>
        /// <param name="logger">日志记录器</param>
        /// <param name="environment">Web环境</param>
        public PhotoController(ILogger<PhotoController> logger, IWebHostEnvironment environment)
        {
            _logger = logger;
            // 图片保存在应用程序目录下的Uploads文件夹中
            _uploadFolder = Path.Combine(environment.ContentRootPath, "Uploads");
            
            // 确保上传文件夹存在
            if (!Directory.Exists(_uploadFolder))
            {
                Directory.CreateDirectory(_uploadFolder);
            }
        }

        /// <summary>
        /// 获取照片上传服务状态
        /// </summary>
        /// <returns>服务状态</returns>
        [HttpGet]
        public IActionResult Get()
        {
            return Ok(new { message = "照片上传服务运行正常" });
        }

        /// <summary>
        /// 测试服务是否正常运行
        /// </summary>
        [HttpGet("test")]
        public IActionResult TestConnection()
        {
            try
            {
                return Ok(new { 
                    status = "success",
                    message = "服务正常运行",
                    timestamp = DateTime.Now
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "测试连接失败");
                return StatusCode(500, new { 
                    status = "error",
                    message = "服务异常",
                    error = ex.Message
                });
            }
        }

        /// <summary>
        /// 上传照片API
        /// </summary>
        /// <remarks>
        /// 通过表单上传照片文件并保存到服务器
        /// </remarks>
        /// <param name="moduleId">模块ID</param>
        /// <param name="moduleType">模块类型</param>
        /// <param name="photoType">照片类型</param>
        /// <param name="projectName">项目名称</param>
        /// <param name="uploadPhotoType">上传照片类型(MODEL/PROCESS)</param>
        /// <param name="uploadTypeId">上传类型ID</param>
        /// <param name="latitude">纬度</param>
        /// <param name="longitude">经度</param>
        /// <returns>上传结果</returns>
        [HttpPost("upload")]
        [Consumes("multipart/form-data")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<IActionResult> Upload(
            string moduleId, 
            string moduleType, 
            string photoType, 
            string projectName = "",
            string uploadPhotoType = "",
            string uploadTypeId = "",
            double? latitude = null,
            double? longitude = null)
        {
            try
            {
                var file = Request.Form.Files.FirstOrDefault();
                
                if (file == null || file.Length == 0)
                {
                    return BadRequest("未提供有效的文件");
                }

                // 确定基本目录结构
                string baseFolder = Path.Combine(_uploadFolder, moduleType);
                string subfolder;
                
                // 根据moduleType决定存储结构
                if (moduleType.Equals("PROJECT", StringComparison.OrdinalIgnoreCase))
                {
                    // 项目级照片直接存储在项目文件夹下
                    subfolder = !string.IsNullOrEmpty(projectName) 
                        ? Path.Combine(baseFolder, $"{moduleId}_{projectName}")
                        : Path.Combine(baseFolder, moduleId);
                    
                    // 如果指定了上传类型和ID，则添加到子文件夹结构中
                    if (!string.IsNullOrEmpty(uploadPhotoType))
                    {
                        subfolder = Path.Combine(subfolder, uploadPhotoType);
                        if (!string.IsNullOrEmpty(uploadTypeId))
                        {
                            subfolder = Path.Combine(subfolder, uploadTypeId);
                        }
                    }
                }
                else if (moduleType.Equals("VEHICLE", StringComparison.OrdinalIgnoreCase))
                {
                    // 车辆级照片存储在车辆文件夹下，并包含车辆ID信息
                    string vehicleFolderName = $"Vehicle_{moduleId}";
                    subfolder = !string.IsNullOrEmpty(projectName)
                        ? Path.Combine(baseFolder, projectName, vehicleFolderName)
                        : Path.Combine(baseFolder, vehicleFolderName);
                    
                    // 如果指定了上传类型和ID，则添加到子文件夹结构中
                    if (!string.IsNullOrEmpty(uploadPhotoType))
                    {
                        subfolder = Path.Combine(subfolder, uploadPhotoType);
                        if (!string.IsNullOrEmpty(uploadTypeId))
                        {
                            subfolder = Path.Combine(subfolder, uploadTypeId);
                        }
                    }
                }
                else if (moduleType.Equals("TRACK", StringComparison.OrdinalIgnoreCase))
                {
                    // 从moduleId中解析出必要信息 (这里假设moduleId格式为 "trackId_vehicleId")
                    string[] idParts = moduleId.Split('_');
                    string trackId = idParts[0];
                    string vehicleId = idParts.Length > 1 ? idParts[1] : "unknown";
                    
                    // 轨迹级照片存储在车辆下的轨迹文件夹中
                    string vehicleFolderName = $"Vehicle_{vehicleId}";
                    string trackFolderName = $"Track_{trackId}";
                    
                    subfolder = !string.IsNullOrEmpty(projectName)
                        ? Path.Combine(baseFolder, projectName, vehicleFolderName, trackFolderName)
                        : Path.Combine(baseFolder, vehicleFolderName, trackFolderName);
                    
                    // 如果指定了上传类型和ID，则添加到子文件夹结构中
                    if (!string.IsNullOrEmpty(uploadPhotoType))
                    {
                        subfolder = Path.Combine(subfolder, uploadPhotoType);
                        if (!string.IsNullOrEmpty(uploadTypeId))
                        {
                            subfolder = Path.Combine(subfolder, uploadTypeId);
                        }
                    }
                }
                else
                {
                    // 其他类型，使用默认结构
                    subfolder = Path.Combine(baseFolder, moduleId);
                }
                
                // 确保目录存在
                if (!Directory.Exists(subfolder))
                {
                    Directory.CreateDirectory(subfolder);
                }

                // 保留原始文件名，不再生成GUID
                // string fileName = $"{Guid.NewGuid()}_{file.FileName}";
                string fileName = file.FileName;
                string filePath = Path.Combine(subfolder, fileName);

                // 保存文件
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                _logger.LogInformation($"已成功上传照片：{filePath}，项目名称：{projectName}，类型：{uploadPhotoType}, 类型ID：{uploadTypeId}");

                // 返回成功信息
                return Ok(new 
                { 
                    fileName,
                    filePath,
                    moduleId,
                    moduleType,
                    photoType,
                    projectName,
                    uploadPhotoType,
                    uploadTypeId,
                    latitude,
                    longitude,
                    uploadTime = DateTime.Now
                });
            }
            catch (Exception ex)
            {
                _logger.LogError($"上传照片失败：{ex.Message}");
                return StatusCode(500, $"上传照片失败：{ex.Message}");
            }
        }

        /// <summary>
        /// 批量上传照片API
        /// </summary>
        /// <remarks>
        /// 允许一次性上传多张照片，返回批次ID用于查询状态
        /// </remarks>
        /// <param name="moduleId">模块ID</param>
        /// <param name="moduleType">模块类型</param>
        /// <param name="projectName">项目名称</param>
        /// <param name="uploadPhotoType">上传照片类型(MODEL/PROCESS)</param>
        /// <param name="uploadTypeId">上传类型ID</param>
        /// <returns>批量上传结果</returns>
        [HttpPost("batch-upload")]
        [Consumes("multipart/form-data")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> BatchUpload(
            string moduleId, 
            string moduleType, 
            string projectName = "",
            string uploadPhotoType = "",
            string uploadTypeId = "")
        {
            try
            {
                var files = Request.Form.Files;
                if (files == null || !files.Any())
                {
                    return BadRequest("未提供有效的文件");
                }

                // 创建批次ID
                string batchId = Guid.NewGuid().ToString();
                int totalFiles = files.Count;
                
                // 注册上传状态
                var status = new UploadStatus
                {
                    BatchId = batchId,
                    ModuleId = moduleId,
                    ModuleType = moduleType,
                    TotalCount = totalFiles,
                    UploadedCount = 0,
                    Progress = 0,
                    IsUploading = true,
                    StartTime = DateTime.Now,
                    UploadPhotoType = uploadPhotoType,
                    UploadTypeId = uploadTypeId
                };
                
                _uploadStatuses[batchId] = status;
                
                // 启动异步上传任务
                _ = Task.Run(async () => 
                {
                    try 
                    {
                        await ProcessBatchUploadAsync(batchId, moduleId, moduleType, projectName, files, uploadPhotoType, uploadTypeId);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError($"批量上传处理失败: {ex.Message}");
                        MarkUploadAsFailed(batchId, ex.Message);
                    }
                });

                // 立即返回批次ID
                return Ok(new 
                { 
                    batchId,
                    totalCount = totalFiles,
                    uploadPhotoType,
                    uploadTypeId,
                    status = "processing"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError($"批量上传请求失败: {ex.Message}");
                return StatusCode(500, $"批量上传失败: {ex.Message}");
            }
        }
        
        /// <summary>
        /// 获取上传状态
        /// </summary>
        /// <param name="batchId">批次ID</param>
        /// <returns>上传状态</returns>
        [HttpGet("upload-status/{batchId}")]
        public IActionResult GetUploadStatus(string batchId)
        {
            if (_uploadStatuses.TryGetValue(batchId, out var status))
            {
                return Ok(status);
            }
            
            return NotFound($"未找到批次ID为 {batchId} 的上传状态");
        }
        
        /// <summary>
        /// 处理批量上传的实际逻辑
        /// </summary>
        private async Task ProcessBatchUploadAsync(
            string batchId, 
            string moduleId, 
            string moduleType, 
            string projectName, 
            IFormFileCollection files,
            string uploadPhotoType = "",
            string uploadTypeId = "")
        {
            // 确定基本目录结构
            string baseFolder = Path.Combine(_uploadFolder, moduleType);
            string subfolder;
            
            // 根据moduleType决定存储结构
            if (moduleType.Equals("PROJECT", StringComparison.OrdinalIgnoreCase))
            {
                // 项目级照片直接存储在项目文件夹下
                subfolder = !string.IsNullOrEmpty(projectName) 
                    ? Path.Combine(baseFolder, $"{moduleId}_{projectName}")
                    : Path.Combine(baseFolder, moduleId);
                
                // 如果指定了上传类型和ID，则添加到子文件夹结构中
                if (!string.IsNullOrEmpty(uploadPhotoType))
                {
                    subfolder = Path.Combine(subfolder, uploadPhotoType);
                    if (!string.IsNullOrEmpty(uploadTypeId))
                    {
                        subfolder = Path.Combine(subfolder, uploadTypeId);
                    }
                }
            }
            else if (moduleType.Equals("VEHICLE", StringComparison.OrdinalIgnoreCase))
            {
                // 车辆级照片存储在车辆文件夹下，并包含车辆ID信息
                string vehicleFolderName = $"Vehicle_{moduleId}";
                subfolder = !string.IsNullOrEmpty(projectName)
                    ? Path.Combine(baseFolder, projectName, vehicleFolderName)
                    : Path.Combine(baseFolder, vehicleFolderName);
                
                // 如果指定了上传类型和ID，则添加到子文件夹结构中
                if (!string.IsNullOrEmpty(uploadPhotoType))
                {
                    subfolder = Path.Combine(subfolder, uploadPhotoType);
                    if (!string.IsNullOrEmpty(uploadTypeId))
                    {
                        subfolder = Path.Combine(subfolder, uploadTypeId);
                    }
                }
            }
            else if (moduleType.Equals("TRACK", StringComparison.OrdinalIgnoreCase))
            {
                // 从moduleId中解析出必要信息 (这里假设moduleId格式为 "trackId_vehicleId")
                string[] idParts = moduleId.Split('_');
                string trackId = idParts[0];
                string vehicleId = idParts.Length > 1 ? idParts[1] : "unknown";
                
                // 轨迹级照片存储在车辆下的轨迹文件夹中
                string vehicleFolderName = $"Vehicle_{vehicleId}";
                string trackFolderName = $"Track_{trackId}";
                
                subfolder = !string.IsNullOrEmpty(projectName)
                    ? Path.Combine(baseFolder, projectName, vehicleFolderName, trackFolderName)
                    : Path.Combine(baseFolder, vehicleFolderName, trackFolderName);
                
                // 如果指定了上传类型和ID，则添加到子文件夹结构中
                if (!string.IsNullOrEmpty(uploadPhotoType))
                {
                    subfolder = Path.Combine(subfolder, uploadPhotoType);
                    if (!string.IsNullOrEmpty(uploadTypeId))
                    {
                        subfolder = Path.Combine(subfolder, uploadTypeId);
                    }
                }
            }
            else
            {
                // 其他类型，使用默认结构
                subfolder = Path.Combine(baseFolder, moduleId);
            }
            
            // 确保目录存在
            if (!Directory.Exists(subfolder))
            {
                Directory.CreateDirectory(subfolder);
            }

            // 现有的处理逻辑保持不变
            int processedCount = 0;
            int successCount = 0;
            List<string> errors = new List<string>();

            foreach (var file in files)
            {
                try
                {
                    string fileName = $"{Guid.NewGuid()}_{file.FileName}";
                    string filePath = Path.Combine(subfolder, fileName);

                    using (var stream = new FileStream(filePath, FileMode.Create))
                    {
                        await file.CopyToAsync(stream);
                    }

                    successCount++;
                    _logger.LogInformation($"批量上传 - 已成功上传照片：{filePath}");
                }
                catch (Exception ex)
                {
                    errors.Add($"{file.FileName}: {ex.Message}");
                    _logger.LogError($"批量上传 - 文件 {file.FileName} 上传失败: {ex.Message}");
                }
                finally
                {
                    processedCount++;
                    // 更新进度
                    UpdateUploadProgress(batchId, processedCount);
                    
                    // 模拟更真实的上传过程
                    await Task.Delay(500);
                }
            }

            // 标记上传完成
            if (errors.Count == 0)
            {
                MarkUploadAsCompleted(batchId);
            }
            else if (successCount > 0)
            {
                string errorMessage = $"部分文件上传失败: {string.Join("; ", errors)}";
                MarkUploadAsPartialSuccess(batchId, errorMessage, successCount);
            }
            else
            {
                string errorMessage = $"所有文件上传失败: {string.Join("; ", errors)}";
                MarkUploadAsFailed(batchId, errorMessage);
            }
        }
        
        /// <summary>
        /// 更新上传进度
        /// </summary>
        private void UpdateUploadProgress(string batchId, int uploadedCount)
        {
            if (_uploadStatuses.TryGetValue(batchId, out var status))
            {
                status.UploadedCount = uploadedCount;
                status.Progress = (float)uploadedCount / status.TotalCount;
                _uploadStatuses[batchId] = status;
            }
        }
        
        /// <summary>
        /// 标记上传完成
        /// </summary>
        private void MarkUploadAsCompleted(string batchId)
        {
            if (_uploadStatuses.TryGetValue(batchId, out var status))
            {
                status.IsUploading = false;
                status.IsSuccess = true;
                status.Progress = 1.0f;
                status.UploadedCount = status.TotalCount;
                status.EndTime = DateTime.Now;
                _uploadStatuses[batchId] = status;
            }
        }
        
        /// <summary>
        /// 标记部分上传成功
        /// </summary>
        private void MarkUploadAsPartialSuccess(string batchId, string message, int successCount)
        {
            if (_uploadStatuses.TryGetValue(batchId, out var status))
            {
                status.IsUploading = false;
                status.IsSuccess = true;  // 部分成功也算成功
                status.Error = message;
                status.UploadedCount = successCount;
                status.Progress = (float)successCount / status.TotalCount;
                status.EndTime = DateTime.Now;
                _uploadStatuses[batchId] = status;
            }
        }
        
        /// <summary>
        /// 标记上传失败
        /// </summary>
        private void MarkUploadAsFailed(string batchId, string error)
        {
            if (_uploadStatuses.TryGetValue(batchId, out var status))
            {
                status.IsUploading = false;
                status.IsSuccess = false;
                status.Error = error;
                status.EndTime = DateTime.Now;
                _uploadStatuses[batchId] = status;
            }
        }

        /// <summary>
        /// 删除指定项目的所有照片
        /// </summary>
        /// <param name="moduleId">模块ID</param>
        /// <param name="moduleType">模块类型</param>
        /// <returns>删除结果</returns>
        [HttpDelete("delete")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public IActionResult DeleteProjectPhotos(string moduleId, string moduleType)
        {
            try
            {
                if (string.IsNullOrEmpty(moduleId) || string.IsNullOrEmpty(moduleType))
                {
                    return BadRequest("模块ID和类型不能为空");
                }

                // 查找该项目的文件夹
                string projectFolder = Path.Combine(_uploadFolder, moduleType);
                if (!Directory.Exists(projectFolder))
                {
                    return Ok(new { message = "没有找到该项目的照片" });
                }

                // 查找以moduleId开头的所有文件夹（支持带项目名称的格式）
                var directories = Directory.GetDirectories(projectFolder)
                    .Where(dir => Path.GetFileName(dir).StartsWith(moduleId))
                    .ToList();

                if (directories.Count == 0)
                {
                    return Ok(new { message = "没有找到该项目的照片" });
                }

                int deletedCount = 0;
                foreach (var dir in directories)
                {
                    if (Directory.Exists(dir))
                    {
                        string[] files = Directory.GetFiles(dir);
                        deletedCount += files.Length;

                        // 删除文件
                        foreach (var file in files)
                        {
                            System.IO.File.Delete(file);
                        }

                        // 删除空文件夹
                        Directory.Delete(dir, true);
                    }
                }

                _logger.LogInformation($"已删除项目 {moduleType}/{moduleId} 的 {deletedCount} 张照片");

                return Ok(new
                {
                    message = $"已删除 {deletedCount} 张照片",
                    moduleId,
                    moduleType,
                    count = deletedCount
                });
            }
            catch (Exception ex)
            {
                _logger.LogError($"删除项目照片失败：{ex.Message}");
                return StatusCode(500, $"删除项目照片失败：{ex.Message}");
            }
        }
    }
    
    /// <summary>
    /// 上传状态类
    /// </summary>
    public class UploadStatus
    {
        public string BatchId { get; set; }
        public string ModuleId { get; set; }
        public string ModuleType { get; set; }
        public int TotalCount { get; set; }
        public int UploadedCount { get; set; }
        public float Progress { get; set; }
        public bool IsUploading { get; set; }
        public bool IsSuccess { get; set; }
        public string Error { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime? EndTime { get; set; }
        public string UploadPhotoType { get; set; }
        public string UploadTypeId { get; set; }
    }
} 