// lib/utils/settings_manager.dart
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsManager {
  static const String _cropEnabledKey = 'crop_enabled';
  static const String _resolutionPresetKey = 'resolution_preset';
  static const String _showCenterPointKey = 'show_center_point';

  // 定义可用的分辨率列表，确保按照从低到高的顺序排列
  static List<ResolutionPreset> get availableResolutions => [
    ResolutionPreset.high,       // 1080p
    ResolutionPreset.veryHigh,   // 2160p
    ResolutionPreset.ultraHigh,  // 2880p
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

  // 分辨率相关方法 - 默认使用最高分辨率
  static Future<ResolutionPreset> getResolutionPreset() async {
    final prefs = await SharedPreferences.getInstance();
    final presetIndex = prefs.getInt(_resolutionPresetKey) ??
        availableResolutions.length - 1; // 默认使用最高分辨率

    // 确保返回有效的分辨率预设
    if (presetIndex < 0 || presetIndex >= availableResolutions.length) {
      return ResolutionPreset.max; // 如果出现异常，返回最高分辨率
    }
    return availableResolutions[presetIndex];
  }

  static Future<void> setResolutionPreset(ResolutionPreset preset) async {
    final prefs = await SharedPreferences.getInstance();
    final index = availableResolutions.indexOf(preset);
    if (index != -1) {
      await prefs.setInt(_resolutionPresetKey, index);
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

  // 保持原有的分辨率显示文本
  static String resolutionPresetToString(ResolutionPreset preset) {
    switch (preset) {
      case ResolutionPreset.high:
        return '高清';
      case ResolutionPreset.veryHigh:
        return '超清';
      case ResolutionPreset.ultraHigh:
        return '蓝光';
      case ResolutionPreset.max:
        return '最高清晰度';
      default:
        return '高清';
    }
  }
}