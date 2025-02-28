using System;
using System.Diagnostics;
using System.IO;
using System.Text.Json; // 需要.NET Core 3.0+或安装System.Text.Json包

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
            // 调用Python脚本并获取结果
            (int statusCode, string resultMessage) = RunPythonScript("main.py");

            // 输出结果
            Console.WriteLine($"状态码: {statusCode}");
            Console.WriteLine($"消息: {resultMessage}");

            // 根据状态码判断成功或失败
            if (statusCode == 1)
                Console.WriteLine("操作成功!");
            else if (statusCode == 2)
                Console.WriteLine("操作失败!");

            Console.WriteLine("按任意键退出...");
            Console.ReadKey();
        }

        // 运行Python脚本并返回状态码和消息
        static (int statusCode, string message) RunPythonScript(string scriptPath)
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