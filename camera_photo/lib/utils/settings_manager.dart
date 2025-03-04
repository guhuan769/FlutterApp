// lib/utils/settings_manager.dart
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsManager {
  static const String _cropEnabledKey = 'crop_enabled';
  static const String _resolutionPresetKey = 'resolution_preset';
  static const String _showCenterPointKey = 'show_center_point';
  static const String _customResolutionKey = 'custom_resolution';

  // 定义可用的分辨率列表
  static List<ResolutionPreset> get availableResolutions => [
    ResolutionPreset.high,       // 1080p
    ResolutionPreset.veryHigh,   // 2160p
    ResolutionPreset.max,        // 设备支持的最高分辨率
  ];

  // 裁剪开关相关方法
  static Future<bool> getCropEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cropEnabledKey) ?? false;
  }

  static Future<void> setCropEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cropEnabledKey, enabled);
  }

  // 分辨率相关方法
  static Future<ResolutionPreset> getResolutionPreset() async {
    final prefs = await SharedPreferences.getInstance();

    // 尝试获取保存的分辨率枚举值
    final savedResolutionIndex = prefs.getInt(_resolutionPresetKey);
    if (savedResolutionIndex != null && savedResolutionIndex >= 0 && savedResolutionIndex < ResolutionPreset.values.length) {
      return ResolutionPreset.values[savedResolutionIndex];
    }

    // 回退到字符串方式
    final savedResolution = prefs.getString(_customResolutionKey);
    if (savedResolution != null) {
      try {
        return ResolutionPreset.values.firstWhere(
                (preset) => preset.toString() == savedResolution,
            orElse: () => ResolutionPreset.high
        );
      } catch (e) {
        print('Resolution conversion error: $e');
        return ResolutionPreset.high;
      }
    }

    // 默认使用高清
    return ResolutionPreset.high;
  }

  static Future<void> setResolutionPreset(ResolutionPreset preset) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 保存枚举索引
      await prefs.setInt(_resolutionPresetKey, preset.index);

      // 同时保存字符串表示（兼容性目的）
      await prefs.setString(_customResolutionKey, preset.toString());

      print('Saved resolution preset: ${preset.toString()}, index: ${preset.index}');
    } catch (e) {
      print('Error saving resolution preset: $e');
    }
  }

  // 中心点显示相关方法
  static Future<bool> getShowCenterPoint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showCenterPointKey) ?? true;
  }

  static Future<void> setShowCenterPoint(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showCenterPointKey, show);
  }

  // 分辨率显示文本转换
  static String resolutionPresetToString(ResolutionPreset preset) {
    switch (preset) {
      case ResolutionPreset.low:
        return '低清晰度 (480p)';
      case ResolutionPreset.medium:
        return '中等清晰度 (720p)';
      case ResolutionPreset.high:
        return '高清 (1080p)';
      case ResolutionPreset.veryHigh:
        return '超清 (2160p)';
      case ResolutionPreset.ultraHigh:
        return '蓝光 (2880p)';
      case ResolutionPreset.max:
        return '最高清晰度';
      default:
        return '高清 (1080p)';
    }
  }

  // 获取分辨率的数值描述
  static String getResolutionDescription(ResolutionPreset preset) {
    switch (preset) {
      case ResolutionPreset.low:
        return '640x480';
      case ResolutionPreset.medium:
        return '1280x720';
      case ResolutionPreset.high:
        return '1920x1080';
      case ResolutionPreset.veryHigh:
        return '3840x2160';
      case ResolutionPreset.ultraHigh:
        return '5120x2880';
      case ResolutionPreset.max:
        return '设备支持的最高分辨率';
      default:
        return '1920x1080';
    }
  }

  // 转换为系统相机的质量值(0-100)
  static int getSystemCameraQuality(ResolutionPreset preset) {
    switch (preset) {
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
}