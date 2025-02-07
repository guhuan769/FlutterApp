import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../providers/photo_provider.dart';
import 'gallery_screen.dart';
import 'settings_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseScale = 1.0;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;

  // 裁剪框相关变量
  double _cropBoxSize = 200.0;
  final double _minCropBoxSize = 100.0;
  final double _maxCropBoxSize = 500.0;
  Offset _cropBoxPosition = Offset.zero;
  bool _isDraggingCropBox = false;
  bool _isResizingCropBox = false;
  DateTime? _lastTapTime;
  final Duration _doubleTapDuration = const Duration(milliseconds: 300);

  Offset? _focusPoint;
  bool _showFocusCircle = false;
  int _retryCount = 0;
  final int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCameras();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 初始化裁剪框位置到屏幕中心
    if (_cropBoxPosition == Offset.zero) {
      final size = MediaQuery.of(context).size;
      _cropBoxPosition = Offset(
        (size.width - _cropBoxSize) / 2,
        (size.height - _cropBoxSize) / 2,
      );
    }
  }

  Future<void> _loadCameras() async {
    try {
      _cameras = await availableCameras();
      _initializeCamera();
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
        ResolutionPreset.max, // 使用最高分辨率
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = cameraController;

      // 设置相机参数
      await cameraController.initialize();
      await cameraController.setFlashMode(FlashMode.off);

      // 获取缩放范围
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

  Future<File> _cropImage(String imagePath) async {
    // 读取原始图片
    final File imageFile = File(imagePath);
    final img.Image? originalImage = img.decodeImage(await imageFile.readAsBytes());

    if (originalImage == null) throw Exception('Failed to load image');

    // 计算裁剪区域
    final size = MediaQuery.of(context).size;
    final double scale = originalImage.width / size.width;

    int x = (_cropBoxPosition.dx * scale).round();
    int y = (_cropBoxPosition.dy * scale).round();
    int width = (_cropBoxSize * scale).round();
    int height = (_cropBoxSize * scale).round();

    // 确保裁剪区域在图片范围内
    x = x.clamp(0, originalImage.width - width);
    y = y.clamp(0, originalImage.height - height);
    width = width.clamp(1, originalImage.width - x);
    height = height.clamp(1, originalImage.height - y);

    // 裁剪图片
    final img.Image croppedImage = img.copyCrop(
      originalImage,
      x: x,
      y: y,
      width: width,
      height: height,
    );

    // 保存裁剪后的图片
    final String croppedPath = imagePath.replaceAll('.jpg', '_cropped.jpg');
    final File croppedFile = File(croppedPath);
    await croppedFile.writeAsBytes(img.encodeJpg(croppedImage, quality: 100));

    // 删除原始图片
    await imageFile.delete();

    return croppedFile;
  }

  Future<void> _takePicture() async {
    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final XFile photo = await controller.takePicture();

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = path.join(appDir.path, '$timestamp.jpg');

      // 保存原始图片
      final File originalImage = File(filePath);
      await originalImage.writeAsBytes(await File(photo.path).readAsBytes());

      // 裁剪图片
      final File croppedImage = await _cropImage(filePath);

      if (!mounted) return;

      Provider.of<PhotoProvider>(context, listen: false).loadPhotos();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('照片已保存'),
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

  // 裁剪框手势处理
  void _handleCropBoxPanStart(DragStartDetails details) {
    final Offset localPosition = details.localPosition;
    final Rect cropBoxRect = Rect.fromLTWH(
      _cropBoxPosition.dx,
      _cropBoxPosition.dy,
      _cropBoxSize,
      _cropBoxSize,
    );

    // 检查是否在调整大小的区域
    final double handleSize = 44.0; // 调整大小手柄的区域
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
      // 调整大小
      setState(() {
        _cropBoxSize = (_cropBoxSize + details.delta.dx)
            .clamp(_minCropBoxSize, _maxCropBoxSize);
      });
    } else if (_isDraggingCropBox) {
      // 移动位置
      setState(() {
        _cropBoxPosition += details.delta;
      });
    }
  }

  void _handleCropBoxPanEnd(DragEndDetails details) {
    setState(() {
      _isDraggingCropBox = false;
      _isResizingCropBox = false;
    });
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
          if (_isInitialized)
            Positioned.fill(
              child: GestureDetector(
                onPanStart: _handleCropBoxPanStart,
                onPanUpdate: _handleCropBoxPanUpdate,
                onPanEnd: _handleCropBoxPanEnd,
                child: CustomPaint(
                  painter: CropBoxPainter(
                    cropBoxPosition: _cropBoxPosition,
                    cropBoxSize: _cropBoxSize,
                  ),
                ),
              ),
            ),

          // 相机控制按钮
          if (_isInitialized)
            Positioned(
              left: 0,
              right: 0,
              bottom: 30,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildGalleryButton(),
                    _buildCaptureButton(),
                    _buildCameraSwitchButton(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

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

  Future<void> _navigateToScreen(Widget screen) async {
    await _disposeCamera();
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _initializeCamera();
  }

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

  Widget _buildGalleryButton() {
    return GestureDetector(
      onTap: () => _navigateToScreen(const GalleryScreen()),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Consumer<PhotoProvider>(
          builder: (context, provider, _) {
            if (provider.photos.isEmpty) {
              return const Icon(
                Icons.photo_library,
                color: Colors.white,
                size: 20,
              );
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                provider.photos.first,
                fit: BoxFit.cover,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 4,
        ),
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.white.withOpacity(0.2),
        elevation: 0,
        onPressed: _isProcessing ? null : _takePicture,
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
    );
  }

  Widget _buildCameraSwitchButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black38,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.flip_camera_ios,
          color: Colors.white,
          size: 20,
        ),
        onPressed: _cameras.length <= 1 ? null : _switchCamera,
      ),
    );
  }

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
    // );
  }
}

// 裁剪框绘制器
class CropBoxPainter extends CustomPainter {
  final Offset cropBoxPosition;
  final double cropBoxSize;

  CropBoxPainter({
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