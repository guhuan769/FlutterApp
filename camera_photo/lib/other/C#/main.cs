using MQTTnet;
using MQTTnet.Client;
using System.Text;
using System.Text.Json;

namespace PlyFileProcessor
{
    public class MqttPlyClient : IDisposable
    {
        private readonly IMqttClient _mqttClient;
        private readonly MqttClientOptions _options;
        private readonly string _saveDirectory;
        private readonly ILogger<MqttPlyClient> _logger;

        public MqttPlyClient(ILogger<MqttPlyClient> logger, string brokerAddress, string saveDirectory)
        {
            _logger = logger;
            _saveDirectory = saveDirectory;

            var factory = new MqttFactory();
            _mqttClient = factory.CreateMqttClient();

            _options = new MqttClientOptionsBuilder()
                .WithTcpServer(brokerAddress)
                .WithProtocolVersion(MQTTnet.Formatter.MqttProtocolVersion.V500)
                .WithClientId($"ply-processor-{Guid.NewGuid()}")
                .Build();

            ConfigureClient();
        }

        private void ConfigureClient()
        {
            _mqttClient.ApplicationMessageReceivedAsync += HandleMessageAsync;
            _mqttClient.DisconnectedAsync += HandleDisconnectAsync;
        }

        public async Task StartAsync()
        {
            try
            {
                await _mqttClient.ConnectAsync(_options);

                var topicFilter = new MqttTopicFilterBuilder()
                    .WithTopic("ply/files")
                    .Build();

                await _mqttClient.SubscribeAsync(topicFilter);

                _logger.LogInformation("已连接到MQTT服务器并订阅主题");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "连接MQTT服务器失败");
                throw;
            }
        }

        private async Task HandleMessageAsync(MqttApplicationMessageReceivedEventArgs args)
        {
            try
            {
                var payload = Encoding.UTF8.GetString(args.ApplicationMessage.PayloadSegment);
                var message = JsonSerializer.Deserialize<MqttMessage>(payload);

                switch (message.Type)
                {
                    case "ply_files":
                        await ProcessPlyFilesAsync(message);
                        break;
                    case "no_ply_files":
                        _logger.LogWarning($"任务 {message.TaskId} 未找到PLY文件");
                        break;
                    case "error":
                        _logger.LogError($"任务 {message.TaskId} 发生错误: {message.Error}");
                        break;
                }

                // 发送确认消息
                await SendAcknowledgementAsync(message.TaskId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "处理MQTT消息失败");
            }
        }

        private async Task ProcessPlyFilesAsync(MqttMessage message)
        {
            try
            {
                _logger.LogInformation($"接收到PLY文件包 - 任务ID: {message.TaskId}");

                // 确保保存目录存在
                var taskDirectory = Path.Combine(_saveDirectory, message.TaskId);
                Directory.CreateDirectory(taskDirectory);

                // 解码并保存ZIP文件
                var zipPath = Path.Combine(taskDirectory, message.FileName);
                var zipData = Convert.FromBase64String(message.FileData);
                await File.WriteAllBytesAsync(zipPath, zipData);

                // 解压ZIP文件
                var extractPath = Path.Combine(taskDirectory, "extracted");
                Directory.CreateDirectory(extractPath);
                System.IO.Compression.ZipFile.ExtractToDirectory(zipPath, extractPath, true);

                _logger.LogInformation($"任务 {message.TaskId} 的PLY文件已成功处理和保存");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"处理PLY文件失败 - 任务ID: {message.TaskId}");
                throw;
            }
        }

        private async Task SendAcknowledgementAsync(string taskId)
        {
            try
            {
                var ackMessage = new
                {
                    type = "acknowledgement",
                    taskId = taskId,
                    timestamp = DateTime.UtcNow
                };

                var payload = JsonSerializer.Serialize(ackMessage);
                var message = new MqttApplicationMessageBuilder()
                    .WithTopic("ply/acknowledgement")
                    .WithPayload(payload)
                    .WithQualityOfServiceLevel(MQTTnet.Protocol.MqttQualityOfServiceLevel.AtLeastOnce)
                    .Build();

                await _mqttClient.PublishAsync(message);
                _logger.LogInformation($"已发送确认消息 - 任务ID: {taskId}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"发送确认消息失败 - 任务ID: {taskId}");
            }
        }

        private async Task HandleDisconnectAsync(MqttClientDisconnectedEventArgs args)
        {
            try
            {
                // 自动重连
                await Task.Delay(TimeSpan.FromSeconds(5));
                await _mqttClient.ConnectAsync(_options);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "重新连接失败");
            }
        }

        public async Task StopAsync()
        {
            if (_mqttClient.IsConnected)
            {
                await _mqttClient.DisconnectAsync();
            }
        }

        public void Dispose()
        {
            _mqttClient?.Dispose();
        }
    }

    public class MqttMessage
    {
        public string Type { get; set; }
        public string TaskId { get; set; }
        public string FileName { get; set; }
        public string FileData { get; set; }
        public string Error { get; set; }
        public DateTime Timestamp { get; set; }
    }

    // Program.cs 示例
    public class Program
    {
        public static async Task Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // 添加日志
            builder.Logging.AddConsole();

            // 注册MqttPlyClient服务
            builder.Services.AddSingleton<MqttPlyClient>(sp =>
            {
                var logger = sp.GetRequiredService<ILogger<MqttPlyClient>>();
                var config = sp.GetRequiredService<IConfiguration>();

                return new MqttPlyClient(
                    logger,
                    config["Mqtt:BrokerAddress"] ?? "localhost",
                    config["Mqtt:SaveDirectory"] ?? "ply_files"
                );
            });

            var app = builder.Build();

            // 获取MqttPlyClient服务并启动
            var mqttClient = app.Services.GetRequiredService<MqttPlyClient>();
            await mqttClient.StartAsync();

            await app.RunAsync();
        }
    }
}