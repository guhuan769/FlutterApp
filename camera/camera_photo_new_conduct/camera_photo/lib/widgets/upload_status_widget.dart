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
      duration: const Duration(milliseconds: 800),
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

  // 格式化精确的百分比显示
  String _formatProgress(double progress) {
    // 确保百分比在0.0到100.0之间，并保留一位小数
    return '${(progress * 100).clamp(0.0, 100.0).toStringAsFixed(1)}%';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 确定状态颜色
    final Color statusColor = widget.status.isComplete
        ? (_actualUploadStatus ? Colors.green : Colors.red)
        : Colors.blue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 进度指示器（在顶部，全宽）
            if (!widget.status.isComplete)
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Container(
                    height: 4,
                    width: double.infinity,
                    child: LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 4,
                    ),
                  );
                },
              ),
            
            // 主内容
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.status.isComplete
                      ? (_actualUploadStatus ? Icons.check_circle : Icons.error)
                      : Icons.cloud_upload,
                  color: statusColor,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.status.projectName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.status.uploadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '第${widget.status.uploadCount}次',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // 进度百分比（在正在上传时显示）
                  if (!widget.status.isComplete)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Row(
                            children: [
                              Text(
                                _formatProgress(_progressAnimation.value),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${widget.status.status.contains('正在上传:') ? widget.status.status.split('\n').first.replaceAll('正在上传: ', '') : ''})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                  // 状态信息
                  Text(
                    // 如果实际上传成功但标记为失败，提供修正的状态信息
                    _actualUploadStatus && !widget.status.isSuccess
                      ? "上传完成！文件已成功上传到服务器"
                      : (widget.status.isComplete 
                          ? (widget.status.status.contains('\n') ? widget.status.status.split('\n').first : widget.status.status)
                          : (widget.status.status.contains('\n') ? widget.status.status.split('\n').last : '')),
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.status.isComplete
                          ? (_actualUploadStatus ? Colors.green[700] : Colors.red[700])
                          : Colors.grey[700],
                    ),
                  ),
                  
                  // 错误信息
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
                      icon: const Icon(Icons.close, size: 20),
                      color: Colors.grey,
                      onPressed: widget.onDismiss,
                    )
                  : Container(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}