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
            // ����Serilog
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
                Log.Information("����Ӧ�ó���");
                var builder = WebApplication.CreateBuilder(args);

                // ��Serilog���Ϊ��־�ṩ����
                builder.Host.UseSerilog();

                // ����Kestrel��������������������ӿ�
                builder.WebHost.ConfigureKestrel(serverOptions =>
                {
                    serverOptions.Listen(IPAddress.Any, 5000);
                });

                // ��ӿ���֧��
                builder.Services.AddCors(options =>
                {
                    options.AddPolicy("AllowAll", policy =>
                    {
                        policy.AllowAnyOrigin()
                              .AllowAnyMethod()
                              .AllowAnyHeader();
                    });
                });

                // �����ļ��ϴ���С����
                builder.Services.Configure<IISServerOptions>(options =>
                {
                    options.MaxRequestBodySize = 100 * 1024 * 1024; // 100MB
                });

                builder.Services.Configure<FormOptions>(options =>
                {
                    options.MultipartBodyLengthLimit = 100 * 1024 * 1024; // 100MB
                });

                // ��ӿ�����
                builder.Services.AddControllers();
                builder.Services.AddEndpointsApiExplorer();

                // ���Swagger����
                builder.Services.AddSwaggerGen(c =>
                {
                    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
                    {
                        Title = "PLY File Processor API",
                        Version = "v1",
                        Description = "����ͼƬ�ϴ���PLY�ļ������API",
                        Contact = new Microsoft.OpenApi.Models.OpenApiContact
                        {
                            Name = "�����Ŷ�"
                        }
                    });

                    // ����XML�ĵ�ע��
                    var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
                    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
                    if (File.Exists(xmlPath))
                    {
                        c.IncludeXmlComments(xmlPath);
                    }

                    // ����Swaggerע��
                    c.EnableAnnotations();
                });

                // ע��MQTT�ͻ��˷���
                builder.Services.AddSingleton<IMqttClientService, MqttClientService>();

                // ע���ļ��������
                builder.Services.AddSingleton<IPlyFileService, PlyFileService>();

                var app = builder.Build();

                // ����������������ȫ���쳣����
                if (!app.Environment.IsDevelopment())
                {
                    app.UseExceptionHandler("/error");
                }

                // ����Swagger
                app.UseSwagger();
                app.UseSwaggerUI(c =>
                {
                    c.SwaggerEndpoint("/swagger/v1/swagger.json", "PLY File Processor API V1");
                    c.RoutePrefix = "swagger";
                });

                // ����CORS
                app.UseCors("AllowAll");

                // ����HTTPS�ض���������HTTP����
                // app.UseHttpsRedirection();

                app.UseAuthorization();

                // ��־�м��
                app.Use(async (context, next) =>
                {
                    Log.Information("���յ�����: {Method} {Path}", context.Request.Method, context.Request.Path);

                    // ��¼�ͻ���IP
                    var ipAddress = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
                    Log.Information("�ͻ���IP: {IpAddress}", ipAddress);

                    await next();
                });

                app.MapControllers();

                // ����MQTT�ͻ���
                Log.Information("��������Ӧ�ó���...");

                try
                {
                    var mqttClientService = app.Services.GetRequiredService<IMqttClientService>();
                    mqttClientService.StartAsync().GetAwaiter().GetResult();
                    Log.Information("MQTT�ͻ��������ɹ�");
                }
                catch (Exception ex)
                {
                    Log.Error(ex, "MQTT�ͻ�������ʧ��");
                }

                // ����Ӧ�ó��򣬰󶨵���������ӿ��ϵ�5000�˿�
                Log.Information("Web���������� http://0.0.0.0:5000");
                app.Run("http://0.0.0.0:5000");
            }
            catch (Exception ex)
            {
                Log.Fatal(ex, "Ӧ�ó�������ʧ��");
            }
            finally
            {
                Log.CloseAndFlush();
            }
        }
    }
}