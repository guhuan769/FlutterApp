// lib/widgets/upload_status_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';

class UploadStatusWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(
        status.projectName,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!status.isComplete)
            LinearProgressIndicator(value: status.progress),
          Text(
            status.status,
            style: const TextStyle(fontSize: 12),
          ),
          if (status.error != null)
            Text(
              status.error!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
        ],
      ),
      trailing: status.isComplete
          ? Icon(
              status.isSuccess ? Icons.check_circle : Icons.error,
              color: status.isSuccess ? Colors.green : Colors.red,
            )
          : const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
      onTap: onDismiss,
    );
  }
}