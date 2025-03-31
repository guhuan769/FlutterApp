using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;

namespace PlyFileProcessor.Services
{
    public class DirectoryMonitorService : IHostedService, IDisposable
    {
        private readonly ILogger<DirectoryMonitorService> _logger;
        private readonly string _uploadFolder;
        private Timer _timer;
        private readonly TimeSpan _checkInterval = TimeSpan.FromMinutes(5);
        private readonly double _minDiskSpaceGB = 1.0; // 最小磁盘空间阈值（GB）

        public DirectoryMonitorService(ILogger<DirectoryMonitorService> logger, IConfiguration configuration)
        {
            _logger = logger;
            _uploadFolder = configuration.GetValue<string>("UploadFolder") ?? "uploaded_images";
            
            // 可以通过配置自定义检查间隔
            var configInterval = configuration.GetValue<int>("DirectoryMonitor:CheckIntervalMinutes");
            if (configInterval > 0)
            {
                _checkInterval = TimeSpan.FromMinutes(configInterval);
            }
            
            // 可以通过配置自定义磁盘空间阈值
            var configMinSpace = configuration.GetValue<double>("DirectoryMonitor:MinDiskSpaceGB");
            if (configMinSpace > 0)
            {
                _minDiskSpaceGB = configMinSpace;
            }
        }

        public Task StartAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("目录监控服务启动，检查间隔: {CheckInterval}分钟，磁盘空间阈值: {MinDiskSpaceGB}GB", 
                _checkInterval.TotalMinutes, _minDiskSpaceGB);
            
            // 立即执行一次检查，然后定期执行
            _timer = new Timer(DoCheck, null, TimeSpan.Zero, _checkInterval);
            
            return Task.CompletedTask;
        }

        private void DoCheck(object state)
        {
            try
            {
                _logger.LogDebug("开始目录和磁盘空间检查");
                
                // 检查上传根目录
                CheckDirectoryExistence(_uploadFolder);
                
                // 检查磁盘空间
                CheckDiskSpace(_uploadFolder);
                
                // 检查子目录（模型和工艺）
                var modelDir = Path.Combine(_uploadFolder, "模型");
                var processDir = Path.Combine(_uploadFolder, "工艺");
                
                CheckDirectoryExistence(modelDir);
                CheckDirectoryExistence(processDir);
                
                _logger.LogDebug("目录和磁盘空间检查完成");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "目录监控检查过程中发生错误");
            }
        }
        
        private void CheckDirectoryExistence(string directory)
        {
            try
            {
                if (!Directory.Exists(directory))
                {
                    _logger.LogWarning("目录不存在，正在重新创建: {Directory}", directory);
                    Directory.CreateDirectory(directory);
                    _logger.LogInformation("已重新创建目录: {Directory}", directory);
                    
                    // 测试目录权限
                    var testFile = Path.Combine(directory, "monitor_test.txt");
                    File.WriteAllText(testFile, "监控服务测试文件，可以删除");
                    File.Delete(testFile);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "检查或创建目录失败: {Directory}", directory);
                // 发送关键错误通知 - 可以在这里添加邮件或其他通知机制
            }
        }
        
        private void CheckDiskSpace(string directory)
        {
            try
            {
                var rootPath = Path.GetPathRoot(Path.GetFullPath(directory));
                var drive = new DriveInfo(rootPath);
                
                var totalSpaceGB = drive.TotalSize / (1024.0 * 1024 * 1024);
                var freeSpaceGB = drive.AvailableFreeSpace / (1024.0 * 1024 * 1024);
                var usedPercentage = 100 - (freeSpaceGB / totalSpaceGB * 100);
                
                _logger.LogInformation(
                    "磁盘空间检查 - 驱动器: {Drive}, 总空间: {TotalSpace:F2}GB, 可用空间: {FreeSpace:F2}GB, 使用率: {UsedPercentage:F1}%", 
                    rootPath, totalSpaceGB, freeSpaceGB, usedPercentage);
                
                if (freeSpaceGB < _minDiskSpaceGB)
                {
                    _logger.LogError(
                        "磁盘空间不足! 驱动器: {Drive}, 可用空间: {FreeSpace:F2}GB, 最小阈值: {MinSpace}GB", 
                        rootPath, freeSpaceGB, _minDiskSpaceGB);
                    
                    // 发送关键错误通知 - 可以在这里添加邮件或其他通知机制
                }
                else if (freeSpaceGB < _minDiskSpaceGB * 2)
                {
                    _logger.LogWarning(
                        "磁盘空间偏低! 驱动器: {Drive}, 可用空间: {FreeSpace:F2}GB, 警告阈值: {WarnSpace}GB", 
                        rootPath, freeSpaceGB, _minDiskSpaceGB * 2);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "检查磁盘空间时发生错误");
            }
        }

        public Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("目录监控服务停止");
            _timer?.Change(Timeout.Infinite, 0);
            return Task.CompletedTask;
        }

        public void Dispose()
        {
            _timer?.Dispose();
        }
    }
} 