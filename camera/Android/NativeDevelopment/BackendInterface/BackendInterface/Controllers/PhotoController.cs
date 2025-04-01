using Microsoft.AspNetCore.Mvc;
using System;
using System.IO;
using System.Threading.Tasks;
using System.Linq;
using Microsoft.Extensions.Logging;

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
        /// <returns>上传结果</returns>
        [HttpPost("upload")]
        [Consumes("multipart/form-data")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<IActionResult> Upload(string moduleId, string moduleType, string photoType, string projectName = "")
        {
            try
            {
                var file = Request.Form.Files.FirstOrDefault();
                
                if (file == null || file.Length == 0)
                {
                    return BadRequest("未提供有效的文件");
                }

                // 创建基于模块类型和ID的子文件夹
                string subfolder = Path.Combine(_uploadFolder, moduleType, moduleId);
                
                // 如果提供了项目名称，则使用项目名称作为子文件夹名
                if (!string.IsNullOrEmpty(projectName))
                {
                    subfolder = Path.Combine(_uploadFolder, moduleType, $"{moduleId}_{projectName}");
                }
                
                if (!Directory.Exists(subfolder))
                {
                    Directory.CreateDirectory(subfolder);
                }

                // 生成唯一文件名，防止文件覆盖
                string fileName = $"{Guid.NewGuid()}_{file.FileName}";
                string filePath = Path.Combine(subfolder, fileName);

                // 保存文件
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                _logger.LogInformation($"已成功上传照片：{filePath}，项目名称：{projectName}");

                // 返回成功信息
                return Ok(new 
                { 
                    fileName,
                    filePath,
                    moduleId,
                    moduleType,
                    photoType,
                    projectName,
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
} 