// lib/screens/camera_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../utils/settings_manager.dart';
import '../providers/photo_provider.dart';
import 'gallery_screen.dart';
import 'settings_screen.dart';

// 拍照模式枚举
enum PhotoMode {
  start,  // 起始点拍照
  middle, // 中间点拍照
  model,  // 模型点拍照
  end,    // 结束点拍照
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  // ====== 相机控制相关变量 ======
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;

  // ====== 缩放相关变量 ======
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseScale = 1.0;

  // ====== 裁剪框相关变量 ======
  double _cropBoxSize = 200.0;
  final double _minCropBoxSize = 100.0;
  final double _maxCropBoxSize = 500.0;
  Offset _cropBoxPosition = Offset.zero;
  bool _isDraggingCropBox = false;
  bool _isResizingCropBox = false;
  DateTime? _lastTapTime;
  final Duration _doubleTapDuration = const Duration(milliseconds: 300);

  // ====== 对焦相关变量 ======
  Offset? _focusPoint;
  bool _showFocusCircle = false;
  int _retryCount = 0;
  final int _maxRetries = 3;

  // ====== 设置相关变量 ======
  bool _cropEnabled = true;
  bool _showCenterPoint = true;
  ResolutionPreset _currentResolution = ResolutionPreset.max;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cropBoxPosition == Offset.zero) {
      final size = MediaQuery.of(context).size;
      _cropBoxPosition = Offset(
        (size.width - _cropBoxSize) / 2,
        (size.height - _cropBoxSize) / 2,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  // ====== 初始化相关方法 ======
  Future<void> _initializeAll() async {
    await _loadSettings();
    await _loadCameras();
  }

  Future<void> _loadSettings() async {
    try {
      final cropEnabled = await SettingsManager.getCropEnabled();
      final resolution = await SettingsManager.getResolutionPreset();
      final showCenterPoint = await SettingsManager.getShowCenterPoint();

      if (mounted) {
        setState(() {
          _cropEnabled = cropEnabled;
          _currentResolution = resolution;
          _showCenterPoint = showCenterPoint;
        });
      }
    } catch (e) {
      print('加载设置失败: $e');
      _showError('加载设置失败');
    }
  }

  Future<void> _loadCameras() async {
    try {
      _cameras = await availableCameras();
      await _initializeCamera();
    } catch (e) {
      print('加载相机列表失败: $e');
      _showError('无法加载相机列表');
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted || _cameras.isEmpty) return;

    try {
      await _disposeCamera();

      final CameraController cameraController = CameraController(
        _cameras[_currentCameraIndex],
        _currentResolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = cameraController;

      await cameraController.initialize();
      await cameraController.setFlashMode(FlashMode.off);

      _maxAvailableZoom = await cameraController.getMaxZoomLevel();
      _minAvailableZoom = await cameraController.getMinZoomLevel();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _currentZoom = 1.0;
          _retryCount = 0;
        });
      }
    } catch (e) {
      print('相机初始化错误: $e');
      _retryInitialize();
    }
  }

  Future<void> _retryInitialize() async {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      print('尝试重新初始化相机: 第 $_retryCount 次');
      await Future.delayed(Duration(milliseconds: 500 * _retryCount));
      if (mounted) {
        _initializeCamera();
      }
    } else {
      if (mounted) {
        _showError('无法初始化相机，请检查相机权限或重启应用');
      }
    }
  }

  Future<void> _disposeCamera() async {
    try {
      final CameraController? cameraController = _controller;
      if (cameraController != null && cameraController.value.isInitialized) {
        await cameraController.dispose();
      }
    } catch (e) {
      print('相机释放错误: $e');
    } finally {
      _controller = null;
      if (mounted) {
        setState(() => _isInitialized = false);
      }
    }
  }

  // ====== 拍照相关方法 ======
  Future<void> _takePicture(PhotoMode mode) async {
    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final XFile photo = await controller.takePicture();
      final Directory appDir = await getApplicationDocumentsDirectory();

      // 生成时间戳
      final now = DateTime.now();
      final timestamp = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}"
          "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";

      // 根据模式确定文件名前缀
      String prefix;
      switch (mode) {
        case PhotoMode.start:
          prefix = "起始点拍照";
          break;
        case PhotoMode.middle:
          prefix = "中间点拍照";
          break;
        case PhotoMode.model:
          prefix = "模型点拍照";
          break;
        case PhotoMode.end:
          prefix = "结束点拍照";
          break;
      }

      final String filePath = path.join(appDir.path, '${prefix}_$timestamp.jpg');

      // 获取当前照片列表
      final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
      await photoProvider.loadPhotos();
      final photos = photoProvider.photos;

      // 根据不同模式和照片数量处理
      switch (mode) {
        case PhotoMode.start:
          if (photos.isEmpty) {
            // 相册为空，新增照片
            final File originalImage = File(filePath);
            await originalImage.writeAsBytes(await File(photo.path).readAsBytes());
            await _processImage(filePath);
          } else {
            // 有照片，替换第一张
            await photos.first.delete();
            final File originalImage = File(filePath);
            await originalImage.writeAsBytes(await File(photo.path).readAsBytes());
            await _processImage(filePath);
          }
          break;

        case PhotoMode.middle:
        case PhotoMode.model:
          if (photos.isEmpty || photos.length == 1) {
            // 相册为空或只有一张照片，直接新增
            final File originalImage = File(filePath);
            await originalImage.writeAsBytes(await File(photo.path).readAsBytes());
            await _processImage(filePath);
          } else {
            // 两张以上照片，在中间按顺序新增
            final File originalImage = File(filePath);
            await originalImage.writeAsBytes(await File(photo.path).readAsBytes());
            await _processImage(filePath);
          }
          break;

        case PhotoMode.end:
          if (photos.isEmpty) {
            // 相册为空，新增照片
            final File originalImage = File(filePath);
            await originalImage.writeAsBytes(await File(photo.path).readAsBytes());
            await _processImage(filePath);
          } else {
            // 有照片，替换最后一张
            await photos.last.delete();
            final File originalImage = File(filePath);
            await originalImage.writeAsBytes(await File(photo.path).readAsBytes());
            await _processImage(filePath);
          }
          break;
      }

      if (!mounted) return;

      // 刷新相册
      Provider.of<PhotoProvider>(context, listen: false).loadPhotos();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${prefix}已保存'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 100,
            left: 20,
            right: 20,
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      _showError('拍照失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ====== 图片处理相关方法 ======
  Future<File> _processImage(String imagePath) async {
    if (!_cropEnabled) {
      return File(imagePath);
    }
    return _cropImage(imagePath);
  }

  Future<File> _cropImage(String imagePath) async {
    final File imageFile = File(imagePath);
    final img.Image? originalImage = img.decodeImage(await imageFile.readAsBytes());

    if (originalImage == null) throw Exception('Failed to load image');

    final size = MediaQuery.of(context).size;
    final double scale = originalImage.width / size.width;

    int x = (_cropBoxPosition.dx * scale).round();
    int y = (_cropBoxPosition.dy * scale).round();
    int width = (_cropBoxSize * scale).round();
    int height = (_cropBoxSize * scale).round();

    x = x.clamp(0, originalImage.width - width);
    y = y.clamp(0, originalImage.height - height);
    width = width.clamp(1, originalImage.width - x);
    height = height.clamp(1, originalImage.height - y);

    final img.Image croppedImage = img.copyCrop(
      originalImage,
      x: x,
      y: y,
      width: width,
      height: height,
    );

    final String croppedPath = imagePath.replaceAll('.jpg', '_cropped.jpg');
    final File croppedFile = File(croppedPath);
    await croppedFile.writeAsBytes(img.encodeJpg(croppedImage, quality: 100));

    await imageFile.delete();

    return croppedFile;
  }

  // ====== 缩放相关方法 ======
  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentZoom;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (!_isInitialized || _controller == null) return;

    double scale = (_baseScale * details.scale).clamp(
      _minAvailableZoom,
      _maxAvailableZoom,
    );

    if (scale != _currentZoom) {
      try {
        await _controller!.setZoomLevel(scale);
        if (mounted) {
          setState(() => _currentZoom = scale);
        }
      } catch (e) {
        print('设置缩放失败: $e');
      }
    }
  }

  // ====== 对焦相关方法 ======
  Future<void> _handleTapUp(TapUpDetails details) async {
    if (!_isInitialized || _controller == null) return;

    final Offset tapPosition = details.localPosition;
    final Size previewSize = MediaQuery.of(context).size;

    final double x = tapPosition.dx.clamp(0.0, previewSize.width);
    final double y = tapPosition.dy.clamp(0.0, previewSize.height);

    setState(() {
      _focusPoint = Offset(x, y);
      _showFocusCircle = true;
    });

    try {
      await _controller!.setFocusPoint(
        Offset(x / previewSize.width, y / previewSize.height),
      );
      await _controller!.setExposurePoint(
        Offset(x / previewSize.width, y / previewSize.height),
      );
    } catch (e) {
      print('设置对焦点失败: $e');
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showFocusCircle = false);
      }
    });
  }

// ====== 裁剪框相关方法（续） ======
  void _handleCropBoxTapDown(TapDownDetails details) {
    final Offset localPosition = details.localPosition;
    final Rect cropBoxRect = Rect.fromLTWH(
      _cropBoxPosition.dx,
      _cropBoxPosition.dy,
      _cropBoxSize,
      _cropBoxSize,
    );

    final double handleSize = 44.0;
    final Rect resizeHandle = Rect.fromLTWH(
      cropBoxRect.right - handleSize,
      cropBoxRect.bottom - handleSize,
      handleSize,
      handleSize,
    );

    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!) < _doubleTapDuration) {
      if (cropBoxRect.contains(localPosition)) {
        if (_cropBoxSize < _maxCropBoxSize) {
          setState(() {
            final oldSize = _cropBoxSize;
            _cropBoxSize = (_cropBoxSize * 1.5).clamp(_minCropBoxSize, _maxCropBoxSize);

            final scale = _cropBoxSize / oldSize;
            final relativeX = (localPosition.dx - _cropBoxPosition.dx) / oldSize;
            final relativeY = (localPosition.dy - _cropBoxPosition.dy) / oldSize;

            _cropBoxPosition = Offset(
              localPosition.dx - (_cropBoxSize * relativeX),
              localPosition.dy - (_cropBoxSize * relativeY),
            );
          });
        } else {
          setState(() {
            _cropBoxSize = 200.0;
            _cropBoxPosition = Offset(
              (MediaQuery.of(context).size.width - _cropBoxSize) / 2,
              (MediaQuery.of(context).size.height - _cropBoxSize) / 2,
            );
          });
        }
      }
    } else if (resizeHandle.contains(localPosition)) {
      setState(() => _isResizingCropBox = true);
    } else if (cropBoxRect.contains(localPosition)) {
      setState(() => _isDraggingCropBox = true);
    }

    _lastTapTime = now;
  }

  void _handleCropBoxPanStart(DragStartDetails details) {
    final Offset localPosition = details.localPosition;
    final Rect cropBoxRect = Rect.fromLTWH(
      _cropBoxPosition.dx,
      _cropBoxPosition.dy,
      _cropBoxSize,
      _cropBoxSize,
    );

    final double handleSize = 44.0;
    final Rect resizeHandle = Rect.fromLTWH(
      cropBoxRect.right - handleSize,
      cropBoxRect.bottom - handleSize,
      handleSize,
      handleSize,
    );

    if (resizeHandle.contains(localPosition)) {
      setState(() => _isResizingCropBox = true);
    } else if (cropBoxRect.contains(localPosition)) {
      setState(() => _isDraggingCropBox = true);
    }
  }

  void _handleCropBoxPanUpdate(DragUpdateDetails details) {
    if (_isResizingCropBox) {
      setState(() {
        final newSize = (_cropBoxSize + details.delta.dx).clamp(_minCropBoxSize, _maxCropBoxSize);
        if (newSize != _cropBoxSize) {
          _cropBoxSize = newSize;
        }
      });
    } else if (_isDraggingCropBox) {
      setState(() {
        final newPosition = _cropBoxPosition + details.delta;
        final screenSize = MediaQuery.of(context).size;

        _cropBoxPosition = Offset(
          newPosition.dx.clamp(0, screenSize.width - _cropBoxSize),
          newPosition.dy.clamp(0, screenSize.height - _cropBoxSize),
        );
      });
    }
  }

  void _handleCropBoxPanEnd(DragEndDetails details) {
    setState(() {
      _isDraggingCropBox = false;
      _isResizingCropBox = false;
    });
  }

  // ====== 相机切换方法 ======
  Future<void> _switchCamera() async {
    if (_cameras.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('没有其他可用的相机'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isInitialized = false;
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    });

    try {
      await _initializeCamera();
    } catch (e) {
      print('切换相机失败: $e');
      _showError('切换相机失败');
    }
  }

  // ====== 页面导航方法 ======
  Future<void> _navigateToScreen(Widget screen) async {
    await _disposeCamera();
    if (!mounted) return;

    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    await _initializeAll();
  }

  // ====== 错误提示方法 ======
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: '重试',
          textColor: Colors.white,
          onPressed: _initializeCamera,
        ),
      ),
    );
  }

  // ====== UI构建方法 ======
  Widget _buildCaptureButton(PhotoMode mode, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: FloatingActionButton(
            backgroundColor: Colors.white.withOpacity(0.2),
            elevation: 0,
            onPressed: _isProcessing ? null : () => _takePicture(mode),
            child: _isProcessing
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
                : Container(
              margin: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCameraControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 30,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCaptureButton(PhotoMode.start, '起始点'),
            _buildCaptureButton(PhotoMode.middle, '中间点'),
            _buildCaptureButton(PhotoMode.model, '模型点'),
            _buildCaptureButton(PhotoMode.end, '结束点'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('相机'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToScreen(const SettingsScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () => _navigateToScreen(const GalleryScreen()),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 相机预览
          if (_isInitialized && _controller != null)
            GestureDetector(
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onTapUp: _handleTapUp,
              child: CameraPreview(_controller!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // 裁剪框
          if (_isInitialized && _cropEnabled)
            Positioned.fill(
              child: GestureDetector(
                onPanStart: _handleCropBoxPanStart,
                onPanUpdate: _handleCropBoxPanUpdate,
                onPanEnd: _handleCropBoxPanEnd,
                onTapDown: _handleCropBoxTapDown,
                child: CustomPaint(
                  painter: CropBoxPainter(
                    cropBoxPosition: _cropBoxPosition,
                    cropBoxSize: _cropBoxSize,
                  ),
                ),
              ),
            ),

          // 中心点指示器
          if (_isInitialized && _showCenterPoint)
            const Positioned.fill(
              child: CustomPaint(
                painter: CenterPointPainter(),
              ),
            ),

          // 对焦点
          if (_showFocusCircle && _focusPoint != null)
            Positioned(
              left: _focusPoint!.dx - 20,
              top: _focusPoint!.dy - 20,
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  shape: BoxShape.circle,
                ),
              ),
            ),

          // 相机控制按钮
          if (_isInitialized)
            _buildCameraControls(),
        ],
      ),
    );
  }
}

// ====== 自定义画笔 ======
// 裁剪框绘制器
class CropBoxPainter extends CustomPainter {
  final Offset cropBoxPosition;
  final double cropBoxSize;

  const CropBoxPainter({
    required this.cropBoxPosition,
    required this.cropBoxSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 绘制裁剪框
    final Rect cropRect = Rect.fromLTWH(
      cropBoxPosition.dx,
      cropBoxPosition.dy,
      cropBoxSize,
      cropBoxSize,
    );
    canvas.drawRect(cropRect, paint);

    // 绘制中心点
    final Paint centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      cropRect.center,
      4.0,
      centerPaint,
    );

    // 绘制调整大小的手柄
    final Paint handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(cropRect.right, cropRect.bottom),
      10.0,
      handlePaint,
    );

    // 绘制网格线
    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 垂直线
    for (int i = 1; i < 3; i++) {
      final double x = cropRect.left + (cropRect.width / 3) * i;
      canvas.drawLine(
        Offset(x, cropRect.top),
        Offset(x, cropRect.bottom),
        gridPaint,
      );
    }

    // 水平线
    for (int i = 1; i < 3; i++) {
      final double y = cropRect.top + (cropRect.height / 3) * i;
      canvas.drawLine(
        Offset(cropRect.left, y),
        Offset(cropRect.right, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CropBoxPainter oldDelegate) {
    return cropBoxPosition != oldDelegate.cropBoxPosition ||
        cropBoxSize != oldDelegate.cropBoxSize;
  }
}

// 中心点绘制器
class CenterPointPainter extends CustomPainter {
  const CenterPointPainter();  // 添加 const 构造函数
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    const crossSize = 20.0;

    // 绘制十字准星
    canvas.drawLine(
      Offset(center.dx - crossSize, center.dy),
      Offset(center.dx + crossSize, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - crossSize),
      Offset(center.dx, center.dy + crossSize),
      paint,
    );

    // 绘制圆圈
    canvas.drawCircle(center, crossSize * 1.5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}