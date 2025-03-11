import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/project.dart';

class QRGeneratorScreen extends StatelessWidget {
  final Project project;

  const QRGeneratorScreen({
    Key? key,
    required this.project,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final qrData = {
      'id': project.id,
      'name': project.name,
      'createdAt': project.createdAt.toIso8601String(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('项目二维码'),
      ),
      body: Center(
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
                    ),
                    const SizedBox(height: 16),
                    QrImageView(
                      data: qrData.toString(),
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '使用扫描功能扫描此二维码\n即可快速定位到此项目',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}