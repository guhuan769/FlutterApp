// lib/screens/qr_test_page.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// 用于开发测试的二维码生成页面
class QRTestPage extends StatefulWidget {
  const QRTestPage({Key? key}) : super(key: key);

  @override
  State<QRTestPage> createState() => _QRTestPageState();
}

class _QRTestPageState extends State<QRTestPage> {
  final TextEditingController _controller = TextEditingController(text: "测试项目");
  String qrData = "测试项目";

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('二维码测试'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '测试用二维码',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: '项目名称',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    qrData = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              // 生成二维码
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 250.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '二维码内容: $qrData',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              const Text(
                '使用说明: 使用扫码功能扫描上面的二维码，\n可以快速创建同名项目。\n请尽量保持屏幕亮度足够高以便于扫描。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('返回扫描页面'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}