using MQTTnet;
using MQTTnet.Client;
using MQTTnet.Protocol;
using System.Text;
using System.Text.Json;

namespace PLYProcessor
{
public class MqttPlyClient : IAsyncDisposable
{
private readonly IMqttClient _mqttClient;
private readonly string _brokerAddress;
private readonly int _brokerPort;
private readonly string _topic;
private readonly string _clientId;

public event EventHandler<PlyDataReceivedEventArgs>? PlyDataReceived;

public MqttPlyClient(string brokerAddress = "localhost", int brokerPort = 1883)
{
_brokerAddress = brokerAddress;
_brokerPort = brokerPort;
_topic = "ply/files";
_clientId = $"csharp-client-{Guid.NewGuid()}";

var factory = new MqttFactory();
_mqttClient = factory.CreateMqttClient();
}

public async Task ConnectAsync()
{
var options = new MqttClientOptionsBuilder()
    .WithTcpServer(_brokerAddress, _brokerPort)
    .WithProtocolVersion(MqttProtocolVersion.V500)
    .WithClientId(_clientId)
    .Build();

_mqttClient.ApplicationMessageReceivedAsync += HandleMessageReceived;

await _mqttClient.ConnectAsync(options);
await SubscribeToTopics();
}

private async Task SubscribeToTopics()
{
var topicFilter = new MqttTopicFilterBuilder()
    .WithTopic(_topic)
    .WithQualityOfServiceLevel(MqttQualityOfServiceLevel.ExactlyOnce)
    .Build();

await _mqttClient.SubscribeAsync(topicFilter);
}

private async Task HandleMessageReceived(MqttApplicationMessageReceivedEventArgs args)
{
try
{
var payload = Encoding.UTF8.GetString(args.ApplicationMessage.PayloadSegment);
var message = JsonSerializer.Deserialize<PlyMessage>(payload);

if (message == null) return;

switch (message.Type?.ToLower())
{
case "ply_data" when !string.IsNullOrEmpty(message.FileData):
await ProcessPlyData(message);
break;

case "ply_data" when message.ProjectInfo?.Status == "no_ply_files":
Console.WriteLine($"No PLY files found for project {message.ProjectId}");
break;
}

// Send acknowledgment
await SendAcknowledgment(message.ProjectId);
}
catch (Exception ex)
{
Console.WriteLine($"Error processing message: {ex.Message}");
}
}

private async Task ProcessPlyData(PlyMessage message)
{
try
{
var fileData = Convert.FromBase64String(message.FileData!);

// Create output directory
var outputDir = Path.Combine(
AppDomain.CurrentDomain.BaseDirectory,
"received_files",
message.ProjectId ?? "unknown_project"
);
Directory.CreateDirectory(outputDir);

// Save the zip file
var zipPath = Path.Combine(outputDir, message.FileName ?? $"{DateTime.Now:yyyyMMddHHmmss}.zip");
await File.WriteAllBytesAsync(zipPath, fileData);

// Extract the zip file
var extractPath = Path.Combine(outputDir, "extracted");
Directory.CreateDirectory(extractPath);
System.IO.Compression.ZipFile.ExtractToDirectory(zipPath, extractPath, overwriteFiles: true);

// Raise event
PlyDataReceived?.Invoke(this, new PlyDataReceivedEventArgs(
message.ProjectId!,
zipPath,
extractPath,
message.ProjectInfo
));
}
catch (Exception ex)
{
Console.WriteLine($"Error processing PLY data: {ex.Message}");
}
}

private async Task SendAcknowledgment(string? projectId)
{
if (string.IsNullOrEmpty(projectId)) return;

var ackMessage = new
{
type = "ack",
projectId = projectId,
timestamp = DateTime.UtcNow,
clientId = _clientId
};

var message = new MqttApplicationMessageBuilder()
    .WithTopic($"{_topic}/ack/{projectId}")
    .WithPayload(JsonSerializer.Serialize(ackMessage))
    .WithQualityOfServiceLevel(MqttQualityOfServiceLevel.AtLeastOnce)
    .WithRetainFlag(false)
    .Build();

await _mqttClient.PublishAsync(message);
}

public async ValueTask DisposeAsync()
{
if (_mqttClient.IsConnected)
{
await _mqttClient.DisconnectAsync();
}
await _mqttClient.DisposeAsync();
}
}

public class PlyDataReceivedEventArgs : EventArgs
{
public string ProjectId { get; }
public string ZipPath { get; }
public string ExtractPath { get; }
public Dictionary<string, object>? ProjectInfo { get; }

public PlyDataReceivedEventArgs(
string projectId,
string zipPath,
string extractPath,
Dictionary<string, object>? projectInfo)
{
ProjectId = projectId;
ZipPath = zipPath;
ExtractPath = extractPath;
ProjectInfo = projectInfo;
}
}

public class PlyMessage
{
public string? Type { get; set; }
public string? ProjectId { get; set; }
public string? FileName { get; set; }
public string? FileData { get; set; }
public string? Timestamp { get; set; }
public Dictionary<string, object>? ProjectInfo { get; set; }
}

// Example usage
public class Program
{
public static async Task Main(string[] args)
{
var client = new MqttPlyClient();
client.PlyDataReceived += (sender, e) =>
{
Console.WriteLine($"Received PLY data for project {e.ProjectId}");
Console.WriteLine($"Files extracted to: {e.ExtractPath}");
};

await client.ConnectAsync();
Console.WriteLine("Connected to MQTT broker. Press any key to exit.");
Console.ReadKey();
await client.DisposeAsync();
}
}
}