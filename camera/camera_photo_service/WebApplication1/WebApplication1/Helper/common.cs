using PlyFileProcessor.Models;
using System.Diagnostics;
using System.Text;
using System.Text.Json;

namespace PlyFileProcessor.Helper
{
    public static class Common
    {
        // 运行Python脚本并返回状态码和消息
        public static(int statusCode, string message) RunPythonScript(string scriptPath, params string[] scriptArgs)
        {
            try
            {
                // 确保脚本路径有效
                if (!File.Exists(scriptPath))
                {
                    Console.WriteLine($"错误: 在{scriptPath}未找到Python脚本");
                    return (-1, "脚本文件不存在");
                }

                // 构建参数字符串
                StringBuilder argumentsBuilder = new StringBuilder(scriptPath);
                foreach (var arg in scriptArgs)
                {
                    // 为参数添加引号，处理包含空格的参数
                    // 如果参数中包含引号，需要进行转义
                    string escapedArg = arg.Replace("\"", "\\\"");
                    argumentsBuilder.Append($" \"{escapedArg}\"");
                }
                string arguments = argumentsBuilder.ToString();

                // 设置进程启动信息
                ProcessStartInfo start = new ProcessStartInfo
                {
                    FileName = "python", // 或"python3"，根据您的环境
                    Arguments = arguments,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true,
                    StandardOutputEncoding = Encoding.UTF8, // 确保正确处理UTF-8编码
                    StandardErrorEncoding = Encoding.UTF8
                };

                Console.WriteLine("-------- 执行信息 --------");
                Console.WriteLine($"执行命令: python {arguments}");

                // 启动进程
                using (Process process = Process.Start(start))
                {
                    // 读取标准输出和错误
                    string output = process.StandardOutput.ReadToEnd().Trim();
                    string error = process.StandardError.ReadToEnd().Trim();

                    // 等待进程结束
                    process.WaitForExit();
                    int exitCode = process.ExitCode;

                    // 输出错误信息（如果有）
                    if (!string.IsNullOrEmpty(error))
                    {
                        Console.WriteLine($"Python输出(stderr): {error}");
                    }

                    Console.WriteLine($"Python输出(stdout): {output}");
                    Console.WriteLine($"退出码: {exitCode}");

                    // 如果没有输出，返回空消息
                    if (string.IsNullOrEmpty(output))
                    {
                        return (exitCode, "");
                    }

                    try
                    {
                        // 尝试解析JSON输出
                        var options = new JsonSerializerOptions
                        {
                            PropertyNameCaseInsensitive = true // 允许大小写不敏感的属性名
                        };
                        var result = JsonSerializer.Deserialize<PythonResult>(output, options);
                        return (result.status_code, result.message);
                    }
                    catch (JsonException ex)
                    {
                        // 如果JSON解析失败，直接返回原始输出
                        Console.WriteLine($"警告: 无法解析JSON输出: {ex.Message}");
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
