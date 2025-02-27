// lib/screens/batch_qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';

class BatchQRScannerScreen extends StatefulWidget {
  const BatchQRScannerScreen({Key? key}) : super(key: key);

  @override
  State<BatchQRScannerScreen> createState() => _BatchQRScannerScreenState();
}

class _BatchQRScannerScreenState extends State<BatchQRScannerScreen> with TickerProviderStateMixin {
  MobileScannerController? controller;
  bool isProcessing = false;
  String? lastScanned;
  final List<Map<String, dynamic>> scannedProjects = [];
  final Set<String> scannedQRCodes = {};

  // 添加动画控制器用于扫描线效果
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // 使用较低的分辨率可以提高扫描性能
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      formats: const [BarcodeFormat.qrCode, BarcodeFormat.ean13],
    );

    // 初始化动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _animationController.repeat(reverse: true);

    // 确保相机在页面初始化后启动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller?.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('批量扫描二维码'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: () => controller?.toggleTorch(),
            tooltip: '开关闪光灯',
          ),
          if (scannedProjects.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _finishScanning,
              tooltip: '完成扫描',
            ),
        ],
      ),
      body: Column(
        children: [
          // 扫描区域
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 相机视图
                MobileScanner(
                  controller: controller,
                  onDetect: _onDetect,
                  scanWindow: Rect.fromCenter(
                    center: Offset(
                      MediaQuery.of(context).size.width / 2,
                      MediaQuery.of(context).size.height / 6,
                    ),
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.width * 0.8,
                  ),
                ),

                // 扫描框
                CustomPaint(
                  foregroundPainter: ScannerOverlayPainter(
                    scanWindow: Rect.fromCenter(
                      center: Offset(
                        MediaQuery.of(context).size.width / 2,
                        MediaQuery.of(context).size.height / 6,
                      ),
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                    ),
                    borderColor: Theme.of(context).primaryColor,
                    animation: _animationController,
                  ),
                  child: Container(),
                ),

                // 处理中指示器
                if (isProcessing)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
          ),

          // 已扫描项目列表
          Expanded(
            flex: 4,
            child: Column(
              children: [
                // 标题栏
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '已扫描项目 (${scannedProjects.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (scannedProjects.isNotEmpty)
                        TextButton.icon(
                          icon: const Icon(Icons.delete_sweep, size: 18),
                          label: const Text('清空'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            setState(() {
                              scannedProjects.clear();
                              scannedQRCodes.clear();
                            });
                          },
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
                        Icon(
                          Icons.qr_code_scanner,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '尚未扫描任何项目\n请将二维码对准扫描框',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
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
                            child: Icon(
                              Icons.qr_code,
                              color: Theme.of(context).primaryColor,
                            ),
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

                // 底部按钮
                if (scannedProjects.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: _finishScanning,
                      icon: const Icon(Icons.check),
                      label: Text('完成并创建 ${scannedProjects.length} 个项目'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),

                // 手动添加按钮
                if (scannedProjects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: OutlinedButton.icon(
                      onPressed: _onManualInput,
                      icon: const Icon(Icons.add),
                      label: const Text('手动添加项目'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 处理扫描结果
  void _onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;

      if (code == null || code.isEmpty) continue;

      // 防止重复扫描
      if (scannedQRCodes.contains(code)) continue;

      // 设置处理状态
      setState(() {
        isProcessing = true;
      });

      // 振动反馈
      HapticFeedback.mediumImpact();

      try {
        // 处理二维码数据
        debugPrint('扫描到的二维码数据: $code');

        final projectData = _parseQRData(code);

        if (projectData['name']?.isNotEmpty == true) {
          // 添加到列表
          setState(() {
            projectData['rawData'] = code;
            scannedProjects.add(projectData);
            scannedQRCodes.add(code);
          });

          // 显示提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已添加: ${projectData['name']}'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          _showError('无效的二维码数据');
        }
      } catch (e) {
        _showError('处理二维码失败: $e');
      } finally {
        // 延迟一点时间再恢复扫描，以便用户看到反馈
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              isProcessing = false;
            });
          }
        });
      }

      break; // 只处理第一个有效码
    }
  }

  // 手动输入
  void _onManualInput() async {
    final TextEditingController controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('手动添加项目'),
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
        'name': result,
        'info': '',
        'rawData': 'manual:$result',
      };

      setState(() {
        scannedProjects.add(projectData);
        scannedQRCodes.add(projectData['rawData']!);
      });
    }
  }

  // 继续 lib/screens/batch_qr_scanner_screen.dart

  // 解析二维码数据
  Map<String, dynamic> _parseQRData(String qrData) {
    try {
      // 尝试解析格式为 "名称:附加信息" 的数据
      final parts = qrData.split(':');
      return {
        'name': parts.isNotEmpty ? parts[0].trim() : qrData.trim(),
        'info': parts.length > 1 ? parts[1].trim() : '',
      };
    } catch (e) {
      debugPrint('解析二维码数据失败: $e');
      return {'name': qrData.trim()};
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

  @override
  void dispose() {
    _animationController.dispose();
    controller?.dispose();
    super.dispose();
  }
}

// 自定义扫描框绘制
class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final Color borderColor;
  final Animation<double> animation;

  ScannerOverlayPainter({
    required this.scanWindow,
    required this.borderColor,
    required this.animation,
  }) : super(repaint: animation);

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

    // 添加激光线动画效果
    final laserPaint = Paint()
      ..color = borderColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 使用动画控制器来移动激光线
    final y = scanWindow.top + (scanWindow.height * animation.value);
    canvas.drawLine(
      Offset(scanWindow.left, y),
      Offset(scanWindow.right, y),
      laserPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}