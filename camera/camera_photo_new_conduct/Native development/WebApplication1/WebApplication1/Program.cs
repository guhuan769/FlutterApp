using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using System.Diagnostics;
using System.Collections.Concurrent;
using System.Net;
using PlyFileProcessor.Services;
using PlyFileProcessor.Services.Implementation;
using Serilog;
using Serilog.Events;
using Microsoft.AspNetCore.Http.Features;

namespace PlyFileProcessor
{
    public class Program
    {
        public static void Main(string[] args)
        {
            // 初始化Serilog
            Log.Logger = new LoggerConfiguration()
                .MinimumLevel.Information()
                .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
                .MinimumLevel.Override("Microsoft.Hosting.Lifetime", LogEventLevel.Information)
                .Enrich.FromLogContext()
                .Enrich.WithMachineName()
                .Enrich.WithEnvironmentName()
                .Enrich.WithProcessId()
                .Enrich.WithThreadId()
                .WriteTo.Console(outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}")
                .WriteTo.File(
                    path: "logs/app-.log",
                    rollingInterval: RollingInterval.Day,
                    outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}{NewLine}",
                    fileSizeLimitBytes: 10 * 1024 * 1024,
                    retainedFileCountLimit: 30)
                .CreateLogger();

            try
            {
                Log.Information("启动应用程序...");
                var builder = WebApplication.CreateBuilder(args);

                // 使用Serilog作为日志提供程序
                builder.Host.UseSerilog();

                // 配置Kestrel服务器以侦听传入的连接
                builder.WebHost.ConfigureKestrel(serverOptions =>
                {
                    serverOptions.Listen(IPAddress.Any, 5000);
                });

                // 添加CORS支持
                builder.Services.AddCors(options =>
                {
                    options.AddPolicy("AllowAll", policy =>
                    {
                        policy.AllowAnyOrigin()
                              .AllowAnyMethod()
                              .AllowAnyHeader();
                    });
                });

                // 添加CORS policy to allow Flutter app to access API
                builder.Services.AddCors(options =>
                {
                    options.AddPolicy("AllowFlutterApp", policy =>
                    {
                        policy.AllowAnyOrigin()
                              .AllowAnyMethod()
                              .AllowAnyHeader();
                    });
                });

                // 配置IIS服务器以限制请求体大小
                builder.Services.Configure<IISServerOptions>(options =>
                {
                    options.MaxRequestBodySize = 100 * 1024 * 1024; // 100MB
                });

                builder.Services.Configure<FormOptions>(options =>
                {
                    options.MultipartBodyLengthLimit = 100 * 1024 * 1024; // 100MB
                });

                // 添加控制器
                builder.Services.AddControllers();
                builder.Services.AddEndpointsApiExplorer();

                // 配置Swagger
                builder.Services.AddSwaggerGen(c =>
                {
                    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
                    {
                        Title = "PLY File Processor API",
                        Version = "v1",
                        Description = "上传PLY文件并处理API",
                        Contact = new Microsoft.OpenApi.Models.OpenApiContact
                        {
                            Name = "作者"
                        }
                    });

                    // 包含XML注释
                    var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
                    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
                    if (File.Exists(xmlPath))
                    {
                        c.IncludeXmlComments(xmlPath);
                    }

                    // 启用Swagger注释
                    c.EnableAnnotations();
                });

                // 注册MQTT客户端服务
                builder.Services.AddSingleton<IMqttClientService, MqttClientService>();

                // 注册文件处理服务
                builder.Services.AddSingleton<IPlyFileService, PlyFileService>();

                // 注册目录监控服务
                builder.Services.AddHostedService<DirectoryMonitorService>();

                // Configure upload folder from appsettings.json
                var uploadFolder = builder.Configuration.GetValue<string>("UploadFolder");
                if (string.IsNullOrEmpty(uploadFolder))
                {
                    uploadFolder = Path.Combine(Directory.GetCurrentDirectory(), "Uploads");
                    builder.Configuration["UploadFolder"] = uploadFolder;
                }

                // Ensure upload folder exists
                if (!Directory.Exists(uploadFolder))
                {
                    Directory.CreateDirectory(uploadFolder);
                }

                var app = builder.Build();

                // 配置应用程序以处理所有异常
                if (!app.Environment.IsDevelopment())
                {
                    app.UseExceptionHandler("/error");
                }

                // 配置Swagger
                app.UseSwagger();
                app.UseSwaggerUI(c =>
                {
                    c.SwaggerEndpoint("/swagger/v1/swagger.json", "PLY File Processor API V1");
                    c.RoutePrefix = "swagger";
                });

                // 配置CORS
                app.UseCors("AllowAll");

                // 配置HTTPS以重定向HTTP请求
                // app.UseHttpsRedirection();

                app.UseAuthorization();

                // 在日志中间件中记录请求
                app.Use(async (context, next) =>
                {
                    Log.Information("收到请求: {Method} {Path}", context.Request.Method, context.Request.Path);

                    // 记录客户端IP
                    var ipAddress = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
                    Log.Information("客户端IP: {IpAddress}", ipAddress);

                    await next();
                });

                app.MapControllers();

                // 启动MQTT客户端
                Log.Information("启动应用程序...");

                try
                {
                    var mqttClientService = app.Services.GetRequiredService<IMqttClientService>();
                    mqttClientService.StartAsync().GetAwaiter().GetResult();
                    Log.Information("MQTT客户端启动成功");
                }
                catch (Exception ex)
                {
                    Log.Error(ex, "MQTT客户端启动失败");
                }

                // 启动应用程序，监听传入的连接，默认情况下监听所有IPv4地址的5000端口
                Log.Information("Web应用程序 http://0.0.0.0:5000");
                app.Run("http://0.0.0.0:5000");
            }
            catch (Exception ex)
            {
                Log.Fatal(ex, "应用程序启动失败");
            }
            finally
            {
                Log.CloseAndFlush();
            }
        }
    }
}