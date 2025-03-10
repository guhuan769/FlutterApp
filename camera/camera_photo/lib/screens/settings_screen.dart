// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/settings_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _urlController;
  bool _isTesting = false;
  bool _showCenterPoint = true;
  ResolutionPreset _selectedResolution = ResolutionPreset.high;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final savedUrl =
        (await SharedPreferences.getInstance()).getString('api_url') ??
            'http://your-server:5000/upload';
    final resolution = await SettingsManager.getResolutionPreset();
    final showCenterPoint = await SettingsManager.getShowCenterPoint();

    setState(() {
      _urlController.text = savedUrl;
      _selectedResolution = resolution;
      _showCenterPoint = showCenterPoint;
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

  // 更新为系统相机的分辨率选择器
  Future<void> _showResolutionPicker(BuildContext context) async {
    final List<Map<String, dynamic>> resolutionOptions = [
      {
        'preset': ResolutionPreset.high,
        'name': '高清 (1080p)',
        'description': '1920x1080',
        'systemCameraDesc': '标准相机质量 (70%)',
      },
      {
        'preset': ResolutionPreset.veryHigh,
        'name': '超清 (2160p)',
        'description': '3840x2160',
        'systemCameraDesc': '高质量 (85%)',
      },
      {
        'preset': ResolutionPreset.max,
        'name': '最高清晰度',
        'description': '设备支持的最高分辨率',
        'systemCameraDesc': '最高质量 (100%)',
      },
    ];

    final ResolutionPreset? result = await showDialog<ResolutionPreset>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择相机分辨率'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '使用系统相机时，实际分辨率取决于设备支持',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '更高的清晰度需要更多的存储空间，请根据需要选择',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 分辨率列表
                ...resolutionOptions.map((option) {
                  final bool isCurrentSelection = option['preset'] == _selectedResolution;
                  return ListTile(
                    title: Text(option['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(option['description']),
                        Text(
                          option['systemCameraDesc'],
                          style: const TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ],
                    ),
                    selected: isCurrentSelection,
                    leading: isCurrentSelection
                        ? const Icon(Icons.check_circle, color: Colors.blue)
                        : const Icon(Icons.circle_outlined),
                    onTap: () => Navigator.pop(context, option['preset']),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        // 保存新的分辨率设置
        await SettingsManager.setResolutionPreset(result);

        if (mounted) {
          setState(() => _selectedResolution = result);

          // 显示提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('分辨率已更改为: ${SettingsManager.resolutionPresetToString(result)}'),
                  const Text('下次拍照时将使用新的分辨率设置'),
                ],
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('保存分辨率设置失败: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('保存设置失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // 更新相机设置卡片中的分辨率显示
  Widget _buildCameraSettingsCard() {
    return Card(
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

            // 中心点显示开关
            SwitchListTile(
              title: const Text('显示中心点'),
              subtitle: const Text('在相机预览中显示中心标识'),
              value: _showCenterPoint,
              onChanged: (value) async {
                await SettingsManager.setShowCenterPoint(value);
                setState(() => _showCenterPoint = value);
              },
            ),

            const Divider(),

            // 分辨率选择
            ListTile(
              title: Row(
                children: [
                  const Text('相机分辨率'),
                  const SizedBox(width: 8),
                  if (_selectedResolution == ResolutionPreset.max)
                    const Tooltip(
                      message: '最高分辨率可能占用更多存储空间',
                      child: Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(SettingsManager.resolutionPresetToString(_selectedResolution)),
                  Text(
                    SettingsManager.getResolutionDescription(_selectedResolution),
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    '系统相机质量: ${SettingsManager.getSystemCameraQuality(_selectedResolution)}%',
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showResolutionPicker(context),
            ),
          ],
        ),
      ),
    );
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
              _buildCameraSettingsCard(),
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
                      Column(
                        children: [
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
                                  onPressed: _isTesting
                                      ? null
                                      : () {
                                    if (_formKey.currentState!.validate()) {
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}