// lib/screens/camera_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';
import 'gallery_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.high);
    await _controller!.initialize();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) return;

    try {
      // 拍照并获取XFile对象
      final XFile photo = await _controller!.takePicture();

      // 获取应用文档目录
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = path.join(appDir.path, '$timestamp.jpg');

      // 创建File对象并复制照片
      final File newImage = File(filePath);
      await newImage.writeAsBytes(await File(photo.path).readAsBytes());

      // 刷新图片列表
      if (mounted) {
        Provider.of<PhotoProvider>(context, listen: false).loadPhotos();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('照片已保存')),
        );
      }
    } catch (e) {
      print('拍照错误: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拍照失败: $e')),
        );
      }
    }
  }

  // Future<void> _takePicture() async {
  //   if (!_controller!.value.isInitialized) return;
  //
  //   final Directory appDir = await getApplicationDocumentsDirectory();
  //   final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  //   final String filePath = path.join(appDir.path, '$timestamp.jpg');
  //
  //   try {
  //     await _controller!.takePicture();
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Photo captured!')),
  //     );
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GalleryScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: FloatingActionButton(
                onPressed: _takePicture,
                child: const Icon(Icons.camera),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
