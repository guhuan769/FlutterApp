import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/project.dart';

class QRGeneratorScreen extends StatelessWidget {
  final Project project;

  const QRGeneratorScreen({Key? key, required this.project}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 创建二维码数据，可以根据需要调整格式
    final qrData = "${project.name}:${project.id}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('项目二维码'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        project.name,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '扫描此二维码可以快速创建同名项目',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('复制项目信息'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: qrData));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('项目信息已复制到剪贴板')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}