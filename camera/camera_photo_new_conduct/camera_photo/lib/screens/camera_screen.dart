// lib/screens/camera_screen.dart

import 'dart:io';
import 'package:camera_photo/models/project.dart';
import 'package:camera_photo/providers/project_provider.dart';
import 'package:camera_photo/utils/photo_utils.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../utils/settings_manager.dart';
import '../providers/photo_provider.dart';

// 拍照模式枚举
enum PhotoMode {
  start, // 起始点拍照
  middle, // 中间点拍照
  model, // 模型点拍照
  end, // 结束点拍照
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

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
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

  // 项目和轨迹相关变量
  Project? currentProject;
  Track? currentTrack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 使用 Future.microtask 来确保在构建完成后初始化
    Future.microtask(() {
      // 获取当前项目和轨迹状态
      final projectProvider =
          Provider.of<ProjectProvider>(context, listen: false);
      setState(() {
        currentProject = projectProvider.currentProject;
        currentTrack = projectProvider.currentTrack;
      });

      // 加载照片
      if (currentProject != null) {
        final photoProvider =
            Provider.of<PhotoProvider>(context, listen: false);
        final path = currentTrack?.path ?? currentProject!.path;
        photoProvider.loadPhotosForProjectOrTrack(path);
      }

      // 初始化相机
      _initializeAll();
    });
  }

  @override
  void dispose() {
    // 在页面销毁时刷新项目列表
    Future.microtask(() =>
        Provider.of<ProjectProvider>(context, listen: false).initialize());
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

      // 获取保存的分辨率设置
      final savedResolution = await SettingsManager.getResolutionPreset();
      print(
          'Initializing camera with resolution: ${savedResolution.toString()}');

      CameraController cameraController = CameraController(
        _cameras[_currentCameraIndex],
        _currentResolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      //imageFormatGroup: ImageFormatGroup.jpeg,
      // final CameraController cameraController = CameraController(
      //   cameraDescription,
      //   ResolutionPreset.max,
      //   enableAudio: false,
      // );

      _controller = cameraController;

      await cameraController.initialize();

      // 打印当前相机配置
      // 打印当前相机配置
      print('Camera description: ${_cameras[_currentCameraIndex].toString()}');
      print('Current resolution preset: ${savedResolution.toString()}');

      if (cameraController.value.isInitialized) {
        final size = cameraController.value.previewSize;
        if (size != null) {
          print('Preview size: ${size.width}x${size.height}');
        }
      }

      await cameraController.setFlashMode(FlashMode.off);

      _maxAvailableZoom = await cameraController.getMaxZoomLevel();
      _minAvailableZoom = await cameraController.getMinZoomLevel();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _currentZoom = 1.0;
          _retryCount = 0;
          _currentResolution = savedResolution;
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
      startPhotos
          .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      // 删除多余的照片
      for (int i = 1; i < startPhotos.length; i++) {
        await startPhotos[i].delete();
      }
    }

    // 处理重复的结束点照片
    final endPhotos = _findPhotosOfType(photos, END_PHOTO);
    if (endPhotos.length > 1) {
      // 按修改时间排序，保留最新的
      endPhotos
          .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      // 删除多余的照片
      for (int i = 1; i < endPhotos.length; i++) {
        await endPhotos[i].delete();
      }
    }
  }

  // ====== 照片处理方法 ======

  Future<void> _handleStartPointPhoto(String sourcePath, String savePath,
      String timestamp, List<File> existingPhotos) async {
    try {
      // 查找现有的起始点照片
      final startPhotos = existingPhotos
          .where((p) => PhotoUtils.getPhotoType(p.path) == PhotoUtils.START_PHOTO)
          .toList();
      
      int sequence;
      if (startPhotos.isEmpty) {
        // 如果没有起始点照片，使用序号1
        sequence = 1;
      } else {
        // 找到最大序号并加1
        startPhotos.sort((a, b) => 
          PhotoUtils.getPhotoSequence(a.path).compareTo(
            PhotoUtils.getPhotoSequence(b.path)
          )
        );
        sequence = PhotoUtils.getPhotoSequence(startPhotos.last.path) + 1;
      }

      // 生成新文件名
      final String filename =
          PhotoUtils.generateFileName(PhotoUtils.START_PHOTO, sequence, timestamp);
      final String newPath = path.join(savePath, filename);
      await File(sourcePath).copy(newPath);
      
      // 不需要重新排序，只需要重新加载照片列表
      // 因为我们已经确保了照片的命名和排序规则
    } catch (e) {
      print('处理起始点照片失败: $e');
      rethrow;
    }
  }

  Future<void> _handleMiddlePointPhoto(String sourcePath, String savePath,
      String timestamp, List<File> existingPhotos) async {
    try {
      // 查找现有的中间点照片
      final middlePhotos = existingPhotos
          .where((p) => PhotoUtils.getPhotoType(p.path) == PhotoUtils.MIDDLE_PHOTO)
          .toList();
      
      int sequence;
      if (middlePhotos.isEmpty) {
        // 如果没有中间点照片，使用序号1
        sequence = 1;
      } else {
        // 找到最大序号并加1
        middlePhotos.sort((a, b) => 
          PhotoUtils.getPhotoSequence(a.path).compareTo(
            PhotoUtils.getPhotoSequence(b.path)
          )
        );
        sequence = PhotoUtils.getPhotoSequence(middlePhotos.last.path) + 1;
      }

      final String filename = PhotoUtils.generateFileName(
          PhotoUtils.MIDDLE_PHOTO, sequence, timestamp);
      final String newPath = path.join(savePath, filename);
      await File(sourcePath).copy(newPath);
      
      // 不需要重新排序，只需要重新加载照片列表
    } catch (e) {
      print('处理中间点照片失败: $e');
      rethrow;
    }
  }

  Future<void> _handleModelPointPhoto(String sourcePath, String savePath,
      String timestamp, List<File> existingPhotos) async {
    try {
      // 查找现有的模型点照片
      final modelPhotos = existingPhotos
          .where((p) => PhotoUtils.getPhotoType(p.path) == PhotoUtils.MODEL_PHOTO)
          .toList();
      
      int sequence;
      if (modelPhotos.isEmpty) {
        // 如果没有模型点照片，使用序号1
        sequence = 1;
      } else {
        // 找到最大序号并加1
        modelPhotos.sort((a, b) => 
          PhotoUtils.getPhotoSequence(a.path).compareTo(
            PhotoUtils.getPhotoSequence(b.path)
          )
        );
        sequence = PhotoUtils.getPhotoSequence(modelPhotos.last.path) + 1;
      }

      final String filename = PhotoUtils.generateFileName(
          PhotoUtils.MODEL_PHOTO, sequence, timestamp);
      final String newPath = path.join(savePath, filename);
      await File(sourcePath).copy(newPath);
      
      // 不需要重新排序，只需要重新加载照片列表
    } catch (e) {
      print('处理模型点照片失败: $e');
      rethrow;
    }
  }

  Future<void> _handleEndPointPhoto(String sourcePath, String savePath,
      String timestamp, List<File> existingPhotos) async {
    try {
      // 查找现有的结束点照片
      final endPhotos = existingPhotos
          .where((p) => PhotoUtils.getPhotoType(p.path) == PhotoUtils.END_PHOTO)
          .toList();
      
      int sequence;
      if (endPhotos.isEmpty) {
        // 如果没有结束点照片，使用序号1
        sequence = 1;
      } else {
        // 找到最大序号并加1
        endPhotos.sort((a, b) => 
          PhotoUtils.getPhotoSequence(a.path).compareTo(
            PhotoUtils.getPhotoSequence(b.path)
          )
        );
        sequence = PhotoUtils.getPhotoSequence(endPhotos.last.path) + 1;
      }

      // 生成新文件名
      final String filename =
          PhotoUtils.generateFileName(PhotoUtils.END_PHOTO, sequence, timestamp);
      final String newPath = path.join(savePath, filename);
      await File(sourcePath).copy(newPath);
      
      // 不需要重新排序，只需要重新加载照片列表
    } catch (e) {
      print('处理结束点照片失败: $e');
      rethrow;
    }
  }
  
  // 辅助方法：加载目录中的所有照片
  Future<List<File>> _loadAllPhotos(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      return [];
    }
    
    final List<File> photos = [];
    await for (var entity in dir.list(recursive: false)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.jpg')) {
        photos.add(entity);
      }
    }
    return photos;
  }

  // 处理图片的辅助方法
  Future<void> _processImage(String imagePath) async {
    if (!_cropEnabled) return;

    try {
      File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        File croppedFile = await _cropImage(imagePath);
        if (await croppedFile.exists()) {
          // 如果裁剪成功，用裁剪后的图片替换原图
          await imageFile.delete();
          await croppedFile.copy(imagePath);
          await croppedFile.delete();
        }
      }
    } catch (e) {
      print('处理图片失败: $e');
    }
  }

  Future<File> _cropImage(String imagePath) async {
    final File imageFile = File(imagePath);
    final img.Image? originalImage =
        img.decodeImage(await imageFile.readAsBytes());

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

  // 修改拍照方法
  Future<void> _takePicture(PhotoMode photoMode) async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final XFile photo = await _controller!.takePicture();

      if (currentProject == null) {
        throw Exception('未选择项目');
      }

      final String savePath = currentTrack?.path ?? currentProject!.path;
      final DateTime now = DateTime.now();
      final String timestamp =
          "${now.year}${now.month.toString().padLeft(2, '0')}"
          "${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}"
          "${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";

      final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
      await photoProvider.loadPhotosForProjectOrTrack(savePath);
      final existingPhotos = photoProvider.photos;

      // 根据模式处理照片
      switch (photoMode) {
        case PhotoMode.start:
          await _handleStartPointPhoto(
              photo.path, savePath, timestamp, existingPhotos);
          break;
        case PhotoMode.middle:
          await _handleMiddlePointPhoto(
              photo.path, savePath, timestamp, existingPhotos);
          break;
        case PhotoMode.model:
          await _handleModelPointPhoto(
              photo.path, savePath, timestamp, existingPhotos);
          break;
        case PhotoMode.end:
          await _handleEndPointPhoto(
              photo.path, savePath, timestamp, existingPhotos);
          break;
      }

      // 强制重新加载照片列表
      await photoProvider.forceReloadPhotos();

      // 重新加载项目数据
      final projectProvider =
          Provider.of<ProjectProvider>(context, listen: false);
      await projectProvider.initialize();

      // 显示提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_getModePrefix(photoMode)}已保存')),
        );
      }
    } catch (e) {
      print('拍照失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拍照失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // 修改按钮构建方法以显示正确的标签
  Widget _buildCaptureButtons() {
    return Container(
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
    );
  }

  // ====== 辅助方法 ======
  String _getModePrefix(PhotoMode mode) {
    switch (mode) {
      case PhotoMode.start:
        return PhotoUtils.START_PHOTO;
      case PhotoMode.middle:
        return PhotoUtils.MIDDLE_PHOTO;
      case PhotoMode.model:
        return PhotoUtils.MODEL_PHOTO;
      case PhotoMode.end:
        return PhotoUtils.END_PHOTO;
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
// 修改拍照按钮的构建方法

  // 修改拍照按钮构建方法
  Widget _buildCaptureButton(PhotoMode mode, String label) {
    final bool isEnabled = _isButtonEnabled(mode);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.3,
      child: Column(
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
              onPressed: (_isProcessing || !isEnabled)
                  ? null
                  : () => _takePicture(mode),
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
      ),
    );
  }

  // ====== 导航方法 ======
  Future<void> _navigateToScreen(Widget screen) async {
    await _disposeCamera();
    if (!mounted) return;

    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

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

  // 裁剪框相关方法
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
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < _doubleTapDuration) {
      if (cropBoxRect.contains(localPosition)) {
        if (_cropBoxSize < _maxCropBoxSize) {
          setState(() {
            final oldSize = _cropBoxSize;
            _cropBoxSize =
                (_cropBoxSize * 1.5).clamp(_minCropBoxSize, _maxCropBoxSize);

            final scale = _cropBoxSize / oldSize;
            final relativeX =
                (localPosition.dx - _cropBoxPosition.dx) / oldSize;
            final relativeY =
                (localPosition.dy - _cropBoxPosition.dy) / oldSize;

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
        final newSize = (_cropBoxSize + details.delta.dx)
            .clamp(_minCropBoxSize, _maxCropBoxSize);
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

  Widget _buildResolutionIndicator() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          SettingsManager.resolutionPresetToString(_currentResolution),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // 修改按钮启用状态检查
  bool _isButtonEnabled(PhotoMode mode) {
    // 如果项目未初始化，禁用所有按钮
    if (currentProject == null) return false;

    if (currentTrack == null) {
      // 项目模式：只允许模型点拍照
      return mode == PhotoMode.model;
    } else {
      // 轨迹模式：允许除模型点外的所有类型
      return mode != PhotoMode.model;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(currentTrack != null ? '轨迹拍照' : '项目拍照'),
        foregroundColor: Colors.white,
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

          // 根据设置显示裁剪框
          if (false)
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
          // 显示分辨率指示器
          if (_isInitialized) _buildResolutionIndicator(),
          // 中心点指示器
          if (_isInitialized && _showCenterPoint)
            const Positioned.fill(
              child: CustomPaint(
                painter: CenterPointPainter(),
              ),
            ),

          // 拍照按钮
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

// 在 camera_screen.dart 文件底部添加此类

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
