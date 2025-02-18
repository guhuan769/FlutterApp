// lib/utils/settings_manager.dart

import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsManager {
  static const String _cropEnabledKey = 'crop_enabled';
  static const String _resolutionPresetKey = 'resolution_preset';
  static const String _showCenterPointKey = 'show_center_point'; // 新增中心点显示键

  // 定义可用的分辨率列表
  static List<ResolutionPreset> get availableResolutions => [
    ResolutionPreset.high,
    ResolutionPreset.veryHigh,
    ResolutionPreset.ultraHigh,
    ResolutionPreset.max,
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

  // 分辨率相关方法
  static Future<ResolutionPreset> getResolutionPreset() async {
    final prefs = await SharedPreferences.getInstance();
    final presetIndex = prefs.getInt(_resolutionPresetKey) ??
        availableResolutions.length - 1; // 默认使用最高分辨率

    if (presetIndex < 0 || presetIndex >= availableResolutions.length) {
      return availableResolutions.last;
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

  // 分辨率显示文本转换
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