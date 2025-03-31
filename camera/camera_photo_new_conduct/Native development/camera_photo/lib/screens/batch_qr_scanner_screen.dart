// lib/screens/batch_qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';

class BatchQRScannerScreen extends StatefulWidget {
  const BatchQRScannerScreen({Key? key}) : super(key: key);

  @override
  State<BatchQRScannerScreen> createState() => _BatchQRScannerScreenState();
}

class _BatchQRScannerScreenState extends State<BatchQRScannerScreen> {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  final Set<String> _scannedCodes = {};
  final List<String> _scannedProjects = [];

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || _scannedCodes.contains(rawValue)) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 解析二维码数据
      final data = rawValue.split(':');
      if (data.length != 2) {
        throw Exception('无效的二维码格式');
      }

      final projectName = data[0];
      final projectId = data[1];

      // 查找项目
      final provider = Provider.of<ProjectProvider>(context, listen: false);
      final project = provider.projects.firstWhere(
        (p) => p.id == projectId,
        orElse: () => throw Exception('未找到项目'),
      );

      // 添加到已扫描列表
      _scannedCodes.add(rawValue);
      _scannedProjects.add(project.name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已添加项目: ${project.name}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('扫描失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('批量扫描'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller?.torchState ?? ValueNotifier(false),
              builder: (context, state, child) {
                switch (state as TorchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => _controller?.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller?.cameraFacingState ?? ValueNotifier(CameraFacing.back),
              builder: (context, state, child) {
                switch (state as CameraFacing) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => _controller?.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
                if (_isProcessing)
                  const Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: ScannerOverlayPainter(),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '已扫描: ${_scannedProjects.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _scannedProjects.isEmpty
                            ? null
                            : () {
                                setState(() {
                                  _scannedCodes.clear();
                                  _scannedProjects.clear();
                                });
                              },
                        child: const Text('清空'),
                      ),
                    ],
                  ),
                ),
                if (_scannedProjects.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _scannedProjects.length,
                      itemBuilder: (context, index) {
                        final projectName = _scannedProjects[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.check_circle),
                          title: Text(projectName),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              setState(() {
                                _scannedCodes.remove(_scannedProjects[index]);
                                _scannedProjects.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.width * 0.8,
    );

    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addRect(scanArea),
    );

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(scanArea, borderPaint);

    // 绘制四个角
    const cornerLength = 20.0;
    final cornerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // 左上角
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft.translate(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft.translate(0, cornerLength),
      cornerPaint,
    );

    // 右上角
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight.translate(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight.translate(0, cornerLength),
      cornerPaint,
    );

    // 左下角
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft.translate(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft.translate(0, -cornerLength),
      cornerPaint,
    );

    // 右下角
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight.translate(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight.translate(0, -cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}