// lib/utils/settings_manager.dart
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsManager {
  static const String _cropEnabledKey = 'crop_enabled';
  static const String _resolutionPresetKey = 'resolution_preset';

  // Get crop enabled setting
  static Future<bool> getCropEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cropEnabledKey) ?? true; // Default to true
  }

  // Set crop enabled setting
  static Future<void> setCropEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cropEnabledKey, enabled);
  }

  // Get resolution preset setting
  static Future<ResolutionPreset> getResolutionPreset() async {
    final prefs = await SharedPreferences.getInstance();
    final presetIndex = prefs.getInt(_resolutionPresetKey) ?? 5; // Default to max
    return ResolutionPreset.values[presetIndex];
  }

  // Set resolution preset setting
  static Future<void> setResolutionPreset(ResolutionPreset preset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_resolutionPresetKey, preset.index);
  }

  // Helper method to convert ResolutionPreset to display string
  static String resolutionPresetToString(ResolutionPreset preset) {
    switch (preset) {
      case ResolutionPreset.low:
        return '低清晰度';
      case ResolutionPreset.medium:
        return '标清';
      case ResolutionPreset.high:
        return '高清';
      case ResolutionPreset.veryHigh:
        return '超清';
      case ResolutionPreset.ultraHigh:
        return '蓝光';
      case ResolutionPreset.max:
        return '最高清晰度';
    }
  }
}