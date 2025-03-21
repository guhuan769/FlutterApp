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
            // 配置Serilog
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
                Log.Information("启动应用程序");
                var builder = WebApplication.CreateBuilder(args);

                // 将Serilog添加为日志提供程序
                builder.Host.UseSerilog();

                // 配置Kestrel服务器来监听所有网络接口
                builder.WebHost.ConfigureKestrel(serverOptions =>
                {
                    serverOptions.Listen(IPAddress.Any, 5000);
                });

                // 添加跨域支持
                builder.Services.AddCors(options =>
                {
                    options.AddPolicy("AllowAll", policy =>
                    {
                        policy.AllowAnyOrigin()
                              .AllowAnyMethod()
                              .AllowAnyHeader();
                    });
                });

                // 增加文件上传大小限制
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

                // 添加Swagger服务
                builder.Services.AddSwaggerGen(c =>
                {
                    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
                    {
                        Title = "PLY File Processor API",
                        Version = "v1",
                        Description = "用于图片上传和PLY文件处理的API",
                        Contact = new Microsoft.OpenApi.Models.OpenApiContact
                        {
                            Name = "开发团队"
                        }
                    });

                    // 启用XML文档注释
                    var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
                    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
                    if (File.Exists(xmlPath))
                    {
                        c.IncludeXmlComments(xmlPath);
                    }

                    // 启用Swagger注解
                    c.EnableAnnotations();
                });

                // 注册MQTT客户端服务
                builder.Services.AddSingleton<IMqttClientService, MqttClientService>();

                // 注册文件处理服务
                builder.Services.AddSingleton<IPlyFileService, PlyFileService>();

                var app = builder.Build();

                // 在生产环境中设置全局异常处理
                if (!app.Environment.IsDevelopment())
                {
                    app.UseExceptionHandler("/error");
                }

                // 启用Swagger
                app.UseSwagger();
                app.UseSwaggerUI(c =>
                {
                    c.SwaggerEndpoint("/swagger/v1/swagger.json", "PLY File Processor API V1");
                    c.RoutePrefix = "swagger";
                });

                // 启用CORS
                app.UseCors("AllowAll");

                // 禁用HTTPS重定向以允许HTTP访问
                // app.UseHttpsRedirection();

                app.UseAuthorization();

                // 日志中间件
                app.Use(async (context, next) =>
                {
                    Log.Information("接收到请求: {Method} {Path}", context.Request.Method, context.Request.Path);

                    // 记录客户端IP
                    var ipAddress = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
                    Log.Information("客户端IP: {IpAddress}", ipAddress);

                    await next();
                });

                app.MapControllers();

                // 启动MQTT客户端
                Log.Information("正在启动应用程序...");

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

                // 运行应用程序，绑定到所有网络接口上的5000端口
                Log.Information("Web服务启动于 http://0.0.0.0:5000");
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