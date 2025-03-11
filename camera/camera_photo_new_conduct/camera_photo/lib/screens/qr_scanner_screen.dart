// lib/screens/qr_scanner_screen.dart
import 'dart:convert';
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

class _QRScannerScreenState extends State<QRScannerScreen> with WidgetsBindingObserver {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  String? lastScanned;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      formats: const [BarcodeFormat.qrCode],
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller?.start();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _controller?.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描二维码'),
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
      body: Stack(
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
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null) return;

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

      // 设置当前项目
      provider.setCurrentProject(project);

      if (mounted) {
        Navigator.pop(context, project);
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
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