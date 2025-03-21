using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace PlyFileProcessor.Models
{
    /// <summary>
    /// 通用API响应
    /// </summary>
    public class ApiResponse
    {
        /// <summary>
        /// 响应代码
        /// </summary>
        [JsonPropertyName("code")]
        public int Code { get; set; }

        /// <summary>
        /// 响应消息
        /// </summary>
        [JsonPropertyName("message")]
        public string Message { get; set; }

        /// <summary>
        /// 创建成功响应
        /// </summary>
        /// <param name="message">成功消息</param>
        /// <returns>API响应对象</returns>
        public static ApiResponse Success(string message = "操作成功")
        {
            return new ApiResponse { Code = 200, Message = message };
        }

        /// <summary>
        /// 创建错误响应
        /// </summary>
        /// <param name="message">错误消息</param>
        /// <param name="code">错误代码</param>
        /// <returns>API响应对象</returns>
        public static ApiResponse Error(string message, int code = 500)
        {
            return new ApiResponse { Code = code, Message = message };
        }
    }

    /// <summary>
    /// 上传响应
    /// </summary>
    public class UploadResponse : ApiResponse
    {
        /// <summary>
        /// 任务ID
        /// </summary>
        [JsonPropertyName("task_id")]
        public string TaskId { get; set; }

        /// <summary>
        /// 保存的文件数量
        /// </summary>
        [JsonPropertyName("saved_files")]
        public int SavedFiles { get; set; }

        /// <summary>
        /// 是否找到PLY文件
        /// </summary>
        [JsonPropertyName("ply_files_found")]
        public bool PlyFilesFound { get; set; }
    }

    /// <summary>
    /// 服务器状态响应
    /// </summary>
    public class StatusResponse
    {
        /// <summary>
        /// 服务器状态
        /// </summary>
        [JsonPropertyName("status")]
        public string Status { get; set; }

        /// <summary>
        /// 时间戳
        /// </summary>
        [JsonPropertyName("timestamp")]
        public string Timestamp { get; set; }

        /// <summary>
        /// MQTT连接状态
        /// </summary>
        [JsonPropertyName("mqtt_connected")]
        public bool MqttConnected { get; set; }

        /// <summary>
        /// 工作线程数
        /// </summary>
        [JsonPropertyName("worker_threads")]
        public int WorkerThreads { get; set; }

        /// <summary>
        /// PLY观察目录
        /// </summary>
        [JsonPropertyName("ply_watch_dir")]
        public string PlyWatchDir { get; set; }

        /// <summary>
        /// 服务器IP地址
        /// </summary>
        [JsonPropertyName("server_ip")]
        public string ServerIp { get; set; }

        /// <summary>
        /// 上传文件夹
        /// </summary>
        [JsonPropertyName("upload_folder")]
        public string UploadFolder { get; set; }

        /// <summary>
        /// .NET版本
        /// </summary>
        [JsonPropertyName("dotnet_version")]
        public string DotnetVersion { get; set; }

        /// <summary>
        /// 操作系统版本
        /// </summary>
        [JsonPropertyName("os_version")]
        public string OsVersion { get; set; }

        /// <summary>
        /// MQTT客户端信息
        /// </summary>
        [JsonPropertyName("mqtt_info")]
        public MqttInfo MqttInfo { get; set; }
    }

    /// <summary>
    /// MQTT信息
    /// </summary>
    public class MqttInfo
    {
        /// <summary>
        /// 代理地址
        /// </summary>
        [JsonPropertyName("broker")]
        public string Broker { get; set; }

        /// <summary>
        /// 客户端ID
        /// </summary>
        [JsonPropertyName("client_id")]
        public string ClientId { get; set; }

        /// <summary>
        /// 主题
        /// </summary>
        [JsonPropertyName("topic")]
        public string Topic { get; set; }
    }

    /// <summary>
    /// 文件信息
    /// </summary>
    public class FileInfo
    {
        /// <summary>
        /// 文件类型
        /// </summary>
        [JsonPropertyName("type")]
        public string Type { get; set; }

        /// <summary>
        /// 轨道名称（针对轨道类型）
        /// </summary>
        [JsonPropertyName("trackName")]
        public string TrackName { get; set; }

        /// <summary>
        /// 相对路径
        /// </summary>
        [JsonPropertyName("relativePath")]
        public string RelativePath { get; set; }
    }

    /// <summary>
    /// 项目信息
    /// </summary>
    public class ProjectInfo
    {
        /// <summary>
        /// 项目名称
        /// </summary>
        [JsonPropertyName("name")]
        public string Name { get; set; }
    }
}