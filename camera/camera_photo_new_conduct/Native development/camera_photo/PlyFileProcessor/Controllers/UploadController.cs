using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace PlyFileProcessor.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UploadController : ControllerBase
    {
        private readonly ILogger<UploadController> _logger;
        private readonly string _uploadFolder;

        public UploadController(ILogger<UploadController> logger, IConfiguration configuration)
        {
            _logger = logger;
            _uploadFolder = configuration.GetValue<string>("UploadFolder");
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

                // ... 继续处理文件上传的其余部分 ...

                return Ok(new
                {
                    code = 200,
                    message = "文件上传成功",
                    data = new { savedFiles, failedFiles }
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
    }
} 