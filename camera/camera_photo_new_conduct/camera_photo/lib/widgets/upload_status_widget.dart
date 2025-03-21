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
            ? (widget.status.isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1))
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
              widget.status.status,
              style: TextStyle(
                fontSize: 12,
                color: widget.status.isComplete
                    ? (widget.status.isSuccess ? Colors.green[700] : Colors.red[700])
                    : Colors.grey[700],
              ),
            ),
            _buildErrorInfo(),
          ],
        ),
        trailing: widget.status.isComplete
            ? SizedBox(
                width: 120,
                child: _buildCompletionStatus(),
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

  Widget _buildErrorInfo() {
    if (!widget.status.isSuccess && widget.status.error != null) {
      String errorMessage = '上传失败';
      
      final errorString = widget.status.error!;
      if (errorString.contains('网络连接不可用')) {
        errorMessage = '网络连接不可用，请检查网络设置';
      } else if (errorString.contains('服务器连接超时')) {
        errorMessage = '服务器连接超时，请检查服务器地址';
      } else if (errorString.contains('无法连接到服务器')) {
        errorMessage = '无法连接到服务器，请检查网络设置';
      } else if (errorString.contains('请先在设置中配置服务器地址')) {
        errorMessage = '请先在设置中配置服务器地址';
      } else if (errorString.contains('没有可上传的文件')) {
        errorMessage = '没有可上传的文件，请确保项目中包含照片';
      } else if (errorString.length > 100) {
        errorMessage = '${errorString.substring(0, 100)}...';
      } else {
        errorMessage = errorString;
      }
      
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '上传失败',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 4),
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 4),
              child: Text(
                '请检查网络和服务器设置后重试',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCompletionStatus() {
    if (widget.status.isComplete) {
      if (widget.status.isSuccess) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '上传完成',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (widget.status.hasPlyFiles) 
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 22),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'PLY文件生成成功',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            if (!widget.status.hasPlyFiles)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 22),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.orange,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'PLY文件生成失败',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      } else {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error,
              color: Colors.red,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '上传失败',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        );
      }
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: widget.status.progress > 0 ? widget.status.progress : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '上传中 ${(widget.status.progress * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}