// lib/utils/bluetooth_utils.dart
import 'dart:io';
import 'package:flutter/services.dart';

class BluetoothUtils {
  // 打开系统蓝牙设置
  static Future<void> openBluetoothSettings() async {
    try {
      // 对于Android，使用原生方法通道
      if (Platform.isAndroid) {
        const platform = MethodChannel('com.yourapp/bluetooth');
        await platform.invokeMethod('openBluetoothSettings');
      }
      // 对于iOS，仅能引导用户手动打开设置
      else if (Platform.isIOS) {
        // iOS无法直接打开蓝牙设置，只能显示提示
        print('iOS不支持直接打开蓝牙设置');
      }
    } catch (e) {
      print('打开蓝牙设置失败: $e');
    }
  }

  // 检查蓝牙权限
  static Future<bool> checkBluetoothPermissions() async {
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('com.yourapp/bluetooth');
        return await platform.invokeMethod('checkBluetoothPermissions');
      }
      return true; // iOS在安装时已请求权限
    } catch (e) {
      print('检查蓝牙权限失败: $e');
      return false;
    }
  }

  // 请求蓝牙权限
  static Future<bool> requestBluetoothPermissions() async {
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('com.yourapp/bluetooth');
        return await platform.invokeMethod('requestBluetoothPermissions');
      }
      return true; // iOS在安装时已请求权限
    } catch (e) {
      print('请求蓝牙权限失败: $e');
      return false;
    }
  }
}