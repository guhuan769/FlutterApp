// lib/screens/camera_screen.dart
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 延迟初始化相机，确保widget完全加载
    Future.microtask(_initializeCamera);
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

  Future<void> _disposeCamera() async {
    try {
      final CameraController? cameraController = _controller;
      if (cameraController != null && cameraController.value.isInitialized) {
        await cameraController.dispose();
        _controller = null;
      }
    } catch (e) {
      print('相机释放错误: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitialized = false);
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;

    try {
      await _disposeCamera();

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('no_cameras', '没有可用的相机');
      }

      final CameraController cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = cameraController;

      await cameraController.initialize();

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        _showError('相机初始化失败: $e');
      }
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

  Future<void> _navigateToScreen(Widget screen) async {
    await _disposeCamera();
    if (!mounted) return;

    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _initializeCamera();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
            CameraPreview(_controller!)
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
          if (_isInitialized)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: FloatingActionButton(
                  onPressed: _isProcessing ? null : _takePicture,
                  child: _isProcessing
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.camera),
                  backgroundColor: _isProcessing ? Colors.grey : Colors.blue,
                ),
              ),
            ),
        ],
      ),
    );
  }
}