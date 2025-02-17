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

// 照片类型定义
const String START_PHOTO = '起始点拍照';
const String MIDDLE_PHOTO = '中间点拍照';
const String MODEL_PHOTO = '模型点拍照';
const String END_PHOTO = '结束点拍照';

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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
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

  // ====== 初始化方法 ======
  Future<void> _initializeAll() async {
    await _loadSettings();
    await _loadCameras();
  }

  // ====== 基础设置和初始化方法 ======
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

  // ====== 照片类型检查和查找方法 ======
  bool _isPhotoOfType(String filePath, String type) {
    return path.basename(filePath).toLowerCase().startsWith(type.toLowerCase());
  }

  List<File> _findPhotosOfType(List<File> photos, String type) {
    return photos.where((photo) => _isPhotoOfType(photo.path, type)).toList();
  }

  // ====== 照片排序和管理方法 ======
  Future<void> _organizePhotos(List<File> photos) async {
    // 处理重复的起始点照片
    final startPhotos = _findPhotosOfType(photos, START_PHOTO);
    if (startPhotos.length > 1) {
      // 按修改时间排序，保留最新的
      startPhotos.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      // 删除多余的照片
      for (int i = 1; i < startPhotos.length; i++) {
        await startPhotos[i].delete();
      }
    }

    // 处理重复的结束点照片
    final endPhotos = _findPhotosOfType(photos, END_PHOTO);
    if (endPhotos.length > 1) {
      // 按修改时间排序，保留最新的
      endPhotos.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      // 删除多余的照片
      for (int i = 1; i < endPhotos.length; i++) {
        await endPhotos[i].delete();
      }
    }
  }

  // ====== 照片处理方法 ======
  Future<void> _handleStartPointPhoto(XFile photo, Directory appDir, String timestamp, List<File> photos) async {
    final String filename = '${START_PHOTO}_$timestamp.jpg';
    final String filePath = path.join(appDir.path, filename);

    try {
      // 找出所有起始点照片
      final startPhotos = _findPhotosOfType(photos, START_PHOTO);

      // 删除已存在的起始点照片
      for (var startPhoto in startPhotos) {
        await startPhoto.delete();
      }

      // 保存新的起始点照片
      final File originalImage = File(filePath);
      await originalImage.writeAsBytes(await File(photo.path).readAsBytes());
      await _processImage(filePath);
    } catch (e) {
      print('处理起始点照片失败: $e');
      rethrow;
    }
  }

  Future<void> _handleMiddlePointPhoto(XFile photo, Directory appDir, String timestamp, List<File> photos) async {
    final String filename = '${MIDDLE_PHOTO}_$timestamp.jpg';
    final String filePath = path.join(appDir.path, filename);

    try {
      // 获取起始点和结束点照片
      final startPhotos = _findPhotosOfType(photos, START_PHOTO);
      final endPhotos = _findPhotosOfType(photos, END_PHOTO);

      // 保存照片
      final File originalImage = File(filePath);
      await originalImage.writeAsBytes(await File(photo.path).readAsBytes());
      await _processImage(filePath);
    } catch (e) {
      print('处理中间点照片失败: $e');
      rethrow;
    }
  }

  Future<void> _handleModelPointPhoto(XFile photo, Directory appDir, String timestamp, List<File> photos) async {
    final String filename = '${MODEL_PHOTO}_$timestamp.jpg';
    final String filePath = path.join(appDir.path, filename);

    try {
      // 获取起始点和结束点照片
      final startPhotos = _findPhotosOfType(photos, START_PHOTO);
      final endPhotos = _findPhotosOfType(photos, END_PHOTO);

      // 保存照片
      final File originalImage = File(filePath);
      await originalImage.writeAsBytes(await File(photo.path).readAsBytes());
      await _processImage(filePath);
    } catch (e) {
      print('处理模型点照片失败: $e');
      rethrow;
    }
  }

  Future<void> _handleEndPointPhoto(XFile photo, Directory appDir, String timestamp, List<File> photos) async {
    final String filename = '${END_PHOTO}_$timestamp.jpg';
    final String filePath = path.join(appDir.path, filename);

    try {
      // 找出所有结束点照片
      final endPhotos = _findPhotosOfType(photos, END_PHOTO);

      // 删除已存在的结束点照片
      for (var endPhoto in endPhotos) {
        await endPhoto.delete();
      }

      // 保存新的结束点照片
      final File originalImage = File(filePath);
      await originalImage.writeAsBytes(await File(photo.path).readAsBytes());
      await _processImage(filePath);
    } catch (e) {
      print('处理结束点照片失败: $e');
      rethrow;
    }
  }

  // ====== 图片处理方法 ======
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

  // ====== 主拍照方法 ======
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

      // 获取和整理当前照片列表
      final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
      await photoProvider.loadPhotos();
      final photos = photoProvider.photos;

      // 处理和整理现有照片
      await _organizePhotos(photos);

      // 根据模式处理照片
      switch (mode) {
        case PhotoMode.start:
          await _handleStartPointPhoto(photo, appDir, timestamp, photos);
          break;

        case PhotoMode.middle:
          await _handleMiddlePointPhoto(photo, appDir, timestamp, photos);
          break;

        case PhotoMode.model:
          await _handleModelPointPhoto(photo, appDir, timestamp, photos);
          break;

        case PhotoMode.end:
          await _handleEndPointPhoto(photo, appDir, timestamp, photos);
          break;
      }

      if (!mounted) return;

      // 刷新相册
      await photoProvider.loadPhotos();

      // 再次整理照片确保顺序正确
      await _organizePhotos(photoProvider.photos);

      // 显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getModePrefix(mode)}已保存'),
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
      print('拍照失败: $e');
      _showError('拍照失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ====== 辅助方法 ======
  String _getModePrefix(PhotoMode mode) {
    switch (mode) {
      case PhotoMode.start:
        return START_PHOTO;
      case PhotoMode.middle:
        return MIDDLE_PHOTO;
      case PhotoMode.model:
        return MODEL_PHOTO;
      case PhotoMode.end:
        return END_PHOTO;
    }
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

  // ====== UI 构建方法 ======
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

  // ====== 导航方法 ======
  Future<void> _navigateToScreen(Widget screen) async {
    await _disposeCamera();
    if (!mounted) return;

    await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen)
    );

    // 返回后重新初始化相机
    await _initializeAll();
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

          // 中心点指示器
          if (_isInitialized && _showCenterPoint)
            const Positioned.fill(
              child: CustomPaint(
                painter: CenterPointPainter(),
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
                    _buildCaptureButton(PhotoMode.start, '起始点'),
                    _buildCaptureButton(PhotoMode.middle, '中间点'),
                    _buildCaptureButton(PhotoMode.model, '模型点'),
                    _buildCaptureButton(PhotoMode.end, '结束点'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ====== 自定义画笔 ======
class CenterPointPainter extends CustomPainter {
  const CenterPointPainter();

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