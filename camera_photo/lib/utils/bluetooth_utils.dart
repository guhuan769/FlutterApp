// lib/utils/bluetooth_utils.dart 更新版
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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

  // 新增: 确保蓝牙已开启
  static Future<bool> ensureBluetoothIsOn() async {
    try {
      // 获取当前蓝牙状态
      final state = await FlutterBluePlus.adapterState.first;

      if (state == BluetoothAdapterState.on) {
        // 蓝牙已经开启
        return true;
      } else {
        // 蓝牙未开启，提示用户
        print('蓝牙未开启，请手动开启蓝牙');
        await openBluetoothSettings();
        return false;
      }
    } catch (e) {
      print('检查蓝牙状态失败: $e');
      return false;
    }
  }

  // 新增: 获取系统已连接的UGREEN设备
  static Future<List<BluetoothDevice>> getConnectedUgreenDevices() async {
    try {
      final connectedDevices = await FlutterBluePlus.connectedDevices;

      // 过滤出UGREEN/LP848设备
      return connectedDevices.where((device) =>
      device.name.contains("UGREEN") ||
          device.name.contains("LP848")
      ).toList();
    } catch (e) {
      print('获取已连接UGREEN设备失败: $e');
      return [];
    }
  }

  // 新增: 调试用 - 打印当前蓝牙适配器状态
  static Future<void> printBluetoothAdapterState() async {
    try {
      final state = await FlutterBluePlus.adapterState.first;
      print('蓝牙适配器状态: $state');

      // 检查是否有设备已连接
      final devices = await FlutterBluePlus.connectedDevices;
      print('已连接设备数量: ${devices.length}');

      // 打印已连接设备信息
      for (var device in devices) {
        print('已连接设备: ${device.name} (${device.id})');
      }
    } catch (e) {
      print('获取蓝牙状态失败: $e');
    }
  }

  // 新增: 解析十六进制特征值
  static Map<String, dynamic> parseHexValue(List<int> value) {
    if (value.isEmpty) {
      return {'text': '空值', 'hex': '[]'};
    }

    // 十六进制表示
    String hexString = value.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ');

    // 尝试解析为文本
    String textValue = '';
    try {
      textValue = String.fromCharCodes(value);
    } catch (e) {
      textValue = '无法解析为文本';
    }

    // 布尔解释(通常第一个字节表示状态)
    bool boolValue = value[0] != 0;

    return {
      'hex': '[$hexString]',
      'text': textValue,
      'bool': boolValue,
      'firstByte': value[0]
    };
  }

  // 新增: 写入特征值
  static Future<bool> writeCharacteristic(
      BluetoothCharacteristic characteristic,
      List<int> value
      ) async {
    try {
      await characteristic.write(value);
      print('写入成功: ${value.toString()}');
      return true;
    } catch (e) {
      print('写入特征失败: $e');
      return false;
    }
  }

  // 新增: UGREEN-LP848设备调试指南
  static String getUgreenDeviceGuide() {
    return '''
UGREEN-LP848蓝牙设备调试指南:

1. 服务识别
   优绿LP848设备通常使用以下几种服务类型:
   - HID服务 (1812): 标准HID设备接口
   - 电池服务 (180F): 电量信息
   - 设备信息服务 (180A): 设备名称、厂商信息等
   - 自定义服务 (FFE0): 专用服务，通常包含按键控制
   
2. 特征识别
   按键触发特征通常有以下特点:
   - 支持通知(Notify)功能
   - 值会在按下时发生变化
   - 常见UUID前缀: FFE1, 2A4D, 2A4B
   
3. 常见问题排查
   - 电池电量不足: 更换电池
   - 多次按键未响应: 检查当前模式是否与按钮匹配
   - 连接成功但无响应: 进入调试模式，验证是否找到正确特征
   
4. 添加新服务/特征
   如果在调试中发现设备使用了未知服务或特征，
   请将其UUID添加到BluetoothProvider中的相应列表:
   - POSSIBLE_SERVICE_UUIDS
   - POSSIBLE_CHARACTERISTIC_UUIDS
''';
  }
}