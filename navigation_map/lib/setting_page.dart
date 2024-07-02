import 'package:flutter/material.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            // Change 'Colors.red' to your desired color
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('设置'),
        ),
        body: const Text('测试'));
  }
}
