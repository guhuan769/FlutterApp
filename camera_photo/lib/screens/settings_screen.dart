// lib/screens/settings_screen.dart
import 'package:camera_photo/screens/camera_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import '../providers/photo_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _urlController;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('api_url') ?? 'http://your-server:5000/upload';
    setState(() {
      _urlController.text = savedUrl;
    });
  }

  Future<void> _saveUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_url', url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设置已保存')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  Future<void> _testApiConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
    });

    try {
      final url = _urlController.text;
      final response = await http.get(Uri.parse(url.replaceAll('/upload', '/status')));

      if (mounted) {
        if (response.statusCode == 200) {
          _showTestResult(true, '接口连接成功！服务器正常运行。');
        } else {
          _showTestResult(false, '接口连接失败: HTTP ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        _showTestResult(false, '接口连接失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  void _showTestResult(bool success, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          success ? '测试成功' : '测试失败',
          style: TextStyle(
            color: success ? Colors.green : Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: '服务器地址',
                  hintText: '例如: http://your-server:5000/upload',
                  border: OutlineInputBorder(),
                  helperText: '请输入完整的上传接口地址',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入服务器地址';
                  }
                  if (!Uri.tryParse(value)!.isAbsolute) {
                    return '请输入有效的URL地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isTesting ? null : _testApiConnection,
                      icon: _isTesting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.refresh),
                      label: Text(_isTesting ? '测试中...' : '测试连接'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isTesting ? null : () {
                        if (_formKey.currentState!.validate()) {
                          Provider.of<PhotoProvider>(context, listen: false)
                              .setApiUrl(_urlController.text);
                          _saveUrl(_urlController.text);
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('保存设置'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isTesting ? null : () {
                  // Navigator.pushReplacement(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (_) => const CameraScreen(),
                  //   ),
                  // );
                  // 使用 pushAndRemoveUntil 清除所有路由历史
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CameraScreen(),
                    ),
                        (route) => false, // 移除所有路由
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('重启应用'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}