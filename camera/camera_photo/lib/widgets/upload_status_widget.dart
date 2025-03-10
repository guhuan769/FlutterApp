// lib/widgets/upload_status_widget.dart
import 'package:flutter/material.dart';
import '../providers/project_provider.dart';

class UploadStatusWidget extends StatelessWidget {
  final UploadStatus status;
  final VoidCallback? onDismiss;

  const UploadStatusWidget({
    Key? key,
    required this.status,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('upload-${status.projectId}'),
      direction: onDismiss != null
          ? DismissDirection.horizontal
          : DismissDirection.none,
      onDismissed: (_) => onDismiss?.call(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.projectName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          status.status,
                          style: TextStyle(
                            color: status.error != null ? Colors.red : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (status.isComplete)
                    Icon(
                      status.isSuccess ? Icons.check_circle : Icons.error,
                      color: status.isSuccess ? Colors.green : Colors.red,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: status.progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                status.isComplete
                        ? (status.isSuccess ? Colors.green : Colors.red)
                        : Colors.blue,
                  ),
                  minHeight: 6,
                ),
              ),
              if (status.error != null) ...[
                const SizedBox(height: 4),
                Text(
                  status.error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
              if (onDismiss != null)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    '左右滑动以清除',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}