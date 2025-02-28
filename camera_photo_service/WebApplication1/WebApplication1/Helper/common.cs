using PlyFileProcessor.Models;
using System.Diagnostics;
using System.Text.Json;

namespace PlyFileProcessor.Helper
{
    public static class Common
    {
        // 运行Python脚本并返回状态码和消息
        public static (int statusCode, string message) RunPythonScript(string scriptPath)
        {
            try
            {
                // 确保脚本路径有效
                if (!File.Exists(scriptPath))
                {
                    Console.WriteLine($"错误: 在{scriptPath}未找到Python脚本");
                    return (-1, "脚本文件不存在");
                }

                // 设置进程启动信息
                ProcessStartInfo start = new ProcessStartInfo
                {
                    FileName = "python", // 或"python3"，根据您的环境
                    Arguments = scriptPath,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true, // 也重定向标准错误
                    CreateNoWindow = true
                };

                // 启动进程
                using (Process process = Process.Start(start))
                {
                    // 读取标准输出
                    string output = process.StandardOutput.ReadToEnd().Trim();
                    // 读取标准错误（如果有）
                    string error = process.StandardError.ReadToEnd().Trim();

                    // 等待进程结束
                    process.WaitForExit();
                    int exitCode = process.ExitCode;

                    // 检查是否有错误输出
                    if (!string.IsNullOrEmpty(error))
                    {
                        Console.WriteLine($"Python错误输出: {error}");
                        return (exitCode, error);
                    }

                    // 如果没有输出，返回空消息
                    if (string.IsNullOrEmpty(output))
                    {
                        return (exitCode, "");
                    }

                    try
                    {
                        // 尝试解析JSON输出
                        var result = JsonSerializer.Deserialize<PythonResult>(output);
                        return (result.status_code, result.message);
                    }
                    catch (JsonException)
                    {
                        // 如果JSON解析失败，直接返回原始输出
                        Console.WriteLine($"警告: 无法解析JSON输出: {output}");
                        return (exitCode, output);
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"执行Python脚本时出错: {ex.Message}");
                return (-1, ex.Message);
            }
        }
    }
}
