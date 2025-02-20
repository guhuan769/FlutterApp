// lib/screens/camera_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:io';
import 'preview_screen.dart';


class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isProcessing = false;
  String? _lastSavedPath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // 请求相机和存储权限
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();

    if (cameraStatus.isDenied || storageStatus.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要相机和存储权限才能使用此功能')),
      );
      return;
    }

    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.bgra8888,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller.initialize();

    await _initializeControllerFuture;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;

      final XFile image = await _controller.takePicture();

      // 保存到相册
      final result = await ImageGallerySaver.saveFile(image.path);

      if (result['isSuccess']) {
        _lastSavedPath = image.path;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('照片已保存到相册')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拍照失败: $e')),
        );
      }
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (!_isProcessing) {
      _isProcessing = true;

      try {
        // 这里处理图像数据
        final bytes = image.planes[0].bytes;
        final width = image.width;
        final height = image.height;

        // TODO: 添加你的图像处理逻辑

      } finally {
        _isProcessing = false;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('相机')),
      body: Stack(
        children: [
          CameraPreview(_controller),
          if (_lastSavedPath != null)
            Positioned(
              bottom: 100,
              right: 20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_lastSavedPath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
