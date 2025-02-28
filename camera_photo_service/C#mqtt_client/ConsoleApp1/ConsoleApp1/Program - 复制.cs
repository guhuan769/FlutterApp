//using Microsoft.Extensions.Logging;
//using MQTTnet;
//using MQTTnet.Client;
//using MQTTnet.Protocol;
//using System.Text;
//using System.Text.Json;
//using Microsoft.Extensions.DependencyInjection;
//using Microsoft.Extensions.Hosting;
//using System.Collections.Concurrent;
//using Microsoft.Extensions.Configuration;

//namespace PlyFileProcessor
//{
//    public class MqttPlyClient : IHostedService
//    {
//        private readonly IMqttClient _mqttClient;
//        private readonly ILogger<MqttPlyClient> _logger;
//        private readonly string _saveDirectory;
//        private readonly SemaphoreSlim _processingSemaphore;
//        private int _reconnectDelay = 5000;

//        public MqttPlyClient(ILogger<MqttPlyClient> logger, IConfiguration configuration)
//        {
//            _logger = logger;
//            _saveDirectory = configuration["Mqtt:SaveDirectory"] ?? "ply_files";
//            _processingSemaphore = new SemaphoreSlim(1, 1);

//            var mqttFactory = new MqttFactory();
//            _mqttClient = mqttFactory.CreateMqttClient();

//            ConfigureMqttClient();
//        }

//        private void ConfigureMqttClient()
//        {
//            _mqttClient.ConnectedAsync += HandleConnectedAsync;
//            _mqttClient.DisconnectedAsync += HandleDisconnectedAsync;
//            _mqttClient.ApplicationMessageReceivedAsync += HandleMessageReceivedAsync;
//        }

//        private async Task HandleConnectedAsync(MqttClientConnectedEventArgs args)
//        {
//            _logger.LogInformation("已连接到 MQTT 服务器");

//            // 订阅主题
//            var mqttSubscribeOptions = new MqttClientSubscribeOptionsBuilder()
//                .WithTopicFilter(f =>
//                {
//                    f.WithTopic("ply/files");
//                    f.WithQualityOfServiceLevel(MqttQualityOfServiceLevel.AtLeastOnce);
//                })
//                .Build();

//            await _mqttClient.SubscribeAsync(mqttSubscribeOptions);
//            _logger.LogInformation("已订阅主题：ply/files");
//        }

//        private async Task HandleDisconnectedAsync(MqttClientDisconnectedEventArgs args)
//        {
//            _logger.LogWarning("MQTT 客户端断开连接");

//            while (!_mqttClient.IsConnected)
//            {
//                try
//                {
//                    await Task.Delay(_reconnectDelay);
//                    await ConnectToMqttServer();
//                }
//                catch (Exception ex)
//                {
//                    _logger.LogError(ex, "重新连接失败");
//                    _reconnectDelay = Math.Min(_reconnectDelay * 2, 60000); // 最大延迟1分钟
//                }
//            }
//        }

//        private async Task HandleMessageReceivedAsync(MqttApplicationMessageReceivedEventArgs args)
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

//                _logger.LogInformation("收到消息类型: {Type}", message.Type);

//                switch (message.Type?.ToLower())
//                {
//                    case "ply_files":
//                        await ProcessPlyFilesAsync(message);
//                        break;
//                    case "no_ply_files":
//                        _logger.LogWarning("未找到 PLY 文件 - TaskId: {TaskId}", message.TaskId);
//                        break;
//                    case "error":
//                        _logger.LogError("错误消息 - TaskId: {TaskId}, Error: {Error}",
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
//            var taskDirectory = Path.Combine(_saveDirectory, message.TaskId);
//            var processingPath = Path.Combine(taskDirectory, "processing");
//            var completedPath = Path.Combine(taskDirectory, "completed");

//            try
//            {
//                Directory.CreateDirectory(processingPath);
//                Directory.CreateDirectory(completedPath);

//                // 保存 ZIP 文件
//                var zipPath = Path.Combine(processingPath, message.FileName);
//                var zipData = Convert.FromBase64String(message.FileData);
//                await File.WriteAllBytesAsync(zipPath, zipData);

//                // 解压文件
//                System.IO.Compression.ZipFile.ExtractToDirectory(zipPath, completedPath, true);

//                _logger.LogInformation("PLY 文件处理完成 - TaskId: {TaskId}", message.TaskId);

//                // 清理处理目录
//                Directory.Delete(processingPath, true);
//            }
//            catch (Exception ex)
//            {
//                _logger.LogError(ex, "处理 PLY 文件失败 - TaskId: {TaskId}", message.TaskId);
//                throw;
//            }
//        }

//        private async Task SendAcknowledgementAsync(string taskId)
//        {
//            var message = new MqttApplicationMessageBuilder()
//                .WithTopic("ply/acknowledgement")
//                .WithPayload(JsonSerializer.Serialize(new
//                {
//                    type = "acknowledgement",
//                    taskId = taskId,
//                    timestamp = DateTime.UtcNow
//                }))
//                .WithQualityOfServiceLevel(MqttQualityOfServiceLevel.AtLeastOnce)
//                .Build();

//            await _mqttClient.PublishAsync(message);
//            _logger.LogInformation("已发送确认消息 - TaskId: {TaskId}", taskId);
//        }

//        private async Task ConnectToMqttServer()
//        {
//            var mqttClientOptions = new MqttClientOptionsBuilder()
//                .WithTcpServer("localhost", 1883)
//                .WithClientId($"ply-processor-{Guid.NewGuid()}")
//                .WithCleanSession()
//                .Build();

//            await _mqttClient.ConnectAsync(mqttClientOptions);
//        }

//        public async Task StartAsync(CancellationToken cancellationToken)
//        {
//            try
//            {
//                await ConnectToMqttServer();
//                _logger.LogInformation("MQTT 客户端服务已启动");
//            }
//            catch (Exception ex)
//            {
//                _logger.LogError(ex, "启动 MQTT 客户端服务失败");
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
//                            clientId = Guid.NewGuid().ToString(),
//                            timestamp = DateTime.UtcNow
//                        }))
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
//                _logger.LogError(ex, "停止 MQTT 客户端时发生错误");
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
//    }

//    // Program.cs
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