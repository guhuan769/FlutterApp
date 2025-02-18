// lib/utils/settings_manager.dart
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsManager {
  static const String _cropEnabledKey = 'crop_enabled';
  static const String _resolutionPresetKey = 'resolution_preset';
  static const String _showCenterPointKey = 'show_center_point';
  static const String _customResolutionKey = 'custom_resolution';

  // 定义可用的分辨率列表，确保按照从低到高的顺序排列
  static List<ResolutionPreset> get availableResolutions => [
    ResolutionPreset.high,       // 1080p
    ResolutionPreset.veryHigh,   // 2160p
    // ResolutionPreset.ultraHigh,  // 2880p
    ResolutionPreset.max,        // 设备支持的最高分辨率
  ];

  // 裁剪开关相关方法
  static Future<bool> getCropEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cropEnabledKey) ?? true;
  }

  static Future<void> setCropEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cropEnabledKey, enabled);
  }

  // 分辨率相关方法 - 改进版本
  static Future<ResolutionPreset> getResolutionPreset() async {
    final prefs = await SharedPreferences.getInstance();

    // 尝试获取保存的分辨率枚举值
    final savedResolution = prefs.getString(_customResolutionKey);
    if (savedResolution != null) {
      // 将字符串转换回枚举
      try {
        return ResolutionPreset.values.firstWhere(
                (preset) => preset.toString() == savedResolution,
            orElse: () => ResolutionPreset.ultraHigh // 默认使用 2880p
        );
      } catch (e) {
        print('Resolution conversion error: $e');
        return ResolutionPreset.ultraHigh;
      }
    }

    // 如果没有保存过自定义分辨率，使用默认值
    return ResolutionPreset.ultraHigh;
  }

  static Future<void> setResolutionPreset(ResolutionPreset preset) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 直接保存分辨率枚举的字符串表示
      await prefs.setString(_customResolutionKey, preset.toString());
      print('Saved resolution preset: ${preset.toString()}');
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

  // 新增：获取分辨率的数值描述
  static String getResolutionDescription(ResolutionPreset preset) {
    switch (preset) {
      case ResolutionPreset.high:
        return '1920x1080';
      case ResolutionPreset.veryHigh:
        return '3840x2160';
      case ResolutionPreset.ultraHigh:
        return '5120x2880';
      case ResolutionPreset.max:
        return '最高清晰度';
      default:
        return '1920x1080';
    }
  }
}