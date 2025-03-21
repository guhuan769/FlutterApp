//using Microsoft.AspNetCore.Mvc;
//using System;
//using System.Collections.Generic;
//using System.IO;
//using System.Linq;
//using System.Net;
//using System.Threading.Tasks;
//using PlyFileProcessor.Models;
//using PlyFileProcessor.Services;
//using System.Diagnostics;

//namespace PlyFileProcessor.Controllers
//{
//    [ApiController]
//    [Produces("application/json")]
//    public class HealthController : ControllerBase
//    {
//        private readonly ILogger<HealthController> _logger;
//        private readonly IMqttClientService _mqttClientService;
//        private readonly IPlyFileService _plyFileService;

//        public HealthController(
//            ILogger<HealthController> logger,
//            IMqttClientService mqttClientService,
//            IPlyFileService plyFileService)
//        {
//            _logger = logger;
//            _mqttClientService = mqttClientService;
//            _plyFileService = plyFileService;
//        }

//        /// <summary>
//        /// 获取基本状态
//        /// </summary>
//        /// <remarks>
//        /// 返回服务是否正常运行的基本信息。
//        /// </remarks>
//        /// <returns>状态信息</returns>
//        /// <response code="200">服务正常运行</response>
//        //[HttpGet("/health")]
//        //[ProducesResponseType(StatusCodes.Status200OK)]
//        public IActionResult Get()
//        {
//            return Ok(new
//            {
//                status = "healthy",
//                timestamp = DateTime.Now.ToString("o"),
//                service = "PLY File Processor"
//            });
//        }

//        /// <summary>
//        /// 获取详细状态
//        /// </summary>
//        /// <remarks>
//        /// 返回详细的系统状态，包括MQTT连接、文件系统等信息。
//        /// </remarks>
//        /// <returns>详细状态信息</returns>
//        /// <response code="200">详细信息</response>
//        //[HttpGet("/health/details")]
//        //[ProducesResponseType(StatusCodes.Status200OK)]
//        public IActionResult GetDetails()
//        {
//            var uploadFolderPath = "uploaded_images";
//            var plyCheckPath = _plyFileService.GetPlyCheckPath();

//            // 检查目录是否存在并可写
//            bool uploadFolderAccessible = Directory.Exists(uploadFolderPath) && IsDirectoryWritable(uploadFolderPath);
//            bool plyFolderAccessible = Directory.Exists(plyCheckPath) && IsDirectoryWritable(plyCheckPath);

//            var healthDetails = new
//            {
//                status = "healthy",
//                timestamp = DateTime.Now.ToString("o"),
//                service = "PLY File Processor",
//                uptime = GetUptime(),
//                environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production",
//                system = new
//                {
//                    os = Environment.OSVersion.ToString(),
//                    machine_name = Environment.MachineName,
//                    processor_count = Environment.ProcessorCount,
//                    dotnet_version = Environment.Version.ToString(),
//                    working_directory = Environment.CurrentDirectory
//                },
//                mqtt = new
//                {
//                    connected = _mqttClientService.IsConnected,
//                    broker = _mqttClientService.GetBrokerInfo(),
//                    client_id = _mqttClientService.GetClientId()
//                },
//                storage = new
//                {
//                    upload_folder = new
//                    {
//                        path = Path.GetFullPath(uploadFolderPath),
//                        accessible = uploadFolderAccessible,
//                        space_available = GetAvailableDiskSpace(uploadFolderPath)
//                    },
//                    ply_folder = new
//                    {
//                        path = Path.GetFullPath(plyCheckPath),
//                        accessible = plyFolderAccessible,
//                        space_available = GetAvailableDiskSpace(plyCheckPath)
//                    }
//                },
//                network = new
//                {
//                    hostname = Dns.GetHostName(),
//                    ip_addresses = GetIpAddresses()
//                }
//            };

//            _logger.LogInformation("健康检查请求: {@HealthDetails}", healthDetails);
//            return Ok(healthDetails);
//        }

//        /// <summary>
//        /// 重置MQTT连接
//        /// </summary>
//        /// <remarks>
//        /// 尝试重新连接MQTT客户端。
//        /// </remarks>
//        /// <returns>重连结果</returns>
//        /// <response code="200">重连结果</response>
//        //[HttpPost("/health/reset-mqtt")]
//        //[ProducesResponseType(StatusCodes.Status200OK)]
//        public async Task<IActionResult> ResetMqtt()
//        {
//            _logger.LogInformation("手动重置MQTT连接请求");

//            try
//            {
//                await _mqttClientService.StartAsync();
//                return Ok(new ApiResponse
//                {
//                    Code = 200,
//                    Message = "MQTT连接已重置"
//                });
//            }
//            catch (Exception ex)
//            {
//                _logger.LogError(ex, "重置MQTT连接失败");
//                return StatusCode(500, ApiResponse.Error($"重置MQTT连接失败: {ex.Message}"));
//            }
//        }

//        // 帮助方法
//        private string GetUptime()
//        {
//            var processStartTime = Process.GetCurrentProcess().StartTime;
//            var uptime = DateTime.Now - processStartTime;
//            return $"{uptime.Days}天 {uptime.Hours}小时 {uptime.Minutes}分钟";
//        }

//        private bool IsDirectoryWritable(string path)
//        {
//            try
//            {
//                using (var fs = new FileStream(
//                    Path.Combine(path, $"test_{Guid.NewGuid()}.tmp"),
//                    FileMode.Create,
//                    FileAccess.Write,
//                    FileShare.None,
//                    4096,
//                    FileOptions.DeleteOnClose))
//                {
//                    fs.WriteByte(0);
//                    return true;
//                }
//            }
//            catch
//            {
//                return false;
//            }
//        }

//        private string GetAvailableDiskSpace(string path)
//        {
//            try
//            {
//                var driveInfo = new DriveInfo(Path.GetPathRoot(Path.GetFullPath(path)));
//                return FormatBytes(driveInfo.AvailableFreeSpace);
//            }
//            catch
//            {
//                return "未知";
//            }
//        }

//        private string FormatBytes(long bytes)
//        {
//            string[] suffixes = { "B", "KB", "MB", "GB", "TB" };
//            int counter = 0;
//            decimal number = bytes;

//            while (Math.Round(number / 1024) >= 1)
//            {
//                number = number / 1024;
//                counter++;
//            }

//            return $"{number:n2} {suffixes[counter]}";
//        }

//        private IEnumerable<string> GetIpAddresses()
//        {
//            return Dns.GetHostAddresses(Dns.GetHostName())
//                .Where(ip => ip.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork)
//                .Select(ip => ip.ToString());
//        }
//    }
//}