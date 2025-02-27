// lib/screens/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController? controller;
  bool isProcessing = false;
  String? lastScanned;

  @override
  void initState() {
    super.initState();
    // 使用较低的分辨率可以提高扫描性能
    controller = MobileScannerController(
      // 降低扫描速度以提高准确性
      detectionSpeed: DetectionSpeed.normal,
      // 启用所有格式支持
      formats: BarcodeFormat.values,
      // 提高扫描灵敏度
      detectionTimeoutMs: 1000, // 增加检测超时时间
    );

    // 确保相机在页面初始化后启动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller?.start();
      }
    });
  }

  // 这个函数会在应用切换到前台时自动调用，确保相机重新初始化
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller?.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描二维码'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: () => controller?.toggleTorch(),
            tooltip: '开关闪光灯',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 扫描器视图
                MobileScanner(
                  controller: controller,
                  onDetect: _onDetect,
                  scanWindow: Rect.fromCenter(
                    center: Offset(
                      MediaQuery.of(context).size.width / 2,
                      MediaQuery.of(context).size.height / 2.5,
                    ),
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.width * 0.8,
                  ),
                ),

                // 扫描框
                CustomPaint(
                  painter: ScannerOverlayPainter(
                    scanWindow: Rect.fromCenter(
                      center: Offset(
                        MediaQuery.of(context).size.width / 2,
                        MediaQuery.of(context).size.height / 2.5,
                      ),
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                    ),
                    borderColor: Theme.of(context).primaryColor,
                  ),
                  child: Container(),
                ),

                // 加载指示器
                if (isProcessing)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          '正在处理...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // 底部提示区域
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                const Text(
                  '将二维码放入扫描框内',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '支持普通二维码和条形码',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _onManualInput,
                  child: const Text('手动输入'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ],
            ),
          ),
        ],
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
      _createProject(result);
    }
  }

  // 处理扫描结果

// 修改 _onDetect 方法，使其更宽容地处理结果
  void _onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    // 打印所有识别到的条码信息，便于调试
    for (final barcode in barcodes) {
      debugPrint('检测到条码: 类型=${barcode.format}, 值=${barcode.rawValue}');
    }

    // 处理第一个有效码
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;

      if (code == null || code.isEmpty) continue;

      // 设置处理状态
      setState(() {
        isProcessing = true;
      });

      // 打印详细日志
      debugPrint('正在处理二维码: $code');

      // 不过滤内容，直接尝试创建项目
      try {
        final provider = Provider.of<ProjectProvider>(context, listen: false);
        await provider.createProject(code.trim());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('项目 "$code" 创建成功')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        _showError('创建项目失败: $e');
        setState(() {
          isProcessing = false;
        });
        controller?.start();
      }

      break;
    }
  }

  // 从二维码内容提取项目名称
  String _extractProjectName(String qrData) {
    try {
      // 首先尝试按照"名称:其他信息"的格式解析
      final parts = qrData.split(':');
      if (parts.isNotEmpty && parts[0].isNotEmpty) {
        return parts[0].trim();
      }

      // 如果没有冒号，直接返回完整内容
      return qrData.trim();
    } catch (e) {
      debugPrint('提取项目名称失败: $e');
      return qrData; // 如果处理失败，返回原始内容
    }
  }

  // 创建项目
  Future<void> _createProject(String name) async {
    try {
      final provider = Provider.of<ProjectProvider>(context, listen: false);
      await provider.createProject(name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('项目 "$name" 创建成功')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('创建项目失败: $e');
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
        controller?.start();
      }
    }
  }

  void _showError(String message) {
    debugPrint(message);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

// 自定义扫描框绘制
class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final Color borderColor;

  ScannerOverlayPainter({
    required this.scanWindow,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // 绘制半透明背景（除了扫描窗口区域）
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRect(scanWindow),
      ),
      backgroundPaint,
    );

    // 绘制边框
    canvas.drawRect(scanWindow, borderPaint);

    // 绘制四角
    const cornerSize = 20.0;
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    // 左上角
    canvas.drawPath(
      Path()
        ..moveTo(scanWindow.left, scanWindow.top + cornerSize)
        ..lineTo(scanWindow.left, scanWindow.top)
        ..lineTo(scanWindow.left + cornerSize, scanWindow.top),
      cornerPaint,
    );

    // 右上角
    canvas.drawPath(
      Path()
        ..moveTo(scanWindow.right - cornerSize, scanWindow.top)
        ..lineTo(scanWindow.right, scanWindow.top)
        ..lineTo(scanWindow.right, scanWindow.top + cornerSize),
      cornerPaint,
    );

    // 右下角
    canvas.drawPath(
      Path()
        ..moveTo(scanWindow.right, scanWindow.bottom - cornerSize)
        ..lineTo(scanWindow.right, scanWindow.bottom)
        ..lineTo(scanWindow.right - cornerSize, scanWindow.bottom),
      cornerPaint,
    );

    // 左下角
    canvas.drawPath(
      Path()
        ..moveTo(scanWindow.left + cornerSize, scanWindow.bottom)
        ..lineTo(scanWindow.left, scanWindow.bottom)
        ..lineTo(scanWindow.left, scanWindow.bottom - cornerSize),
      cornerPaint,
    );

    // 添加激光线动画效果（这里简单示例，实际中可以使用动画控制器）
    final laserPaint = Paint()
      ..color = borderColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(scanWindow.left, scanWindow.top + scanWindow.height / 2),
      Offset(scanWindow.right, scanWindow.top + scanWindow.height / 2),
      laserPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}