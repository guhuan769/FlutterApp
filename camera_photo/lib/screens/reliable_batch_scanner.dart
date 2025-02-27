// lib/screens/reliable_batch_scanner.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';

class ReliableBatchScannerScreen extends StatefulWidget {
  const ReliableBatchScannerScreen({Key? key}) : super(key: key);

  @override
  State<ReliableBatchScannerScreen> createState() => _ReliableBatchScannerScreenState();
}

class _ReliableBatchScannerScreenState extends State<ReliableBatchScannerScreen> {
  final List<Map<String, dynamic>> scannedProjects = [];
  final Set<String> scannedQRCodes = {};
  bool isScanning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('批量扫描二维码'),
        actions: [
          if (scannedProjects.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('完成', style: TextStyle(color: Colors.white)),
              onPressed: _finishScanning,
            ),
        ],
      ),
      body: Column(
        children: [
          // 头部区域 - 扫描按钮
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                Text(
                  '已扫描 ${scannedProjects.length} 个项目',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: isScanning ? null : _startScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(isScanning ? '扫描中...' : '扫描二维码'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),

          // 项目列表
          Expanded(
            child: scannedProjects.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, size: 72, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    '点击上方按钮开始扫描',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _onManualInput,
                    icon: const Icon(Icons.edit),
                    label: const Text('手动输入'),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: scannedProjects.length,
              itemBuilder: (context, index) {
                final project = scannedProjects[index];
                return Dismissible(
                  key: ValueKey(project['rawData']),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    setState(() {
                      final removed = scannedProjects.removeAt(index);
                      scannedQRCodes.remove(removed['rawData']);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已移除: ${project['name']}')),
                    );
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      child: Text((index + 1).toString()),
                    ),
                    title: Text(
                      project['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: project['info'] != null && project['info'].toString().isNotEmpty
                        ? Text(project['info'].toString())
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() {
                          scannedProjects.removeAt(index);
                          scannedQRCodes.remove(project['rawData']);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // 底部按钮区域
          if (scannedProjects.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          scannedProjects.clear();
                          scannedQRCodes.clear();
                        });
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('清空列表'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _finishScanning,
                      icon: const Icon(Icons.check),
                      label: const Text('完成'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: scannedProjects.isEmpty
          ? FloatingActionButton(
        onPressed: _startScan,
        child: const Icon(Icons.qr_code_scanner),
      )
          : null,
    );
  }

  // 开始扫描
  Future<void> _startScan() async {
    if (isScanning) return;

    setState(() {
      isScanning = true;
    });

    try {
      // 配置扫描选项
      var options = ScanOptions(
        restrictFormat: const [],
        useCamera: -1,
        autoEnableFlash: false,
        android: const AndroidOptions(
          aspectTolerance: 0.5,
          useAutoFocus: true,
        ),
        strings: {
          'cancel': '取消',
          'flash_on': '开启闪光灯',
          'flash_off': '关闭闪光灯',
        },
      );

      var result = await BarcodeScanner.scan(options: options);

      // 处理扫描结果
      if (result.type != ResultType.Cancelled && result.rawContent.isNotEmpty) {
        _processQRData(result.rawContent);
      }
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.cameraAccessDenied) {
        _showError('需要相机权限才能扫描二维码');
      } else {
        _showError('扫描过程中出错: ${e.message}');
      }
    } on Exception catch (e) {
      _showError('发生错误: $e');
    } finally {
      // 无论成功失败，最后都要重置扫描状态
      if (mounted) {
        setState(() {
          isScanning = false;
        });
      }
    }
  }

  // 处理二维码数据
  void _processQRData(String qrData) {
    debugPrint('扫描到二维码: $qrData');

    // 防止重复添加
    if (scannedQRCodes.contains(qrData)) {
      _showError('此二维码已添加');
      return;
    }

    try {
      // 提取并处理数据
      Map<String, dynamic> projectData = _parseQRData(qrData);

      if (projectData['name'].toString().trim().isNotEmpty) {
        setState(() {
          projectData['rawData'] = qrData;
          scannedProjects.add(projectData);
          scannedQRCodes.add(qrData);
        });

        // 添加完成后自动继续扫描
        HapticFeedback.mediumImpact(); // 振动反馈
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已添加: ${projectData['name']}'),
            duration: const Duration(seconds: 1),
            action: SnackBarAction(
              label: '继续扫描',
              onPressed: _startScan,
            ),
          ),
        );
      } else {
        _showError('无法从二维码获取有效的项目名称');
      }
    } catch (e) {
      _showError('处理二维码数据失败: $e');
    }
  }

  // 从二维码内容提取项目名称和信息
  Map<String, dynamic> _parseQRData(String qrData) {
    try {
      // 尝试多种解析方式

      // 1. 尝试按冒号分割（如 "名称:信息"）
      final parts = qrData.split(':');
      if (parts.length > 1) {
        return {
          'name': parts[0].trim(),
          'info': parts.sublist(1).join(':').trim(),
        };
      }

      // 2. 尝试按其他常用分隔符分割
      for (var separator in ['|', '-', '_', '，', ',', '/', '\\']) {
        if (qrData.contains(separator)) {
          final parts = qrData.split(separator);
          if (parts.length > 1) {
            return {
              'name': parts[0].trim(),
              'info': parts.sublist(1).join(separator).trim(),
            };
          }
        }
      }

      // 3. 无法分割时，整个内容作为名称
      return {
        'name': qrData.trim(),
        'info': '',
      };
    } catch (e) {
      debugPrint('解析二维码数据失败: $e');
      return {
        'name': qrData.trim(),
        'info': '',
      };
    }
  }

  // 完成扫描并创建所有项目
  void _finishScanning() async {
    if (scannedProjects.isEmpty) return;

    final provider = Provider.of<ProjectProvider>(context, listen: false);
    int successCount = 0;
    List<String> failedProjects = [];

    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text('正在创建 ${scannedProjects.length} 个项目...'),
          ],
        ),
      ),
    );

    // 创建所有项目
    for (final project in scannedProjects) {
      try {
        await provider.createProject(project['name']);
        successCount++;
      } catch (e) {
        debugPrint('创建项目失败: ${project['name']}, 错误: $e');
        failedProjects.add(project['name']);
      }
    }

    // 关闭加载对话框
    if (mounted) Navigator.pop(context);

    // 显示结果并返回
    if (mounted) {
      if (failedProjects.isNotEmpty) {
        // 如果有创建失败的项目，显示详细信息
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('创建完成 ($successCount/${scannedProjects.length})'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('成功创建了 $successCount 个项目'),
                if (failedProjects.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('以下项目创建失败:'),
                  const SizedBox(height: 4),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: failedProjects.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('• ${failedProjects[index]}'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text('确定'),
              ),
            ],
          ),
        );
      } else {
        // 如果全部成功，显示简单的成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功创建 $successCount 个项目')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  // 处理手动输入
  void _onManualInput() async {
    final TextEditingController controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('手动输入项目名称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入项目名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final projectData = {
        'name': result.trim(),
        'info': '',
        'rawData': 'manual:${result.trim()}',
      };

      setState(() {
        scannedProjects.add(projectData);
        scannedQRCodes.add(projectData['rawData']!);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已添加: ${result.trim()}')),
      );
    }
  }

  // 显示错误消息
  void _showError(String message) {
    debugPrint(message);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}