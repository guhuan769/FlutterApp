//using Microsoft.Extensions.Logging;
//using MQTTnet;
//using MQTTnet.Client;
//using MQTTnet.Protocol;
//using System.Text;
//using System.Text.Json;
//using Microsoft.Extensions.Configuration;
//using Microsoft.Extensions.DependencyInjection;
//using Microsoft.Extensions.Hosting;
//using System.Collections.Concurrent;

//namespace PlyFileProcessor
//{
//    public class MqttPlyClient : IHostedService
//    {
//        private readonly IMqttClient _mqttClient;
//        private readonly ILogger<MqttPlyClient> _logger;
//        private readonly string _saveDirectory;
//        private readonly SemaphoreSlim _processingSemaphore;
//        private readonly ConcurrentDictionary<string, bool> _processedFiles;
//        private readonly IConfiguration _configuration;
//        private int _reconnectDelay = 5000;

//        public MqttPlyClient(
//            ILogger<MqttPlyClient> logger,
//            IConfiguration configuration)
//        {
//            _logger = logger;
//            _configuration = configuration;
//            _saveDirectory = configuration["Ply:SaveDirectory"] ?? "ply_files";
//            _processingSemaphore = new SemaphoreSlim(1, 1);
//            _processedFiles = new ConcurrentDictionary<string, bool>();

//            var factory = new MqttFactory();
//            _mqttClient = factory.CreateMqttClient();

//            ConfigureClient();
//        }

//        private void ConfigureClient()
//        {
//            _mqttClient.ApplicationMessageReceivedAsync += HandleMessageAsync;
//            _mqttClient.DisconnectedAsync += HandleDisconnectedAsync;
//            _mqttClient.ConnectedAsync += HandleConnectedAsync;
//        }

//        private async Task HandleConnectedAsync(MqttClientConnectedEventArgs args)
//        {
//            _logger.LogInformation("已连接到MQTT服务器");

//            var topicFilter = new MqttTopicFilterBuilder()
//                .WithTopic("ply/files")
//                .WithQualityOfServiceLevel(MqttQualityOfServiceLevel.AtLeastOnce)
//                .Build();

//            var subscribeOptions = new MqttClientSubscribeOptionsBuilder()
//                .WithTopicFilter(topicFilter)
//                .Build();

//            await _mqttClient.SubscribeAsync(subscribeOptions);
//            _logger.LogInformation("已订阅主题: ply/files");

//            _reconnectDelay = 5000; // 重置重连延迟
//        }

//        private async Task HandleMessageAsync(MqttApplicationMessageReceivedEventArgs args)
//        {
//            try
//            {
//                await _processingSemaphore.WaitAsync();
//                var payload = Encoding.UTF8.GetString(args.ApplicationMessage.PayloadSegment);
//                var message = JsonSerializer.Deserialize<MqttMessage>(payload);

//                if (message == null)
//                {
//                    _logger.LogWarning("收到空消息");
//                    return;
//                }

//                _logger.LogInformation("收到消息类型: {Type}, TaskId: {TaskId}",
//                    message.Type, message.TaskId);

//                switch (message.Type?.ToLower())
//                {
//                    case "ply_files":
//                        await ProcessPlyFilesAsync(message);
//                        break;
//                    case "no_ply_files":
//                        _logger.LogWarning("任务 {TaskId} PLY文件生成失败: {Message}",
//                            message.TaskId, message.Message);
//                        break;
//                    case "error":
//                        _logger.LogError("任务 {TaskId} 发生错误: {Error}",
//                            message.TaskId, message.Error);
//                        break;
//                }

//                await SendAcknowledgementAsync(message.TaskId);
//            }
//            catch (Exception ex)
//            {
//                _logger.LogError(ex, "处理消息时发生错误");
//            }
//            finally
//            {
//                _processingSemaphore.Release();
//            }
//        }

//        private async Task ProcessPlyFilesAsync(MqttMessage message)
//        {
//            try
//            {
//                // 为每个任务创建独立的目录
//                var taskDirectory = Path.Combine(_saveDirectory, message.TaskId);
//                var processingPath = Path.Combine(taskDirectory, "processing");
//                var completedPath = Path.Combine(taskDirectory, "completed");

//                // 创建必要的目录
//                Directory.CreateDirectory(taskDirectory);
//                Directory.CreateDirectory(processingPath);
//                Directory.CreateDirectory(completedPath);

//                _logger.LogInformation("开始处理PLY文件 - TaskId: {TaskId}, FileName: {FileName}",
//                    message.TaskId, message.FileName);

//                // 检查文件是否已处理
//                if (_processedFiles.ContainsKey(message.FileName))
//                {
//                    _logger.LogInformation("文件已处理过: {FileName}", message.FileName);
//                    return;
//                }

//                // 保存ZIP文件
//                var zipPath = Path.Combine(processingPath, message.FileName);
//                var zipData = Convert.FromBase64String(message.FileData);
//                await File.WriteAllBytesAsync(zipPath, zipData);

//                // 解压文件
//                _logger.LogInformation("正在解压文件到: {Path}", completedPath);
//                System.IO.Compression.ZipFile.ExtractToDirectory(zipPath, completedPath, true);

//                // 记录成功处理
//                _processedFiles.TryAdd(message.FileName, true);

//                // 检查解压后的文件
//                var extractedFiles = Directory.GetFiles(completedPath, "*.ply");
//                _logger.LogInformation("成功解压 {Count} 个PLY文件", extractedFiles.Length);

//                // 清理处理目录
//                Directory.Delete(processingPath, true);

//                _logger.LogInformation("PLY文件处理完成 - TaskId: {TaskId}", message.TaskId);

//                // 发送确认消息
//                await SendProcessingConfirmationAsync(message);
//            }
//            catch (Exception ex)
//            {
//                _logger.LogError(ex, "处理PLY文件失败 - TaskId: {TaskId}", message.TaskId);
//                throw;
//            }
//        }

//        private async Task SendProcessingConfirmationAsync(MqttMessage originalMessage)
//        {
//            try
//            {
//                var confirmationMessage = new MqttApplicationMessageBuilder()
//                    .WithTopic("ply/confirmation")
//                    .WithPayload(JsonSerializer.Serialize(new
//                    {
//                        type = "processing_complete",
//                        taskId = originalMessage.TaskId,
//                        fileName = originalMessage.FileName,
//                        timestamp = DateTime.UtcNow,
//                        projectName = originalMessage.ProjectName
//                    }))
//                    .WithQualityOfServiceLevel(MqttQualityOfServiceLevel.AtLeastOnce)
//                    .Build();

//                await _mqttClient.PublishAsync(confirmationMessage);
//                _logger.LogInformation("已发送处理确认 - TaskId: {TaskId}", originalMessage.TaskId);
//            }
//            catch (Exception ex)
//            {
//                _logger.LogError(ex, "发送确认消息失败");
//            }
//        }

//        private async Task SendAcknowledgementAsync(string taskId)
//        {
//            try
//            {
//                var ackMessage = new MqttApplicationMessageBuilder()
//                    .WithTopic("ply/acknowledgement")
//                    .WithPayload(JsonSerializer.Serialize(new
//                    {
//                        type = "acknowledgement",
//                        taskId = taskId,
//                        timestamp = DateTime.UtcNow,
//                        clientId = _mqttClient.Options.ClientId
//                    }))
//                    .WithQualityOfServiceLevel(MqttQualityOfServiceLevel.AtLeastOnce)
//                    .Build();

//                await _mqttClient.PublishAsync(ackMessage);
//                _logger.LogInformation("已发送确认消息 - TaskId: {TaskId}", taskId);
//            }
//            catch (Exception ex)
//            {
//                _logger.LogError(ex, "发送确认消息失败 - TaskId: {TaskId}", taskId);
//            }
//        }

//        private async Task HandleDisconnectedAsync(MqttClientDisconnectedEventArgs args)
//        {
//            try
//            {
//                _logger.LogWarning("MQTT客户端断开连接: {Reason}", args.Reason);

//                while (!_mqttClient.IsConnected)
//                {
//                    try
//                    {
//                        await Task.Delay(_reconnectDelay);
//                        await ConnectToMqttServer();

//                        if (_mqttClient.IsConnected)
//                        {
//                            _logger.LogInformation("重新连接成功");
//                            break;
//                        }
//                    }
//                    catch (Exception ex)
//                    {
//                        _logger.LogError(ex, "重新连接失败，将在{Delay}ms后重试", _reconnectDelay);
//                        _reconnectDelay = Math.Min(_reconnectDelay * 2, 60000); // 最大延迟1分钟
//                    }
//                }
//            }
//            catch (Exception ex)
//            {
//                _logger.LogError(ex, "处理断开连接事件失败");
//            }
//        }

//        private async Task ConnectToMqttServer()
//        {
//            var options = new MqttClientOptionsBuilder()
//                .WithTcpServer(_configuration["Mqtt:BrokerAddress"] ?? "localhost")
//                .WithClientId($"ply-processor-{Guid.NewGuid()}")
//                .WithCleanSession()
//                .Build();

//            await _mqttClient.ConnectAsync(options);
//        }

//        public async Task StartAsync(CancellationToken cancellationToken)
//        {
//            try
//            {
//                await ConnectToMqttServer();
//                _logger.LogInformation("MQTT客户端服务已启动");
//            }
//            catch (Exception ex)
//            {
//                _logger.LogError(ex, "启动MQTT客户端服务失败");
//                throw;
//            }
//        }

//        public async Task StopAsync(CancellationToken cancellationToken)
//        {
//            try
//            {
//                if (_mqttClient.IsConnected)
//                {
//                    // 取消订阅
//                    var unsubscribeOptions = new MqttClientUnsubscribeOptionsBuilder()
//                        .WithTopicFilter("ply/files")
//                        .Build();

//                    await _mqttClient.UnsubscribeAsync(unsubscribeOptions, cancellationToken);

//                    // 发送离线消息
//                    var offlineMessage = new MqttApplicationMessageBuilder()
//                        .WithTopic("ply/clients")
//                        .WithPayload(JsonSerializer.Serialize(new
//                        {
//                            type = "offline",
//                            clientId = _mqttClient.Options.ClientId,
//                            timestamp = DateTime.UtcNow
//                        }))
//                        .WithQualityOfServiceLevel(MqttQualityOfServiceLevel.AtLeastOnce)
//                        .Build();

//                    await _mqttClient.PublishAsync(offlineMessage, cancellationToken);

//                    // 断开连接
//                    var disconnectOptions = new MqttClientDisconnectOptionsBuilder()
//                        .WithReason(MqttClientDisconnectOptionsReason.NormalDisconnection)
//                        .Build();

//                    await _mqttClient.DisconnectAsync(disconnectOptions, cancellationToken);
//                }
//            }
//            catch (Exception ex)
//            {
//                _logger.LogError(ex, "停止MQTT客户端时发生错误");
//            }
//            finally
//            {
//                _processingSemaphore.Dispose();
//            }
//        }
//    }

//    public class MqttMessage
//    {
//        public string Type { get; set; }
//        public string TaskId { get; set; }
//        public string FileName { get; set; }
//        public string FileData { get; set; }
//        public string Error { get; set; }
//        public DateTime Timestamp { get; set; }
//        public string Message { get; set; }
//        public string ProjectName { get; set; }
//    }

//    public class Program
//    {
//        public static async Task Main(string[] args)
//        {
//            var host = Host.CreateDefaultBuilder(args)
//                .ConfigureServices((hostContext, services) =>
//                {
//                    services.AddHostedService<MqttPlyClient>();
//                })
//                .Build();

//            await host.RunAsync();
//        }
//    }
//}














using MQTTnet;
using MQTTnet.Client;
using MQTTnet.Protocol;
using System.Text;
using System.Text.Json;

namespace MqttPlyClient
{
    // 消息模型
    public class FileMessage
    {
        public string Type { get; set; } = string.Empty;
        public string FileName { get; set; } = string.Empty;
        public string FileData { get; set; } = string.Empty;
        public string Timestamp { get; set; } = string.Empty;
    }

    public class Program
    {
        private static IMqttClient? _mqttClient;
        private static readonly string Topic = "ply/files";
        private static readonly string ClientId = $"ply-client-{Guid.NewGuid()}";
        private static readonly string SavePath = @"C:\ReceivedFiles"; // 接收文件保存路径

        public static async Task Main(string[] args)
        {
            try
            {
                // 确保保存目录存在
                Directory.CreateDirectory(SavePath);
                Console.WriteLine($"文件将保存到: {SavePath}");

                await SetupMqttClient();
                Console.WriteLine("MQTT客户端已启动，按任意键退出...");
                Console.ReadKey();

                if (_mqttClient != null)
                {
                    await _mqttClient.DisconnectAsync();
                    Console.WriteLine("已断开MQTT连接");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"发生错误: {ex.Message}");
                Console.WriteLine("按任意键退出...");
                Console.ReadKey();
            }
        }

        private static async Task SetupMqttClient()
        {
            var mqttFactory = new MqttFactory();
            _mqttClient = mqttFactory.CreateMqttClient();

            var options = new MqttClientOptionsBuilder()
                .WithTcpServer("localhost", 1883)
                .WithClientId(ClientId)
                .WithCleanSession()
                .Build();

            _mqttClient.ApplicationMessageReceivedAsync += HandleMessageReceived;

            try
            {
                await _mqttClient.ConnectAsync(options);
                Console.WriteLine("已连接到MQTT服务器");

                var subscribeOptions = mqttFactory.CreateSubscribeOptionsBuilder()
                    .WithTopicFilter(f => f.WithTopic(Topic).WithQualityOfServiceLevel(MqttQualityOfServiceLevel.AtLeastOnce))
                    .Build();

                await _mqttClient.SubscribeAsync(subscribeOptions);
                Console.WriteLine($"已订阅主题: {Topic}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"连接失败: {ex.Message}");
                throw;
            }
        }

        private static async Task HandleMessageReceived(MqttApplicationMessageReceivedEventArgs e)
        {
            try
            {
                var payload = Encoding.UTF8.GetString(e.ApplicationMessage.PayloadSegment);
                Console.WriteLine("接收到新消息...");

                // 反序列化消息
                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };
                var message = JsonSerializer.Deserialize<FileMessage>(payload, options);

                if (message != null && message.Type == "ply_files" && !string.IsNullOrEmpty(message.FileData))
                {
                    Console.WriteLine($"正在接收文件: {message.FileName}");

                    try
                    {
                        // 将base64数据转换回字节数组
                        var fileBytes = Convert.FromBase64String(message.FileData);

                        // 保存文件
                        var filePath = Path.Combine(SavePath, message.FileName);
                        await File.WriteAllBytesAsync(filePath, fileBytes);

                        Console.WriteLine($"文件已保存到: {filePath}");

                        // 发送确认消息
                        await SendAcknowledgement(message.FileName);
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"保存文件时发生错误: {ex.Message}");
                    }
                }
                else
                {
                    Console.WriteLine("收到的消息格式不正确或不包含文件数据");
                }
            }
            catch (JsonException jex)
            {
                Console.WriteLine($"JSON解析错误: {jex.Message}");
                //Console.WriteLine($"原始消息内容: {payload}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"处理消息时发生错误: {ex.Message}");
            }
        }

        private static async Task SendAcknowledgement(string fileName)
        {
            if (_mqttClient?.IsConnected == true)
            {
                try
                {
                    var ackMessage = new MqttApplicationMessageBuilder()
                        .WithTopic($"{Topic}/ack")
                        .WithPayload(JsonSerializer.Serialize(new
                        {
                            clientId = ClientId,
                            fileName = fileName,
                            timestamp = DateTime.Now,
                            status = "received"
                        }))
                        .WithQualityOfServiceLevel(MqttQualityOfServiceLevel.AtLeastOnce)
                        .Build();

                    await _mqttClient.PublishAsync(ackMessage);
                    Console.WriteLine($"已发送确认消息: {fileName}");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"发送确认消息时发生错误: {ex.Message}");
                }
            }
            else
            {
                Console.WriteLine("MQTT客户端未连接，无法发送确认消息");
            }
        }
    }
}