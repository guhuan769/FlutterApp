// lib/screens/reliable_qr_scanner.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';

class ReliableQRScannerScreen extends StatefulWidget {
  const ReliableQRScannerScreen({Key? key}) : super(key: key);

  @override
  State<ReliableQRScannerScreen> createState() => _ReliableQRScannerScreenState();
}

class _ReliableQRScannerScreenState extends State<ReliableQRScannerScreen> {
  String? scanResult;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    // 页面加载后自动开始扫描
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  // 开始扫描
  Future<void> _startScan() async {
    try {
      // 配置扫描选项
      var options = ScanOptions(
        // 使用所有可用的条码格式以提高兼容性
        restrictFormat: const [],
        useCamera: -1, // 使用默认相机
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
        setState(() {
          scanResult = result.rawContent;
          isProcessing = true;
        });

        // 使用扫描结果创建项目
        await _processQRData(result.rawContent);
      } else {
        // 用户取消了扫描，返回上一页
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } on PlatformException catch (e) {
      // 处理平台特定错误
      if (e.code == BarcodeScanner.cameraAccessDenied) {
        _showError('需要相机权限才能扫描二维码');
      } else {
        _showError('扫描过程中出错: ${e.message}');
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } on Exception catch (e) {
      _showError('发生错误: $e');
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  // 处理二维码数据并创建项目
  Future<void> _processQRData(String qrData) async {
    try {
      debugPrint('扫描到二维码: $qrData');

      // 尝试UTF-8解码
      Uint8List? bytes;
      try {
        // 将扫描结果转换为字节
        bytes = Uint8List.fromList(qrData.codeUnits);
        final utf8Decoded = utf8.decode(bytes, allowMalformed: true);
        debugPrint('UTF-8解码结果: $utf8Decoded');
        qrData = utf8Decoded; // 使用解码后的数据
      } catch (e) {
        debugPrint('UTF-8解码失败: $e');
        // 继续使用原始数据
      }

      // 提取项目名称
      String projectName = _extractProjectName(qrData);

      if (projectName.isNotEmpty) {
        // 创建项目
        final provider = Provider.of<ProjectProvider>(context, listen: false);
        await provider.createProject(projectName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('项目 "$projectName" 创建成功')),
          );
          Navigator.pop(context, true); // 返回上一页并传递成功标志
        }
      } else {
        _showError('无法从二维码获取有效的项目名称');
        _resetAndRetry();
      }
    } catch (e) {
      _showError('创建项目失败: $e');
      _resetAndRetry();
    }
  }

  // 从二维码内容提取项目名称
  String _extractProjectName(String qrData) {
    // 尝试不同的提取方式，增加容错性
    try {
      // 首先尝试按冒号分割（如 "名称:信息"）
      final parts = qrData.split(':');
      if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
        return parts[0].trim();
      }

      // 如果没有冒号，检查是否有其他分隔符如 |、-、_ 等
      for (var separator in ['|', '-', '_', '，', ',', '/', '\\']) {
        if (qrData.contains(separator)) {
          final parts = qrData.split(separator);
          if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
            return parts[0].trim();
          }
        }
      }

      // 如果没有分隔符，直接返回整个内容作为项目名称
      return qrData.trim();
    } catch (e) {
      debugPrint('提取项目名称时出错: $e');
      return qrData.trim(); // 出错时返回原始内容
    }
  }

  // 重置状态并重试扫描
  void _resetAndRetry() {
    if (mounted) {
      setState(() {
        scanResult = null;
        isProcessing = false;
      });

      // 短暂延迟后重新开始扫描
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _startScan();
        }
      });
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
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描二维码'),
      ),
      body: Center(
        child: isProcessing
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text('正在处理二维码...\n$scanResult',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '正在启动扫描...',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
      // 添加底部按钮，允许用户手动输入
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _onManualInput,
          child: const Text('手动输入项目名称'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
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
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final provider = Provider.of<ProjectProvider>(context, listen: false);
        await provider.createProject(result);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('项目 "$result" 创建成功')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        _showError('创建项目失败: $e');
      }
    }
  }
}