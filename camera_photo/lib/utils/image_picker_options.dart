// lib/utils/image_picker_options.dart
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

/// 图像选择器选项类，扩展ImagePicker功能
class ImagePickerOptions {
  final int? imageQuality;
  final Map<String, dynamic>? androidOptions;
  final Map<String, dynamic>? iosOptions;

  ImagePickerOptions({
    this.imageQuality,
    this.androidOptions,
    this.iosOptions,
  });

  /// 从分辨率预设创建图像选择器选项
  static ImagePickerOptions fromResolutionPreset(ResolutionPreset preset) {
    switch (preset) {
      case ResolutionPreset.low:
        return ImagePickerOptions(imageQuality: 30);
      case ResolutionPreset.medium:
        return ImagePickerOptions(imageQuality: 50);
      case ResolutionPreset.high:
        return ImagePickerOptions(imageQuality: 70);
      case ResolutionPreset.veryHigh:
        return ImagePickerOptions(imageQuality: 85);
      case ResolutionPreset.ultraHigh:
        return ImagePickerOptions(imageQuality: 95);
      case ResolutionPreset.max:
        return ImagePickerOptions(imageQuality: 100);
      default:
        return ImagePickerOptions(imageQuality: 80);
    }
  }

  /// 将选项导出为平台特定配置
  Map<String, dynamic> toMap() {
    return {
      'imageQuality': imageQuality,
      // 可以根据需要在这里添加其他平台特定的配置
    };
  }
}