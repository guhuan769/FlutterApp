// lib/screens/system_camera_screen.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import '../models/project.dart';
import '../providers/photo_provider.dart';
import '../providers/project_provider.dart';
import '../utils/photo_utils.dart';
import '../utils/settings_manager.dart';

class SystemCameraScreen extends StatefulWidget {
  const SystemCameraScreen({Key? key}) : super(key: key);

  @override
  State<SystemCameraScreen> createState() => _SystemCameraScreenState();
}

class _SystemCameraScreenState extends State<SystemCameraScreen> {
  final ImagePicker _picker = ImagePicker();

  // 相机设置
  double _currentResolutionQuality = 0.8; // 默认相机质量，范围0.0-1.0
  bool _isProcessing = false;
  bool _showCenterPoint = true;

  // 项目和轨迹相关变量
  Project? currentProject;
  Track? currentTrack;

  @override
  void initState() {
    super.initState();

    // 使用 Future.microtask 来确保在构建完成后初始化
    Future.microtask(() {
      // 获取当前项目和轨迹状态
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      setState(() {
        currentProject = projectProvider.currentProject;
        currentTrack = projectProvider.currentTrack;
      });

      // 加载照片
      if (currentProject != null) {
        final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
        final path = currentTrack?.path ?? currentProject!.path;
        photoProvider.loadPhotosForProjectOrTrack(path);
      }

      // 加载相机设置
      _loadCameraSettings();
    });
  }

  @override
  void dispose() {
    // 在页面销毁时刷新项目列表
    Future.microtask(() =>
        Provider.of<ProjectProvider>(context, listen: false).initialize());
    super.dispose();
  }

  // 加载相机设置
  Future<void> _loadCameraSettings() async {
    try {
      final resolution = await SettingsManager.getResolutionPreset();
      final showCenterPoint = await SettingsManager.getShowCenterPoint();

      // 根据分辨率预设转换为图像质量值 (0.0-1.0)
      double quality = 0.8; // 默认值

      switch (resolution) {
        case ResolutionPreset.low:
          quality = 0.3;
          break;
        case ResolutionPreset.medium:
          quality = 0.5;
          break;
        case ResolutionPreset.high:
          quality = 0.7;
          break;
        case ResolutionPreset.veryHigh:
          quality = 0.85;
          break;
        case ResolutionPreset.ultraHigh:
          quality = 0.95;
          break;
        case ResolutionPreset.max:
          quality = 1.0;
          break;
        default:
          quality = 0.8;
      }

      if (mounted) {
        setState(() {
          _currentResolutionQuality = quality;
          _showCenterPoint = showCenterPoint;
        });
      }
    } catch (e) {
      print('加载相机设置失败: $e');
      if (mounted) {
        _showError('加载相机设置失败');
      }
    }
  }

  // 拍照方法
  Future<void> _takePicture(String photoType) async {
    if (_isProcessing) return;

    if (currentProject == null) {
      _showError('未选择项目');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 计算图像质量，转换为0-100的整数
      final imageQuality = (_currentResolutionQuality * 100).round();
      print('使用的图像质量: $imageQuality%');

      // 使用系统相机拍照
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        preferredCameraDevice: CameraDevice.rear,
      );

      // 用户取消拍照
      if (photo == null) {
        setState(() => _isProcessing = false);
        return;
      }

      print('照片已拍摄: ${photo.path}');
      final String savePath = currentTrack?.path ?? currentProject!.path;
      final DateTime now = DateTime.now();
      final String timestamp = "${now.year}${now.month.toString().padLeft(2, '0')}"
          "${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}"
          "${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";

      final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
      await photoProvider.loadPhotosForProjectOrTrack(savePath);
      final existingPhotos = photoProvider.photos;

      // 根据照片类型处理
      if (currentTrack != null) {
        switch (photoType) {
          case PhotoUtils.START_PHOTO:
            await _handleStartPointPhoto(photo, savePath, timestamp, existingPhotos);
            break;
          case PhotoUtils.MIDDLE_PHOTO:
            await _handleMiddlePointPhoto(photo, savePath, timestamp, existingPhotos);
            break;
          case PhotoUtils.END_PHOTO:
            await _handleEndPointPhoto(photo, savePath, timestamp, existingPhotos);
            break;
          case PhotoUtils.MODEL_PHOTO:
          // 轨迹模式下不支持模型点拍照
            _showError('轨迹模式下不能拍摄模型点照片');
            break;
        }
      } else if (photoType == PhotoUtils.MODEL_PHOTO) {
        await _handleModelPointPhoto(photo, savePath, timestamp, existingPhotos);
      } else {
        _showError('项目模式下只能拍摄模型点照片');
      }

      // 强制重新加载照片列表
      await photoProvider.forceReloadPhotos();

      // 重新加载项目数据
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      await projectProvider.initialize();

      // 显示提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${photoType}已保存')),
        );
      }
    } catch (e) {
      print('拍照失败: $e');
      _showError('拍照失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // 处理起始点照片
  Future<void> _handleStartPointPhoto(XFile photo, String savePath, String timestamp, List<File> existingPhotos) async {
    try {
      // 删除现有的起始点照片
      for (var existingPhoto in existingPhotos) {
        if (PhotoUtils.getPhotoType(existingPhoto.path) == PhotoUtils.START_PHOTO) {
          await existingPhoto.delete();
        }
      }

      // 生成新文件名
      final String filename = PhotoUtils.generateFileName(PhotoUtils.START_PHOTO, 1, timestamp);
      final String newPath = path.join(savePath, filename);
      await File(photo.path).copy(newPath);
    } catch (e) {
      print('处理起始点照片失败: $e');
      rethrow;
    }
  }

  // 处理中间点照片
  Future<void> _handleMiddlePointPhoto(XFile photo, String savePath, String timestamp, List<File> existingPhotos) async {
    try {
      final sortedPhotos = PhotoUtils.sortPhotos(existingPhotos);
      int sequence;

      if (sortedPhotos.isEmpty) {
        sequence = 2;
      } else {
        final nonEndPhotos = sortedPhotos
            .where((p) => PhotoUtils.getPhotoType(p.path) != PhotoUtils.END_PHOTO)
            .toList();
        sequence = nonEndPhotos.isEmpty
            ? 2
            : PhotoUtils.getPhotoSequence(nonEndPhotos.last.path) + 1;
      }

      final String filename = PhotoUtils.generateFileName(PhotoUtils.MIDDLE_PHOTO, sequence, timestamp);
      final String newPath = path.join(savePath, filename);
      await File(photo.path).copy(newPath);
    } catch (e) {
      print('处理中间点照片失败: $e');
      rethrow;
    }
  }

  // 处理结束点照片
  Future<void> _handleEndPointPhoto(XFile photo, String savePath, String timestamp, List<File> existingPhotos) async {
    try {
      // 删除现有的结束点照片
      for (var existingPhoto in existingPhotos) {
        if (PhotoUtils.getPhotoType(existingPhoto.path) == PhotoUtils.END_PHOTO) {
          await existingPhoto.delete();
        }
      }

      final String filename = PhotoUtils.generateFileName(PhotoUtils.END_PHOTO, 999, timestamp);
      final String newPath = path.join(savePath, filename);
      await File(photo.path).copy(newPath);
    } catch (e) {
      print('处理结束点照片失败: $e');
      rethrow;
    }
  }

  // 处理模型点照片
  Future<void> _handleModelPointPhoto(XFile photo, String savePath, String timestamp, List<File> existingPhotos) async {
    try {
      final sequence = PhotoUtils.generateNewSequence(existingPhotos, PhotoUtils.MODEL_PHOTO);
      final String filename = PhotoUtils.generateFileName(PhotoUtils.MODEL_PHOTO, sequence, timestamp);
      final String newPath = path.join(savePath, filename);
      await File(photo.path).copy(newPath);
    } catch (e) {
      print('处理模型点照片失败: $e');
      rethrow;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // 检查按钮是否应该启用
  bool _isButtonEnabled(String photoType) {
    // 如果项目未初始化，禁用所有按钮
    if (currentProject == null) return false;

    if (currentTrack == null) {
      // 项目模式：只允许模型点拍照
      return photoType == PhotoUtils.MODEL_PHOTO;
    } else {
      // 轨迹模式：允许除模型点外的所有类型
      return photoType != PhotoUtils.MODEL_PHOTO;
    }
  }

  // 构建拍照按钮
  Widget _buildCaptureButton(String photoType, String label) {
    final bool isEnabled = _isButtonEnabled(photoType);

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
                  : () => _takePicture(photoType),
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

  // 显示分辨率指示器
  Widget _buildResolutionIndicator() {
    String resolutionText = "标准清晰度";

    if (_currentResolutionQuality >= 0.9) {
      resolutionText = "最高清晰度";
    } else if (_currentResolutionQuality >= 0.8) {
      resolutionText = "超高清晰度";
    } else if (_currentResolutionQuality >= 0.7) {
      resolutionText = "高清晰度";
    }

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
          resolutionText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // 中心点指示器
  Widget _buildCenterPoint() {
    if (!_showCenterPoint) return const SizedBox.shrink();

    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
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
        title: Text(currentTrack != null ? '轨迹拍照' : '项目拍照'),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.grey[900]!],
              ),
            ),
          ),

          // 中心内容
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 80,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 20),
                const Text(
                  '点击下方按钮使用系统相机拍照',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  currentProject != null
                      ? '当前项目: ${currentProject!.name}'
                      : '未选择项目',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                if (currentTrack != null)
                  Text(
                    '当前轨迹: ${currentTrack!.name}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),

          // 中心点
          _buildCenterPoint(),

          // 分辨率指示器
          _buildResolutionIndicator(),

          // 拍照按钮
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCaptureButton(PhotoUtils.START_PHOTO, '起始点'),
                  _buildCaptureButton(PhotoUtils.MIDDLE_PHOTO, '中间点'),
                  _buildCaptureButton(PhotoUtils.MODEL_PHOTO, '模型点'),
                  _buildCaptureButton(PhotoUtils.END_PHOTO, '结束点'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}