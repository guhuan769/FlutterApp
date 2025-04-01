using Microsoft.OpenApi.Models;
using Microsoft.Extensions.FileProviders;
using System.IO;

var builder = WebApplication.CreateBuilder(args);

// 添加控制器和API Explorer
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// 简化的Swagger配置
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "照片上传API", Version = "v1" });
});

// 跨域配置
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// 始终启用Swagger
app.UseSwagger();
app.UseSwaggerUI();

// 启用跨域
app.UseCors("AllowAll");

// 配置静态文件
app.UseStaticFiles();

// 配置上传目录
var uploadPath = Path.Combine(app.Environment.ContentRootPath, "Uploads");
if (!Directory.Exists(uploadPath))
{
    Directory.CreateDirectory(uploadPath);
}

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(uploadPath),
    RequestPath = "/uploads"
});

// 基本中间件
app.UseAuthorization();
app.MapControllers();

// 启动应用(指定使用端口5000)
app.Run("http://0.0.0.0:5000");
