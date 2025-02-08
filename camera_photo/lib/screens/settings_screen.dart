// lib/screens/settings_screen.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/settings_manager.dart';
import '../main.dart';
import '../providers/photo_provider.dart';
import 'camera_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _urlController;
  bool _isTesting = false;
  bool _cropEnabled = true;
  ResolutionPreset _selectedResolution = ResolutionPreset.max;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final savedUrl = (await SharedPreferences.getInstance()).getString('api_url') ?? 'http://your-server:5000/upload';
    final cropEnabled = await SettingsManager.getCropEnabled();
    final resolution = await SettingsManager.getResolutionPreset();

    setState(() {
      _urlController.text = savedUrl;
      _cropEnabled = cropEnabled;
      _selectedResolution = resolution;
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

    setState(() => _isTesting = true);

    try {
      final url = _urlController.text;
      final response = await http.get(Uri.parse('${url}/status'));

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
        setState(() => _isTesting = false);
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

  Future<void> _showResolutionPicker(BuildContext context) async {
    final ResolutionPreset? result = await showDialog<ResolutionPreset>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('选择相机分辨率'),
          children: ResolutionPreset.values.map((preset) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, preset);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(SettingsManager.resolutionPresetToString(preset)),
                  if (preset == _selectedResolution)
                    const Icon(Icons.check, color: Colors.blue),
                ],
              ),
            );
          }).toList(),
        );
      },
    );

    if (result != null) {
      await SettingsManager.setResolutionPreset(result);
      setState(() => _selectedResolution = result);
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 相机设置卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '相机设置',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('启用图片裁剪'),
                        subtitle: const Text('拍照时显示裁剪框'),
                        value: _cropEnabled,
                        onChanged: (value) async {
                          await SettingsManager.setCropEnabled(value);
                          setState(() => _cropEnabled = value);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('相机分辨率'),
                        subtitle: Text(SettingsManager.resolutionPresetToString(_selectedResolution)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showResolutionPicker(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 服务器设置卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '服务器设置',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isTesting ? null : () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CameraScreen(),
                    ),
                        (route) => false,
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