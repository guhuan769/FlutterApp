using MQTTnet;
using MQTTnet.Client;
using MQTTnet.Client.Connecting;
using MQTTnet.Client.Disconnecting;
using MQTTnet.Client.Options;
using System.Text;

namespace PlyFileProcessor
{
    public interface IMqttClientService
    {
        Task StartAsync();
        Task PublishAsync(string topic, string payload);
        bool IsConnected { get; }
        string GetClientId();
        string GetBrokerInfo();
    }

    public class MqttClientService : IMqttClientService, IDisposable
    {
        private readonly ILogger<MqttClientService> _logger;
        private readonly IConfiguration _configuration;
        private IMqttClient _mqttClient;
        private string _mqttBroker;
        private int _mqttPort;
        private string _mqttTopic;
        private string _clientId;
        private readonly SemaphoreSlim _connectionLock = new SemaphoreSlim(1, 1);
        private Timer _reconnectTimer;
        private readonly TimeSpan _reconnectInterval = TimeSpan.FromSeconds(5);
        private bool _disposed = false;

        public bool IsConnected => _mqttClient?.IsConnected ?? false;

        public MqttClientService(ILogger<MqttClientService> logger, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;

            // 从配置或环境变量获取MQTT设置
            _mqttBroker = Environment.GetEnvironmentVariable("MQTT_BROKER") ??
                          _configuration.GetValue<string>("MqttSettings:BrokerAddress") ??
                          "localhost";

            _mqttPort = Environment.GetEnvironmentVariable("MQTT_PORT") != null ?
                        int.Parse(Environment.GetEnvironmentVariable("MQTT_PORT")) :
                        _configuration.GetValue<int>("MqttSettings:BrokerPort", 1883);

            _mqttTopic = Environment.GetEnvironmentVariable("MQTT_TOPIC") ??
                         _configuration.GetValue<string>("MqttSettings:Topic") ??
                         "ply/files";

            _clientId = Environment.GetEnvironmentVariable("MQTT_CLIENT_ID") ??
                        _configuration.GetValue<string>("MqttSettings:ClientId") ??
                        $"dotnet-server-{Guid.NewGuid()}";

            _logger.LogInformation("MQTT设置初始化完成 - 代理: {Broker}:{Port}, 主题: {Topic}, 客户端ID: {ClientId}",
                _mqttBroker, _mqttPort, _mqttTopic, _clientId);
        }

        public string GetClientId() => _clientId;

        public string GetBrokerInfo() => $"{_mqttBroker}:{_mqttPort}";

        public async Task StartAsync()
        {
            await _connectionLock.WaitAsync();
            try
            {
                _logger.LogInformation("启动MQTT客户端...");
                var factory = new MqttFactory();
                _mqttClient = factory.CreateMqttClient();

                var options = new MqttClientOptionsBuilder()
                    .WithTcpServer(_mqttBroker, _mqttPort)
                    .WithClientId(_clientId)
                    .WithCleanSession()
                    .Build();

                _mqttClient.UseConnectedHandler(async e => await OnConnected(e));
                _mqttClient.UseDisconnectedHandler(async e => await OnDisconnected(e));

                await ConnectAsync(options);

                // 启动重连定时器
                _reconnectTimer = new Timer(async _ => await CheckConnection(), null, _reconnectInterval, _reconnectInterval);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "启动MQTT客户端失败");
                throw;
            }
            finally
            {
                _connectionLock.Release();
            }
        }

        private async Task ConnectAsync(IMqttClientOptions options)
        {
            try
            {
                _logger.LogInformation("正在连接到MQTT代理 {Broker}:{Port}...", _mqttBroker, _mqttPort);
                await _mqttClient.ConnectAsync(options, CancellationToken.None);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "连接到MQTT代理失败");
                throw;
            }
        }

        private async Task OnConnected(MqttClientConnectedEventArgs e)
        {
            _logger.LogInformation("MQTT客户端已连接到 {Broker}:{Port}, 结果: {ResultCode}",
                _mqttBroker, _mqttPort, e.ConnectResult.ResultCode);

            // 可以在这里订阅主题
            // await _mqttClient.SubscribeAsync(new MqttTopicFilterBuilder().WithTopic("some/topic").Build());
        }

        private async Task OnDisconnected(MqttClientDisconnectedEventArgs e)
        {
            _logger.LogWarning("MQTT客户端断开连接: {Reason}", e.Exception?.Message ?? "未知原因");
        }

        private async Task CheckConnection()
        {
            if (_disposed) return;

            await _connectionLock.WaitAsync();
            try
            {
                if (_mqttClient == null || !_mqttClient.IsConnected)
                {
                    _logger.LogInformation("检测到MQTT连接断开，尝试重新连接...");

                    var options = new MqttClientOptionsBuilder()
                        .WithTcpServer(_mqttBroker, _mqttPort)
                        .WithClientId(_clientId)
                        .WithCleanSession()
                        .Build();

                    try
                    {
                        await ConnectAsync(options);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "MQTT重新连接失败");
                    }
                }
            }
            finally
            {
                _connectionLock.Release();
            }
        }

        public async Task PublishAsync(string topic, string payload)
        {
            if (_disposed)
            {
                _logger.LogWarning("尝试使用已释放的MQTT客户端服务发送消息");
                return;
            }

            if (!IsConnected)
            {
                _logger.LogWarning("MQTT客户端未连接，无法发送消息");
                return;
            }

            try
            {
                var message = new MqttApplicationMessageBuilder()
                    .WithTopic(topic)
                    .WithPayload(payload)
                    .WithQualityOfServiceLevel(MQTTnet.Protocol.MqttQualityOfServiceLevel.AtLeastOnce)
                    .WithRetainFlag(false)
                    .Build();

                await _mqttClient.PublishAsync(message, CancellationToken.None);

                // 记录消息发送（但不包含完整的负载，因为可能很大）
                var payloadInfo = payload.Length > 100
                    ? $"{payload.Substring(0, 100)}... [长度: {payload.Length}]"
                    : payload;

                _logger.LogInformation("已发送MQTT消息到主题: {Topic}, 负载大小: {PayloadSize}字节",
                    topic, Encoding.UTF8.GetByteCount(payload));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "发送MQTT消息失败");
                throw;
            }
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        protected virtual void Dispose(bool disposing)
        {
            if (_disposed) return;

            if (disposing)
            {
                // 释放托管资源
                _reconnectTimer?.Dispose();
                _connectionLock?.Dispose();

                try
                {
                    if (_mqttClient != null && _mqttClient.IsConnected)
                    {
                        _mqttClient.DisconnectAsync().GetAwaiter().GetResult();
                    }
                    _mqttClient?.Dispose();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "关闭MQTT客户端时发生错误");
                }
            }

            _disposed = true;
        }

        ~MqttClientService()
        {
            Dispose(false);
        }
    }
}