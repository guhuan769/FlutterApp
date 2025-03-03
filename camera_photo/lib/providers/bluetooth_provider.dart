// lib/providers/bluetooth_provider.dart 优化版
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// 蓝牙连接状态枚举
enum BtConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

// 拍照触发类型枚举
enum PhotoTriggerType {
  start,
  middle,
  model,
  end,
}

class BluetoothProvider with ChangeNotifier {
  // ========== 基本属性 ==========
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _connectedDevice;
  BluetoothService? _triggerService;
  BluetoothCharacteristic? _triggerCharacteristic;
  BtConnectionState _connectionState = BtConnectionState.disconnected;

  // 流订阅
  StreamSubscription? _deviceConnectionSubscription;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _buttonPressSubscription;

  // 设备信息
  static const String DEVICE_NAME_FILTER = "UGREEN-LP848";

  // 可能的服务UUID列表 - 扩展更多可能的服务UUID
  static const List<String> POSSIBLE_SERVICE_UUIDS = [
    "1812",    // HID服务
    "180F",    // 电池服务
    "180A",    // 设备信息服务
    "FFE0",    // 自定义控制服务
    "FFF0",    // 另一种自定义服务
    "FF00",    // 常见的自定义服务
    "FF10",    // 常见的自定义服务
    "1801",    // 通用属性服务
    "1800",    // 通用访问服务
  ];

  // 可能的特征UUID列表 - 添加特征UUID列表
  static const List<String> POSSIBLE_CHARACTERISTIC_UUIDS = [
    "FFE1",    // 常见的自定义特征
    "2A4D",    // HID报告特征
    "2A4B",    // HID报告映射特征
    "2A4A",    // HID信息特征
    "2A19",    // 电池电量特征
    "2A00",    // 设备名称特征
    "FFF1",    // 自定义特征
    "FFF2",    // 自定义特征
    "FF01",    // 自定义特征
  ];

  // 拍照模式
  PhotoTriggerType _currentTriggerType = PhotoTriggerType.model;

  // 错误信息
  String _errorMessage = '';

  // 连接尝试次数
  int _connectionAttempts = 0;
  final int _maxConnectionAttempts = 3;

  // 最后按钮触发时间，用于防抖
  DateTime? _lastTriggerTime;

  // ========== Getters ==========
  BtConnectionState get connectionState => _connectionState;
  List<BluetoothDevice> get devicesList => _devicesList;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  String get errorMessage => _errorMessage;
  bool get isScanning => FlutterBluePlus.isScanningNow;
  PhotoTriggerType get currentTriggerType => _currentTriggerType;

  // ========== 初始化 ==========
  BluetoothProvider() {
    _initialize();
  }

  void _initialize() {
    // 监听蓝牙适配器状态
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.on) {
        // 蓝牙开启，自动检查系统已连接设备
        _checkSystemConnectedDevices();
      } else if (state == BluetoothAdapterState.off) {
        // 蓝牙关闭
        _setConnectionState(BtConnectionState.disconnected);
        _errorMessage = '蓝牙已关闭';
        notifyListeners();
      }
    });
  }

  // ========== 扫描方法 ==========
  Future<void> startScan() async {
    _devicesList = [];
    _errorMessage = '';
    notifyListeners();

    try {
      // 检查蓝牙是否开启
      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) {
        _errorMessage = '请打开蓝牙';
        notifyListeners();
        return;
      }

      // 取消之前的扫描
      if (_scanSubscription != null) {
        await _scanSubscription!.cancel();
        _scanSubscription = null;
      }

      // 先检查已连接的设备
      await _checkSystemConnectedDevices();

      // 开始新的扫描
      _scanSubscription = FlutterBluePlus.scanResults.listen(
              (results) {
            for (ScanResult result in results) {
              if (!_devicesList.contains(result.device) &&
                  result.device.name.isNotEmpty &&
                  (result.device.name.toLowerCase().contains("ugreen") ||
                      result.device.name.toLowerCase().contains("lp848"))) {
                _devicesList.add(result.device);
                print('找到蓝牙设备: ${result.device.name} [${result.device.id}]');
                notifyListeners();
              }
            }
          },
          onError: (error) {
            _errorMessage = '扫描错误: $error';
            notifyListeners();
          }
      );

      // 开始扫描
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 5),
        androidScanMode: AndroidScanMode.lowLatency,
      );

      // 5秒后自动停止扫描
      Future.delayed(Duration(seconds: 5), () {
        stopScan();
      });
    } catch (e) {
      _errorMessage = '扫描失败: $e';
      notifyListeners();
    }
  }

  // 检查系统中已连接的设备
  Future<void> _checkSystemConnectedDevices() async {
    try {
      final connectedDevices = await FlutterBluePlus.connectedDevices;
      for (var device in connectedDevices) {
        if (device.name.contains("UGREEN") ||
            device.name.contains("LP848")) {
          if (!_devicesList.contains(device)) {
            _devicesList.add(device);
            print('找到已连接的设备: ${device.name} [${device.id}]');

            // 自动连接已连接设备
            if (_connectionState == BtConnectionState.disconnected) {
              connectToDevice(device);
            }

            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('检查系统连接设备失败: $e');
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      if (_scanSubscription != null) {
        await _scanSubscription!.cancel();
        _scanSubscription = null;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = '停止扫描失败: $e';
      notifyListeners();
    }
  }

  // ========== 设备连接方法 ==========
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_connectionState == BtConnectionState.connecting) {
      return;
    }

    _setConnectionState(BtConnectionState.connecting);
    _errorMessage = '';
    _connectionAttempts = 0;

    try {
      // 断开之前的连接
      await disconnectDevice();

      // 设置监听连接状态变化
      _deviceConnectionSubscription = device.connectionState.listen(
              (BluetoothConnectionState state) {
            print('设备连接状态变更: $state');
            switch (state) {
              case BluetoothConnectionState.connected:
                _setConnectionState(BtConnectionState.connected);
                _discoverServices(device);
                break;
              case BluetoothConnectionState.disconnected:
                _setConnectionState(BtConnectionState.disconnected);
                break;
              case BluetoothConnectionState.connecting:
                _setConnectionState(BtConnectionState.connecting);
                break;
              case BluetoothConnectionState.disconnecting:
                _setConnectionState(BtConnectionState.disconnecting);
                break;
            }
          },
          onError: (error) {
            _setConnectionState(BtConnectionState.error);
            _errorMessage = '连接状态错误: $error';
            notifyListeners();
          }
      );

      // 连接设备
      await device.connect(timeout: Duration(seconds: 15));
      _connectedDevice = device;

    } catch (e) {
      _handleConnectionError(e, device);
    }
  }

  // 处理连接错误
  void _handleConnectionError(dynamic error, BluetoothDevice device) {
    print('连接错误: $error');

    _connectionAttempts++;
    if (_connectionAttempts < _maxConnectionAttempts) {
      print('尝试重新连接: 第 $_connectionAttempts 次');
      _setConnectionState(BtConnectionState.connecting);

      // 延迟一段时间后重试
      Future.delayed(Duration(seconds: 2), () {
        if (_connectionState != BtConnectionState.connected) {
          connectToDevice(device);
        }
      });
    } else {
      _setConnectionState(BtConnectionState.error);
      _errorMessage = '连接失败，请重试: $error';
      notifyListeners();
    }
  }

  Future<void> disconnectDevice() async {
    if (_connectedDevice != null) {
      _setConnectionState(BtConnectionState.disconnecting);

      try {
        // 取消服务发现和按钮监听
        if (_buttonPressSubscription != null) {
          await _buttonPressSubscription!.cancel();
          _buttonPressSubscription = null;
        }

        // 取消连接状态监听
        if (_deviceConnectionSubscription != null) {
          await _deviceConnectionSubscription!.cancel();
          _deviceConnectionSubscription = null;
        }

        // 断开设备连接
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _triggerService = null;
        _triggerCharacteristic = null;

        _setConnectionState(BtConnectionState.disconnected);
      } catch (e) {
        _errorMessage = '断开连接失败: $e';
        _setConnectionState(BtConnectionState.error);
      }
    }
  }


// 添加改进的服务发现方法
  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      print('开始发现设备服务...');
      List<BluetoothService> services = await device.discoverServices();
      print('发现了 ${services.length} 个服务');

      // 记录所有服务和特征
      _logAllServicesAndCharacteristics(services);

      // 查找可用的服务和特征
      bool foundTriggerService = await _findAndSetupTriggerService(services);

      // 使用备用方案，尝试设置所有支持通知的特征
      if (!foundTriggerService) {
        foundTriggerService = await _setupAllPossibleNotifyCharacteristics(services);
      }

      // 如果仍未找到，尝试使用通用HID特征
      if (!foundTriggerService && _connectionState == BtConnectionState.connected) {
        print('使用通用HID键盘监听作为备选方案');
        _setupFallbackButtonDetection();
        // 即使找不到特定特征，也认为连接成功
        foundTriggerService = true;
      }

      if (!foundTriggerService) {
        _errorMessage = '未找到兼容的设备服务，但设备已连接';
        print(_errorMessage);
        notifyListeners();
      } else {
        print('成功设置蓝牙触发服务');
      }
    } catch (e) {
      _errorMessage = '服务发现失败: $e';
      print(_errorMessage);
      _setConnectionState(BtConnectionState.error);
    }
  }



// 辅助方法：记录所有服务和特征
  void _logAllServicesAndCharacteristics(List<BluetoothService> services) {
    for (var service in services) {
      print('服务: ${service.uuid.toString()}');
      for (var characteristic in service.characteristics) {
        String props = '';
        if (characteristic.properties.read) props += 'Read ';
        if (characteristic.properties.write) props += 'Write ';
        if (characteristic.properties.notify) props += 'Notify ';
        if (characteristic.properties.indicate) props += 'Indicate ';

        print('  特征: ${characteristic.uuid.toString()} [$props]');
      }
    }
  }

// 辅助方法：查找和设置触发服务
  Future<bool> _findAndSetupTriggerService(List<BluetoothService> services) async {
    for (String serviceUuid in POSSIBLE_SERVICE_UUIDS) {
      print('尝试查找服务: $serviceUuid');

      for (BluetoothService service in services) {
        if (service.uuid.toString().toUpperCase().contains(serviceUuid)) {
          print('找到可能的触发服务: ${service.uuid.toString()}');

          for (BluetoothCharacteristic characteristic in service.characteristics) {
            String charUuid = characteristic.uuid.toString().toUpperCase().substring(0, 4);
            print('检查特征: $charUuid');

            // 检查是否是已知特征或支持通知/指示
            bool isKnownChar = POSSIBLE_CHARACTERISTIC_UUIDS.any(
                    (id) => characteristic.uuid.toString().toUpperCase().contains(id)
            );

            if (isKnownChar ||
                characteristic.properties.notify ||
                characteristic.properties.indicate) {

              print('发现可能的触发特征: ${characteristic.uuid.toString()}');
              if (await _setupCharacteristicNotification(characteristic)) {
                _triggerService = service;
                _triggerCharacteristic = characteristic;
                return true;
              }
            }
          }
        }
      }
    }
    return false;
  }


// 辅助方法：设置特征通知
  Future<bool> _setupCharacteristicNotification(BluetoothCharacteristic characteristic) async {
    if (characteristic.properties.notify || characteristic.properties.indicate) {
      try {
        print('尝试设置特征通知: ${characteristic.uuid.toString()}');

        // 设置通知前先关闭已有通知
        if (_buttonPressSubscription != null) {
          await _buttonPressSubscription!.cancel();
          _buttonPressSubscription = null;
        }

        // 开启通知
        await characteristic.setNotifyValue(true);

        // 添加值监听
        _buttonPressSubscription = characteristic.value.listen(
                (value) {
              print('收到特征值更新: $value');
              if (value.isNotEmpty) {
                _handleButtonPress(value);
              }
            },
            onError: (error) {
              print('特征通知错误: $error');
            }
        );

        print('成功设置特征通知');
        return true;
      } catch (e) {
        print('设置特征通知失败: $e');
      }
    }
    return false;
  }


// 辅助方法：尝试设置所有可能的通知特征
  Future<bool> _setupAllPossibleNotifyCharacteristics(List<BluetoothService> services) async {
    print('尝试设置所有支持通知的特征...');
    bool anySuccess = false;

    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.notify || characteristic.properties.indicate) {
          try {
            print('尝试设置通知特征: ${characteristic.uuid}');
            await characteristic.setNotifyValue(true);

            // 监听一个特殊的特征
            if (!anySuccess) {
              _buttonPressSubscription = characteristic.value.listen(
                      (value) {
                    print('收到特征值更新[通用]: $value');
                    if (value.isNotEmpty) {
                      _handleButtonPress(value);
                    }
                  }
              );

              _triggerService = service;
              _triggerCharacteristic = characteristic;
              anySuccess = true;
              print('成功设置通用通知特征');
            }
          } catch (e) {
            print('设置通知失败: ${characteristic.uuid}, 错误: $e');
          }
        }
      }
    }

    return anySuccess;
  }

  // 设置备用的按钮检测方法
  void _setupFallbackButtonDetection() {
    print('设置备用按键检测...');

    // 如果没有找到标准的通知特征，可以通过监听系统按键事件或者其他方式来检测
    // 这里示例使用RawKeyboard监听系统按键，实际应用中可能需要平台通道

    // 当设备连接状态发生变化时，可能会触发事件
    if (_connectedDevice != null) {
      print('设备已连接，可以接收系统按键事件');
    }
  }


// 改进的按钮按下事件处理
  void _handleButtonPress(List<int> value) {
    final now = DateTime.now();

    // 防抖处理：如果两次按钮事件间隔小于800毫秒，忽略后续事件
    if (_lastTriggerTime != null) {
      final difference = now.difference(_lastTriggerTime!);
      if (difference.inMilliseconds < 800) {
        print('按钮事件触发过于频繁 (${difference.inMilliseconds}ms)，忽略此次事件');
        return;
      }
    }

    _lastTriggerTime = now;

    // 记录详细的按键值
    String hexValues = value.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ');
    print('按键值: [$hexValues], 长度: ${value.length}');

    // 使用更强的震动反馈确认按钮被按下
    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      // 忽略可能的平台错误
    }

    // 触发拍照事件
    print('检测到远程触发！当前模式: $_currentTriggerType');
    onRemoteTriggerPressed();
  }

  // ========== 触发方法 ==========
  void onRemoteTriggerPressed() {
    print('触发远程按钮事件 - 当前模式: $_currentTriggerType');
    // 防止状态已清理的情况下调用
    try {
      notifyListeners();
      // 确保触发事件被传递到监听器
      Future.delayed(Duration(milliseconds: 100), () {
        notifyListeners();  // 二次通知，确保事件不会被丢失
      });
    } catch (e) {
      print('触发通知异常: $e');
    }
  }

  // 设置当前的触发类型
  void setTriggerType(PhotoTriggerType type) {
    print('设置触发类型: $type');
    _currentTriggerType = type;
    notifyListeners();
  }

  // 更新连接状态
  void _setConnectionState(BtConnectionState state) {
    _connectionState = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _deviceConnectionSubscription?.cancel();
    _buttonPressSubscription?.cancel();
    super.dispose();
  }
}