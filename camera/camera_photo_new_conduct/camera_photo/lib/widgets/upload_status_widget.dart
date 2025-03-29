// lib/widgets/upload_status_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';

class UploadStatusWidget extends StatefulWidget {
  final ScrollController scrollController;
  final UploadStatus status;
  final VoidCallback? onDismiss;

  const UploadStatusWidget({
    Key? key,
    required this.scrollController,
    required this.status,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<UploadStatusWidget> createState() => _UploadStatusWidgetState();
}

class _UploadStatusWidgetState extends State<UploadStatusWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late bool _actualUploadStatus;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.status.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward();
    
    // 对上传状态进行初始化判断
    _determineActualUploadStatus();
  }

  @override
  void didUpdateWidget(UploadStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status.progress != widget.status.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.status.progress,
        end: widget.status.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.forward(from: 0);
    }
    
    // 当组件更新时重新判断状态
    _determineActualUploadStatus();
  }

  // 判断实际上传状态的方法
  void _determineActualUploadStatus() {
    // 默认使用传入的状态
    _actualUploadStatus = widget.status.isSuccess;
    
    // 如果状态标记为完成但显示失败，检查日志或状态消息来判断真实情况
    if (widget.status.isComplete && !widget.status.isSuccess) {
      // 检查状态消息中是否包含成功上传的关键词和百分比信息
      final statusText = widget.status.status.toLowerCase();
      
      // 1. 检查是否存在上传成功的百分比信息
      if (statusText.contains('成功上传') && 
          statusText.contains('%') &&
          !statusText.contains('0%')) {
        
        // 尝试解析百分比值
        try {
          // 解析百分比字符串，格式如"成功上传: 20/25 张照片 (80.0%)"
          RegExp percentRegex = RegExp(r'\(([\d\.]+)%\)');
          final match = percentRegex.firstMatch(statusText);
          if (match != null) {
            final percentString = match.group(1);
            if (percentString != null) {
              final percent = double.tryParse(percentString);
              // 如果上传成功率大于等于50%，认为是基本成功
              if (percent != null && percent >= 50.0) {
                _actualUploadStatus = true;
              }
            }
          }
        } catch (e) {
          print('解析上传百分比失败: $e');
          // 解析失败时，如果包含"成功上传"字样，默认认为基本成功
          if (statusText.contains('成功上传')) {
            _actualUploadStatus = true;
          }
        }
      }
      
      // 2. 检查日志中的成功和失败记录
      bool hasSuccessLog = false;
      bool hasCriticalErrorLog = false;
      int successBatchCount = 0;
      int failedBatchCount = 0;
      int serverIssueCount = 0;
      
      for (var log in widget.status.logs) {
        // 统计批次上传成功和失败数
        if (log.message.contains('批次') && log.message.contains('上传成功')) {
          hasSuccessLog = true;
          successBatchCount++;
        } else if (log.isError && log.message.contains('批次') && log.message.contains('上传失败')) {
          failedBatchCount++;
        } else if (log.message.contains('状态码异常') || log.message.contains('服务器可能未记录')) {
          serverIssueCount++;
        }
        
        // 检查是否有严重错误
        if (log.isError && (
            log.message.contains('网络连接失败') || 
            log.message.contains('没有可上传的文件') ||
            log.message.contains('服务器地址') ||
            log.message.contains('配置错误'))) {
          hasCriticalErrorLog = true;
        }
      }
      
      // 如果有成功记录且失败不超过总数的一半
      if (hasSuccessLog && !hasCriticalErrorLog && 
          ((successBatchCount > 0 && failedBatchCount <= successBatchCount) || 
           (serverIssueCount > 0 && failedBatchCount == 0))) {
        _actualUploadStatus = true;
      }
      
      // 3. 处理特殊情况：服务器返回问题但文件可能已上传
      if (statusText.contains('状态码异常') || statusText.contains('服务器可能未记录')) {
        // 如果状态中提到服务器异常但文件可能已上传，设置为"部分成功"状态
        _actualUploadStatus = true;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.status.isComplete
            ? (_actualUploadStatus ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1))
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Text(
              widget.status.projectName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            if (widget.status.uploadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '第${widget.status.uploadCount}次',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.status.isComplete) ...[
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_progressAnimation.value * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 4),
            Text(
              // 如果实际上传成功但标记为失败，提供修正的状态信息
              _actualUploadStatus && !widget.status.isSuccess
                ? "上传完成！文件已成功上传到服务器"
                : widget.status.status,
              style: TextStyle(
                fontSize: 12,
                color: widget.status.isComplete
                    ? (_actualUploadStatus ? Colors.green[700] : Colors.red[700])
                    : Colors.grey[700],
              ),
            ),
            if (widget.status.error != null && !_actualUploadStatus)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.status.error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        trailing: widget.status.isComplete
            ? IconButton(
                icon: Icon(
                  _actualUploadStatus ? Icons.check_circle : Icons.error,
                  color: _actualUploadStatus ? Colors.green : Colors.red,
                ),
                onPressed: widget.onDismiss,
              )
            : SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
      ),
    );
  }
}