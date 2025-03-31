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
    
    // 判断显示状态类型
    bool isPartialSuccess = false;
    if (status.isComplete && status.isSuccess) {
      // 检查状态消息，判断是否是部分成功
      isPartialSuccess = status.status.contains('部分上传完成');
    }
    
    // 上传状态的颜色
    final Color statusColor = status.isComplete
        ? (status.isSuccess 
            ? (isPartialSuccess ? Colors.orange : Colors.green) 
            : Colors.red)
        : Colors.blue;

    // 上传状态图标
    final IconData statusIcon = status.isComplete
        ? (status.isSuccess 
            ? (isPartialSuccess ? Icons.warning : Icons.check_circle) 
            : Icons.error)
        : Icons.cloud_upload;

    // 统计错误类型和成功数量
    int errorCount = 0;
    int successCount = 0;
    
    if (status.logs.isNotEmpty) {
      for (var log in status.logs) {
        if (log.isError) {
          errorCount++;
        } else if (log.message.contains('上传成功:')) {
          successCount++;
        }
      }
    }

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
                ? (status.isSuccess 
                    ? (isPartialSuccess ? Colors.orange.shade100 : Colors.green.shade100)
                    : Colors.red.shade100)
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
                  // 上传进行中的状态
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
                  // 将状态信息分行显示，更清晰
                  if (status.status.contains('\n')) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: status.status.split('\n').map((line) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            line,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 13,
                              fontWeight: line.contains('成功上传:') ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    Text(
                      status.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  
                  // 显示上传统计信息 - 新增
                  if (isPartialSuccess && status.logs.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Text(
                      '上传详情统计',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '成功: $successCount 个文件',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.error, color: Colors.red, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '失败: $errorCount 个错误',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // 服务器确认数量检查
                    _buildServerConfirmationSummary(status),
                    
                    // 常见错误类型统计
                    _buildCommonErrorSummary(status),
                  ],
                  
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

  // 新增：构建服务器确认总结组件
  Widget _buildServerConfirmationSummary(UploadStatus status) {
    int localSuccessCount = 0;
    int serverConfirmedCount = 0;
    bool serverMismatchFound = false;
    
    // 解析日志查找相关信息
    for (var log in status.logs) {
      String message = log.message;
      // 本地上传成功计数
      if (message.contains("成功: ") && message.contains(", 失败: ")) {
        try {
          final parts = message.split(", ");
          if (parts.length >= 1 && parts[0].contains("成功: ")) {
            final countStr = parts[0].split("成功: ")[1].trim();
            localSuccessCount = int.tryParse(countStr) ?? 0;
          }
        } catch (e) {
          // 解析失败，忽略
        }
      }
      // 查找本地与服务器计数不匹配警告
      else if (message.contains("本地成功上传计数: ") && message.contains("服务器确认计数: ")) {
        serverMismatchFound = true;
        try {
          final parts = message.split(", ");
          if (parts.length >= 2) {
            final localPart = parts[0].split("本地成功上传计数: ")[1].trim();
            final serverPart = parts[1].split("服务器确认计数: ")[1].trim();
            localSuccessCount = int.tryParse(localPart) ?? 0;
            serverConfirmedCount = int.tryParse(serverPart) ?? 0;
          }
        } catch (e) {
          // 解析失败，忽略
        }
      }
      // 服务器确认保存数量
      else if (message.contains("服务器确认保存了") && message.contains("个文件")) {
        try {
          final countStr = message.split("服务器确认保存了")[1].split("个文件")[0].trim();
          serverConfirmedCount = int.tryParse(countStr) ?? 0;
        } catch (e) {
          // 解析失败，忽略
        }
      }
      // 服务器已确认保存信息
      else if (message.contains("服务器已确认保存：") && message.contains("个文件")) {
        try {
          final countStr = message.split("服务器已确认保存：")[1].split("个文件")[0].trim();
          final count = int.tryParse(countStr) ?? 0;
          if (count > 0) {
            // 单个文件确认，累计计数
            serverConfirmedCount += count;
          }
        } catch (e) {
          // 解析失败，忽略
        }
      }
    }
    
    // 如果没有找到不匹配信息，且服务器确认数为0，则不显示此组件
    if (!serverMismatchFound && serverConfirmedCount == 0) {
      return const SizedBox.shrink();
    }
    
    // 计算差异
    final difference = localSuccessCount - serverConfirmedCount;
    final bool hasDifference = difference > 0 && serverConfirmedCount > 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (serverConfirmedCount > 0) ...[
          Row(
            children: [
              Icon(
                Icons.cloud_done,
                color: Colors.blue,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '服务器确认: $serverConfirmedCount 个文件',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
        if (hasDifference) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.orange,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '未确认: $difference 个文件',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '部分文件可能已上传但服务器未确认接收',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ],
        const SizedBox(height: 4),
      ],
    );
  }

  // 新增：构建常见错误类型摘要组件
  Widget _buildCommonErrorSummary(UploadStatus status) {
    // 错误类型计数
    Map<String, int> errorTypes = {};
    
    // 查找常见错误类型
    for (var log in status.logs) {
      if (log.isError) {
        String errorMessage = log.message.toLowerCase();
        
        if (errorMessage.contains('超时') || errorMessage.contains('timeout')) {
          errorTypes['网络超时'] = (errorTypes['网络超时'] ?? 0) + 1;
        } else if (errorMessage.contains('连接') || errorMessage.contains('network') || errorMessage.contains('socket')) {
          errorTypes['网络连接'] = (errorTypes['网络连接'] ?? 0) + 1;
        } else if (errorMessage.contains('服务器') && (errorMessage.contains('500') || errorMessage.contains('503'))) {
          errorTypes['服务器错误'] = (errorTypes['服务器错误'] ?? 0) + 1;
        } else if (errorMessage.contains('不存在') || errorMessage.contains('文件验证')) {
          errorTypes['文件问题'] = (errorTypes['文件问题'] ?? 0) + 1;
        } else if (errorMessage.contains('未确认') || errorMessage.contains('未保存')) {
          errorTypes['服务器未确认'] = (errorTypes['服务器未确认'] ?? 0) + 1;
        } else {
          errorTypes['其他错误'] = (errorTypes['其他错误'] ?? 0) + 1;
        }
      }
    }
    
    // 如果没有错误，返回空组件
    if (errorTypes.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // 按数量排序错误类型
    List<MapEntry<String, int>> sortedErrors = errorTypes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // 最多显示三种主要错误
    sortedErrors = sortedErrors.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '主要问题:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 2),
        ...sortedErrors.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            '• ${entry.key}: ${entry.value}次',
            style: TextStyle(
              fontSize: 11,
              color: Colors.red[800],
            ),
          ),
        )),
        Text(
          '点击查看详细日志',
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: Colors.blue[700],
          ),
        ),
      ],
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
    
    // 美化标识特定类型错误的颜色
    Color dotColor = log.isError ? Colors.red : Colors.blue;
    String message = log.message;
    
    // 增强错误显示
    if (log.isError) {
      // 针对超时错误
      if (message.contains('超时') || message.contains('timeout')) {
        dotColor = Colors.orange;
      } 
      // 针对网络连接错误
      else if (message.contains('网络') || message.contains('连接') || message.contains('socket')) {
        dotColor = Colors.deepOrange;
      }
      // 针对服务器错误
      else if (message.contains('服务器') && (message.contains('500') || message.contains('503'))) {
        dotColor = Colors.purple;
      }
      // 针对文件问题
      else if (message.contains('不存在') || message.contains('文件验证')) {
        dotColor = Colors.amber[700] ?? Colors.amber;
      }
    } else if (message.contains('上传成功')) {
      dotColor = Colors.green;
    }
    
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
              color: dotColor,
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