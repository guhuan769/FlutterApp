//using MQTTnet;
//using MQTTnet.Client;
//using MQTTnet.Protocol;
//using System.Text;
//using System.Text.Json;

//namespace MqttPlyClient
//{
//    // 消息模型
//    public class FileMessage1
//    {
//        public string Type { get; set; } = string.Empty;
//        public string FileName { get; set; } = string.Empty;
//        public string FileData { get; set; } = string.Empty;
//        public string Timestamp { get; set; } = string.Empty;
//    }

//    public class Program1
//    {
//        private static IMqttClient? _mqttClient;
//        private static readonly string Topic = "ply/files";
//        private static readonly string ClientId = $"ply-client-{Guid.NewGuid()}";
//        private static readonly string SavePath = @"C:\ReceivedFiles"; // 接收文件保存路径

//        public static async Task Main(string[] args)
//        {
//            try
//            {
//                // 确保保存目录存在
//                Directory.CreateDirectory(SavePath);
//                Console.WriteLine($"文件将保存到: {SavePath}");

//                await SetupMqttClient();
//                Console.WriteLine("MQTT客户端已启动，按任意键退出...");
//                Console.ReadKey();

//                if (_mqttClient != null)
//                {
//                    await _mqttClient.DisconnectAsync();
//                    Console.WriteLine("已断开MQTT连接");
//                }
//            }
//            catch (Exception ex)
//            {
//                Console.WriteLine($"发生错误: {ex.Message}");
//                Console.WriteLine("按任意键退出...");
//                Console.ReadKey();
//            }
//        }

//        private static async Task SetupMqttClient()
//        {
//            var mqttFactory = new MqttFactory();
//            _mqttClient = mqttFactory.CreateMqttClient();

//            var options = new MqttClientOptionsBuilder()
//                .WithTcpServer("localhost", 1883)
//                .WithClientId(ClientId)
//                .WithCleanSession()
//                .Build();

//            _mqttClient.ApplicationMessageReceivedAsync += HandleMessageReceived;

//            try
//            {
//                await _mqttClient.ConnectAsync(options);
//                Console.WriteLine("已连接到MQTT服务器");

//                var subscribeOptions = mqttFactory.CreateSubscribeOptionsBuilder()
//                    .WithTopicFilter(f => f.WithTopic(Topic).WithQualityOfServiceLevel(MqttQualityOfServiceLevel.AtLeastOnce))
//                    .Build();

//                await _mqttClient.SubscribeAsync(subscribeOptions);
//                Console.WriteLine($"已订阅主题: {Topic}");
//            }
//            catch (Exception ex)
//            {
//                Console.WriteLine($"连接失败: {ex.Message}");
//                throw;
//            }
//        }

//        private static async Task HandleMessageReceived(MqttApplicationMessageReceivedEventArgs e)
//        {
//            try
//            {
//                var payload = Encoding.UTF8.GetString(e.ApplicationMessage.PayloadSegment);
//                Console.WriteLine("接收到新消息...");

//                // 反序列化消息
//                var options = new JsonSerializerOptions
//                {
//                    PropertyNameCaseInsensitive = true
//                };
//                var message = JsonSerializer.Deserialize<FileMessage>(payload, options);

//                if (message != null && message.Type == "ply_files" && !string.IsNullOrEmpty(message.FileData))
//                {
//                    Console.WriteLine($"正在接收文件: {message.FileName}");

//                    try
//                    {
//                        // 将base64数据转换回字节数组
//                        var fileBytes = Convert.FromBase64String(message.FileData);

//                        // 保存文件
//                        var filePath = Path.Combine(SavePath, message.FileName);
//                        await File.WriteAllBytesAsync(filePath, fileBytes);

//                        Console.WriteLine($"文件已保存到: {filePath}");

//                        // 发送确认消息
//                        await SendAcknowledgement(message.FileName);
//                    }
//                    catch (Exception ex)
//                    {
//                        Console.WriteLine($"保存文件时发生错误: {ex.Message}");
//                    }
//                }
//                else
//                {
//                    Console.WriteLine("收到的消息格式不正确或不包含文件数据");
//                }
//            }
//            catch (JsonException jex)
//            {
//                Console.WriteLine($"JSON解析错误: {jex.Message}");
//                //Console.WriteLine($"原始消息内容: {payload}");
//            }
//            catch (Exception ex)
//            {
//                Console.WriteLine($"处理消息时发生错误: {ex.Message}");
//            }
//        }

//        private static async Task SendAcknowledgement(string fileName)
//        {
//            if (_mqttClient?.IsConnected == true)
//            {
//                try
//                {
//                    var ackMessage = new MqttApplicationMessageBuilder()
//                        .WithTopic($"{Topic}/ack")
//                        .WithPayload(JsonSerializer.Serialize(new
//                        {
//                            clientId = ClientId,
//                            fileName = fileName,
//                            timestamp = DateTime.Now,
//                            status = "received"
//                        }))
//                        .WithQualityOfServiceLevel(MqttQualityOfServiceLevel.AtLeastOnce)
//                        .Build();

//                    await _mqttClient.PublishAsync(ackMessage);
//                    Console.WriteLine($"已发送确认消息: {fileName}");
//                }
//                catch (Exception ex)
//                {
//                    Console.WriteLine($"发送确认消息时发生错误: {ex.Message}");
//                }
//            }
//            else
//            {
//                Console.WriteLine("MQTT客户端未连接，无法发送确认消息");
//            }
//        }
//    }
//}