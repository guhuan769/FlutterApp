// lib/services/system_camera_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';

/// 系统相机服务类，封装了系统相机的操作
class SystemCameraService {
  final ImagePicker _picker = ImagePicker();

  /// 打开系统相机并拍照
  /// [imageQuality] 图片质量 0-100
  Future<XFile?> takePhoto({
    int? imageQuality = 80,
    CameraDevice preferredCamera = CameraDevice.rear,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCamera,
      );

      return photo;
    } catch (e) {
      print('系统相机拍照失败: $e');
      return null;
    }
  }

  /// 根据分辨率预设获取图片质量
  int getImageQualityFromResolution(ResolutionPreset resolution) {
    switch (resolution) {
      case ResolutionPreset.low:
        return 30;
      case ResolutionPreset.medium:
        return 50;
      case ResolutionPreset.high:
        return 70;
      case ResolutionPreset.veryHigh:
        return 85;
      case ResolutionPreset.ultraHigh:
        return 95;
      case ResolutionPreset.max:
        return 100;
      default:
        return 80;
    }
  }

  /// 保存照片到指定路径
  Future<File?> savePhotoToPath(XFile photo, String savePath) async {
    try {
      final File savedFile = File(savePath);
      await File(photo.path).copy(savePath);
      return savedFile;
    } catch (e) {
      print('保存照片失败: $e');
      return null;
    }
  }
}