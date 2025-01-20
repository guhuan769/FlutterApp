import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
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

  Future<void> _loadCameras() async {
    try {
      _cameras = await availableCameras();
      _initializeCamera();
    } catch (e) {
      print('加载相机列表失败: $e');
      _showError('无法加载相机列表');
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted || _cameras.isEmpty) return;

    try {
      await _disposeCamera();

      final CameraController cameraController = CameraController(
        _cameras[_currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = cameraController;

      cameraController.addListener(() {
        if (mounted && _controller != null && _controller!.value.hasError) {
          print('Camera error ${_controller!.value.errorDescription}');
          _retryInitialize();
        }
      });

      await cameraController.initialize();

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

      final File newImage = File(filePath);
      await newImage.writeAsBytes(await File(photo.path).readAsBytes());

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

  Future<void> _navigateToScreen(Widget screen) async {
    await _disposeCamera();
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _initializeCamera();
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    '正在初始化相机...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          if (_isInitialized) Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
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
                  ),
                  Container(
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
                  ),
                  Container(
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
                      onPressed: _switchCamera,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isInitialized && _currentZoom > 1.0)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentZoom.toStringAsFixed(1)}x',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          if (_showFocusCircle && _focusPoint != null)
            Positioned(
              left: _focusPoint!.dx - 20,
              top: _focusPoint!.dy - 20,
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.yellow,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}