import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import 'package:intl/intl.dart';

class UploadHistoryDialog extends StatelessWidget {
  final String projectId;
  final String projectName;

  const UploadHistoryDialog({
    Key? key,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final logs = provider.getProjectUploadLogs(projectId);
        final uploadCount = provider.getProjectUploadCount(projectId);
        final currentStatus = provider.getProjectUploadStatus(projectId);

        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          projectName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '总上传次数: $uploadCount',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (currentStatus != null && !currentStatus.isComplete)
                  _buildCurrentUploadStatus(currentStatus),
                const SizedBox(height: 8),
                const Text(
                  '上传历史记录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: logs.isEmpty
                      ? const Center(
                          child: Text('暂无上传记录'),
                        )
                      : ListView.builder(
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[logs.length - 1 - index];
                            return _buildLogItem(log);
                          },
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      provider.clearProjectUploadStatus(projectId);
                      Navigator.of(context).pop();
                    },
                    child: const Text('清除历史记录'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentUploadStatus(UploadStatus status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.upload_file, size: 16),
              const SizedBox(width: 8),
              const Text(
                '当前上传进度',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: status.progress,
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(height: 4),
          Text(
            status.status,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(UploadLog log) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            log.isError ? Icons.error : Icons.info,
            size: 16,
            color: log.isError ? Colors.red : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.message,
                  style: TextStyle(
                    color: log.isError ? Colors.red : Colors.black,
                  ),
                ),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 