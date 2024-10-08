import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Companyprofile extends StatelessWidget {
  const Companyprofile({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://www.lerobotics.com/Products/'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('公司介绍'),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
