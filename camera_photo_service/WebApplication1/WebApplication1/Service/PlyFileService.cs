using PlyFileProcessor.Helper;
using System.Diagnostics.Eventing.Reader;
using System.IO.Compression;
using System.Text.Json;

namespace PlyFileProcessor.Services.Implementation
{
    /// <summary>
    /// PLY文件服务实现
    /// </summary>
    public class PlyFileService : IPlyFileService
    {
        private readonly ILogger<PlyFileService> _logger;
        private readonly IMqttClientService _mqttClientService;
        private readonly string _plyCheckPath;
        private readonly string _mqttTopic;
        private readonly SemaphoreSlim _processingLock = new SemaphoreSlim(1, 1);

        /// <summary>
        /// 初始化PLY文件服务
        /// </summary>
        /// <param name="logger">日志记录器</param>
        /// <param name="mqttClientService">MQTT客户端服务</param>
        /// <param name="configuration">配置</param>
        public PlyFileService(ILogger<PlyFileService> logger, IMqttClientService mqttClientService, IConfiguration configuration)
        {
            _logger = logger;
            _mqttClientService = mqttClientService;

            // 从配置或环境变量获取PLY检查路径
            _plyCheckPath = Environment.GetEnvironmentVariable("PLY_CHECK_PATH") ??
                            configuration["PlyCheckPath"] ??
                            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Desktop), "code", "Test");

            // 从配置或环境变量获取MQTT主题
            _mqttTopic = Environment.GetEnvironmentVariable("MQTT_TOPIC") ??
                         configuration["MqttSettings:Topic"] ??
                         "ply/files";

            // 确保PLY检查路径存在
            try
            {
                Directory.CreateDirectory(_plyCheckPath);
                _logger.LogInformation("PLY检查路径已创建: {PlyCheckPath}", _plyCheckPath);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "创建PLY检查路径失败: {PlyCheckPath}", _plyCheckPath);
            }
        }

        /// <summary>
        /// 获取PLY检查路径
        /// </summary>
        /// <returns>PLY文件检查路径</returns>
        public string GetPlyCheckPath()
        {
            return _plyCheckPath;
        }

        /// <summary>
        /// 检查并处理PLY文件
        /// </summary>
        /// <param name="taskId">任务ID</param>
        /// <param name="projectName">项目名称</param>
        /// <returns>是否找到并处理了PLY文件</returns>
        public async Task<bool> CheckAndProcessPlyFilesAsync(string taskId, string projectName)
        {
            await _processingLock.WaitAsync();
            try
            {
                _logger.LogInformation("开始检查PLY文件 - TaskID: {TaskId}, 项目: {ProjectName}", taskId, projectName);
                _logger.LogInformation("PLY检查路径: {PlyCheckPath}", _plyCheckPath);

                //# 根据返回值处理逻辑
                //                if 1 == 1:
                //        print("错误：输入文件夹中没有图片文件。")
                //    elif 2 == 2:
                //        print("错误：输出文件夹中没有点云文件。")
                //    elif 3 == 3:
                //        print("处理完成，输出目录中包含图片。")
                //    else:
                //        print("发生未知错误。")

                // 根据python 文件获取他的状态 文件路径 1 成功 2 失败
                // 调用Python脚本并获取结果
                (int statusCode, string resultMessage) = Common.RunPythonScript("main.py");

                if (statusCode == 1)
                {
                    // 成功不给予理会
                }
                else if (statusCode == 2)
                {
                    return false;
                }
                else if (statusCode == 3)
                {
                    return false;
                }


                var plyFiles = Directory.GetFiles(_plyCheckPath, "*.ply");
                _logger.LogInformation("找到 {Count} 个PLY文件", plyFiles.Length);

                if (plyFiles.Length == 0)
                {
                    _logger.LogWarning("未找到PLY文件 - TaskID: {TaskId}", taskId);
                    var noFilesMessage = new
                    {
                        type = "no_ply_files",
                        task_id = taskId,
                        message = "未找到PLY文件，生成失败",
                        project_name = projectName,
                        timestamp = DateTime.Now.ToString("O")
                    };

                    await _mqttClientService.PublishAsync(_mqttTopic, JsonSerializer.Serialize(noFilesMessage));
                    return false;
                }

                // 创建ZIP文件
                var zipPath = Path.Combine(_plyCheckPath, $"ply_files_{taskId}.zip");
                _logger.LogInformation("创建ZIP文件: {ZipPath}", zipPath);

                using (var zipArchive = ZipFile.Open(zipPath, ZipArchiveMode.Create))
                {
                    foreach (var plyFile in plyFiles)
                    {
                        _logger.LogInformation("添加文件到ZIP: {PlyFile}", plyFile);
                        zipArchive.CreateEntryFromFile(plyFile, Path.GetFileName(plyFile), CompressionLevel.Optimal);
                    }
                }

                // 读取并发送ZIP文件
                _logger.LogInformation("读取ZIP文件准备发送");
                var fileBytes = await File.ReadAllBytesAsync(zipPath);
                var fileBase64 = Convert.ToBase64String(fileBytes);

                _logger.LogInformation("ZIP文件大小: {Size} 字节, Base64长度: {Length}",
                    fileBytes.Length, fileBase64.Length);

                var message = new
                {
                    type = "ply_files",
                    task_id = taskId,
                    fileName = Path.GetFileName(zipPath),
                    fileData = fileBase64,
                    project_name = projectName,
                    timestamp = DateTime.Now.ToString("O")
                };

                _logger.LogInformation("发送MQTT消息: {Type}, 任务ID: {TaskId}", message.type, message.task_id);
                await _mqttClientService.PublishAsync(_mqttTopic, JsonSerializer.Serialize(message));

                // 清理ZIP文件
                _logger.LogInformation("删除临时ZIP文件: {ZipPath}", zipPath);
                File.Delete(zipPath);

                _logger.LogInformation("PLY文件处理完成 - TaskID: {TaskId}", taskId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "处理PLY文件失败 - TaskID: {TaskId}", taskId);
                var errorMessage = new
                {
                    type = "error",
                    task_id = taskId,
                    error = ex.Message,
                    project_name = projectName,
                    timestamp = DateTime.Now.ToString("O")
                };

                await _mqttClientService.PublishAsync(_mqttTopic, JsonSerializer.Serialize(errorMessage));
                return false;
            }
            finally
            {
                _processingLock.Release();
            }
        }
    }
}