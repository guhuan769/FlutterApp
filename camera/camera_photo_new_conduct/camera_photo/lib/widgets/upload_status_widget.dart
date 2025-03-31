// lib/widgets/upload_status_widget.dart
import 'package:flutter/material.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';

class UploadStatusWidget extends StatelessWidget {
  final UploadStatus status;
  final Function? onDismiss;
  final ScrollController scrollController;

  const UploadStatusWidget({
    Key? key,
    required this.status,
    required this.scrollController,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 格式化上传开始时间
    final timeString = _formatUploadTime(status.uploadTime);
    
    // 上传状态的颜色
    final Color statusColor = status.isComplete
        ? (status.isSuccess ? Colors.green : Colors.red)
        : Colors.blue;

    // 上传状态图标
    final IconData statusIcon = status.isComplete
        ? (status.isSuccess ? Icons.check_circle : Icons.error)
        : Icons.cloud_upload;

    return Dismissible(
      key: Key('upload-${status.projectId}-${status.uploadTime.millisecondsSinceEpoch}'),
      direction: onDismiss != null ? DismissDirection.horizontal : DismissDirection.none,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: status.isComplete
                ? (status.isSuccess ? Colors.green.shade100 : Colors.red.shade100)
                : Colors.blue.shade100,
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // 显示详细日志
            _showUploadDetails(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.projectName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            timeString,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onDismiss != null && status.isComplete)
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => onDismiss?.call(),
                        tooltip: '关闭',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        color: Colors.grey[400],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!status.isComplete) ...[
                  LinearProgressIndicator(
                    value: status.progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(height: 8),
                  // 显示百分比和详细进度
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          status.status.split('\n').first,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${(status.progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  // 显示当前处理的文件名（如果状态中包含）
                  if (status.status.contains('\n')) ...[
                    const SizedBox(height: 4),
                    Text(
                      status.status.split('\n').last,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ] else ...[
                  // 已完成上传的状态显示
                  Text(
                    status.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                    ),
                  ),
                  if (status.isSuccess && status.hasPlyFiles) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'PLY文件已生成',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 显示详细日志
  void _showUploadDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => UploadLogDetail(
          status: status,
          scrollController: scrollController,
        ),
      ),
    );
  }

  // 格式化上传时间
  String _formatUploadTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}

// 上传日志详情组件
class UploadLogDetail extends StatelessWidget {
  final UploadStatus status;
  final ScrollController scrollController;

  const UploadLogDetail({
    Key? key,
    required this.status,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logs = status.logs.reversed.toList(); // 最新的日志显示在顶部
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖动条
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 标题和基本信息
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.folder, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        status.projectName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '上传日志 (${logs.length})',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.isComplete 
                    ? (status.isSuccess ? '上传已完成' : '上传失败') 
                    : '上传中...',
                  style: TextStyle(
                    color: status.isComplete
                        ? (status.isSuccess ? Colors.green : Colors.red)
                        : Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!status.isComplete) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: status.progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '进度: ${(status.progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(height: 1),
              ],
            ),
          ),
          // 日志列表
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Text(
                      '暂无日志',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return LogItem(log: log);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// 日志项组件
class LogItem extends StatelessWidget {
  final UploadLog log;

  const LogItem({Key? key, required this.log}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeString = _formatLogTime(log.timestamp);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: log.isError ? Colors.red : Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.message,
                  style: TextStyle(
                    color: log.isError ? Colors.red : Colors.black87,
                    fontWeight: log.isError ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeString,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 格式化日志时间
  String _formatLogTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}