using System;
using System.Diagnostics;
using System.IO;
using System.Text.Json; // 需要.NET Core 3.0+或安装System.Text.Json包
using System.Text;

namespace PythonScriptRunner
{
    class Program
    {
        // 定义结果类，用于解析Python返回的JSON
        class PythonResult
        {
            public int status_code { get; set; }
            public string message { get; set; }
        }

        static void Main(string[] args)
        {
            // 定义要传递给Python脚本的参数
            string param1 = "success"; // 尝试将此改为其他值以测试失败情况
            string param2 = "测试参数";

            // 调用Python脚本并传递参数
            (int statusCode, string resultMessage) = RunPythonScript("main.py", param1, param2);

            // 输出结果
            Console.WriteLine("-------- 执行结果 --------");
            Console.WriteLine($"状态码: {statusCode}");
            Console.WriteLine($"消息: {resultMessage}");

            // 根据状态码判断成功或失败
            if (statusCode == 1)
                Console.WriteLine("结论: 操作成功!");
            else if (statusCode == 2)
                Console.WriteLine("结论: 操作失败!");
            else
                Console.WriteLine("结论: 未知状态!");

            Console.WriteLine("\n按任意键退出...");
            Console.ReadKey();
        }

        // 运行Python脚本并传递参数
        static (int statusCode, string message) RunPythonScript(string scriptPath, params string[] scriptArgs)
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