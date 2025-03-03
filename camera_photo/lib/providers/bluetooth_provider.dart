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


// 针对 UGREEN-LP848 常见的服务UUID列表 - 基于设备信息扩展
  static const List<String> POSSIBLE_SERVICE_UUIDS = [
    "1812",    // HID服务（最可能的服务）
    "180F",    // 电池服务
    "180A",    // 设备信息服务
    "FFE0",    // 自定义控制服务
    "FFF0",    // 另一种自定义服务
    "FF00",    // UGREEN常用自定义服务
    "FF10",    // UGREEN常用自定义服务
    "FFA0",    // UGREEN-LP848可能使用的服务
    "1801",    // 通用属性服务
    "1800",    // 通用访问服务
  ];

// 针对 UGREEN-LP848 常见的特征UUID列表
  static const List<String> POSSIBLE_CHARACTERISTIC_UUIDS = [
    "FFE1",    // 常见的自定义特征
    "2A4D",    // HID报告特征
    "2A4B",    // HID报告映射特征
    "2A4A",    // HID信息特征
    "2A33",    // 设备按键特征
    "2A19",    // 电池电量特征
    "2A00",    // 设备名称特征
    "FFF1",    // 自定义特征
    "FFF2",    // 自定义特征
    "FF01",    // 自定义特征
    "FFA1",    // UGREEN-LP848可能使用的特征
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



// 在 bluetooth_provider.dart 修改 _discoverServices 方法
  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      print('开始发现设备服务...');
      List<BluetoothService> services = await device.discoverServices();
      print('发现了 ${services.length} 个服务');

      // 记录所有服务和特征用于调试
      _logAllServicesAndCharacteristics(services);

      // 针对 UGREEN-LP848 设备，尝试直接找到 HID 服务
      bool foundTriggerService = await _setupHidService(services);

      if (!foundTriggerService) {
        // 尝试常规服务发现
        foundTriggerService = await _findAndSetupTriggerService(services);
      }

      if (!foundTriggerService) {
        // 使用备用方案，尝试设置所有支持通知的特征
        foundTriggerService = await _setupAllPossibleNotifyCharacteristics(services);
      }

      // 如果仍未找到，使用轮询方式监控特征
      if (!foundTriggerService && _connectionState == BtConnectionState.connected) {
        print('使用轮询方式监控HID按键');
        setupPollingFallback(services);
        foundTriggerService = true;
      }

      if (foundTriggerService) {
        print('成功设置蓝牙触发服务');
      } else {
        _errorMessage = '未找到兼容的设备服务，但设备已连接';
        print(_errorMessage);
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = '服务发现失败: $e';
      print(_errorMessage);
      _setConnectionState(BtConnectionState.error);
    }
  }


// 添加轮询监控方法 - 从日志看出 UGREEN-LP848 设备有 HID 服务和可读的特征
  void setupPollingFallback(List<BluetoothService> services) {
    print('设置轮询监控...');

    // 找到所有可读特征
    List<BluetoothCharacteristic> readableCharacteristics = [];

    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.read) {
          readableCharacteristics.add(characteristic);
          print('添加可读特征到轮询队列: ${characteristic.uuid}');
        }
      }
    }

    if (readableCharacteristics.isEmpty) {
      print('没有找到可读特征，无法设置轮询');
      return;
    }

    // 保存最近读取的值
    Map<String, List<int>> lastValues = {};

    // 设置定时器进行轮询
    Timer.periodic(Duration(milliseconds: 200), (timer) async {
      if (_connectionState != BtConnectionState.connected) {
        print('设备已断开连接，停止轮询');
        timer.cancel();
        return;
      }

      for (var characteristic in readableCharacteristics) {
        try {
          final value = await characteristic.read();
          final charUuid = characteristic.uuid.toString();

          // 检查值是否变化
          if (lastValues.containsKey(charUuid) &&
              !_areListsEqual(lastValues[charUuid]!, value) &&
              value.isNotEmpty) {
            // 值发生变化，可能是按钮按下
            print('轮询检测到值变化: $charUuid - 旧值: ${lastValues[charUuid]}, 新值: $value');
            _handleButtonPress(value);
          }

          lastValues[charUuid] = value;
        } catch (e) {
          // 忽略读取错误，继续轮询
        }
      }
    });
  }


// 比较两个列表是否相等
  bool _areListsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }


// 为 UGREEN-LP848 添加专门的 HID 服务设置方法
  Future<bool> _setupHidService(List<BluetoothService> services) async {
    print('尝试设置 UGREEN-LP848 的 HID 服务...');

    // 查找 HID 服务 (0x1812)
    final hidServices = services.where((service) =>
        service.uuid.toString().toUpperCase().contains("1812")).toList();

    if (hidServices.isEmpty) {
      print('未找到 HID 服务');
      return false;
    }

    print('找到 ${hidServices.length} 个 HID 服务');

    for (var hidService in hidServices) {
      final characteristics = hidService.characteristics;

      // 从日志看，设备有 2A4D Report 特征
      var reportCharacteristics = characteristics.where((c) =>
          c.uuid.toString().toUpperCase().contains("2A4D")).toList();

      if (reportCharacteristics.isEmpty) {
        print('HID 服务中未找到 Report 特征');
        continue;
      }

      print('找到 ${reportCharacteristics.length} 个 Report 特征');

      // 尝试设置轮询监控这些特征
      _triggerService = hidService;

      // 对每个特征设置轮询读取
      List<List<int>> lastValues = List.generate(
          reportCharacteristics.length,
              (_) => []
      );

      Timer.periodic(Duration(milliseconds: 100), (timer) async {
        if (_connectionState != BtConnectionState.connected) {
          timer.cancel();
          return;
        }

        for (int i = 0; i < reportCharacteristics.length; i++) {
          try {
            final characteristic = reportCharacteristics[i];

            if (!characteristic.properties.read) continue;

            final value = await characteristic.read();

            // 检查值是否变化
            if (lastValues[i].isNotEmpty &&
                !_areListsEqual(lastValues[i], value) &&
                value.isNotEmpty) {
              // 值发生变化，可能是按钮按下
              print('轮询 Report 特征检测到值变化: 旧值: ${lastValues[i]}, 新值: $value');
              _handleButtonPress(value);
            }

            lastValues[i] = value;
          } catch (e) {
            // 忽略读取错误
          }
        }
      });

      print('已设置 HID 服务轮询');
      return true;
    }

    return false;
  }



// 3. 添加专门用于HID服务特征的设置方法
  Future<bool> _setupAllHidCharacteristics(List<BluetoothService> services) async {
    print('尝试设置HID服务特征...');
    bool anySuccess = false;

    try {
      // 查找HID服务
      final hidServices = services.where((service) =>
          service.uuid.toString().toUpperCase().contains("1812"));

      if (hidServices.isEmpty) {
        print('未找到HID服务');
        return false;
      }

      // 对每个HID服务设置所有通知特征
      for (var hidService in hidServices) {
        print('发现HID服务: ${hidService.uuid}');

        // 查找报告特征或其他可能包含按键信息的特征
        final potentialCharacteristics = hidService.characteristics.where((c) =>
        c.properties.notify || c.properties.indicate || c.properties.read);

        for (var characteristic in potentialCharacteristics) {
          try {
            print('尝试设置HID特征通知: ${characteristic.uuid}');

            // 如果支持通知，设置通知
            if (characteristic.properties.notify || characteristic.properties.indicate) {
              await characteristic.setNotifyValue(true);

              // 设置监听
              if (!anySuccess) {
                _buttonPressSubscription = characteristic.value.listen(
                        (value) {
                      print('收到HID特征值更新: $value');
                      if (value.isNotEmpty) {
                        _handleButtonPress(value);
                      }
                    }
                );

                _triggerService = hidService;
                _triggerCharacteristic = characteristic;
                anySuccess = true;
                print('成功设置HID特征通知');
              }
            }
            // 如果是只读特征，定期读取它的值
            else if (characteristic.properties.read) {
              // 设置定期读取计时器
              Timer.periodic(Duration(milliseconds: 100), (timer) async {
                if (_connectionState == BtConnectionState.connected) {
                  try {
                    final value = await characteristic.read();
                    if (value.isNotEmpty) {
                      print('读取HID特征值: $value');
                      _handleButtonPress(value);
                    }
                  } catch (e) {
                    // 忽略读取错误
                  }
                } else {
                  timer.cancel();
                }
              });
            }
          } catch (e) {
            print('设置HID特征失败: ${characteristic.uuid}, 错误: $e');
          }
        }
      }
    } catch (e) {
      print('设置HID特征时出错: $e');
    }

    return anySuccess;
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




// 修改按钮事件处理方法，增加更多检测模式
  void _handleButtonPress(List<int> value) {
    final now = DateTime.now();

    // 防抖处理，避免重复触发
    if (_lastTriggerTime != null) {
      final difference = now.difference(_lastTriggerTime!);
      if (difference.inMilliseconds < 500) {
        print('按钮事件触发过于频繁 (${difference.inMilliseconds}ms)，忽略此次事件');
        return;
      }
    }

    _lastTriggerTime = now;

    // 输出详细的按键值以便调试
    String hexValues = value.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ');
    print('接收到按键值: [$hexValues], 长度: ${value.length}');

    // UGREEN-LP848 常见的几种按键模式判断
    bool isButtonPress = false;

    // 1. 有些值变化会置第一个字节为1
    if (value.length >= 1 && value[0] != 0) {
      isButtonPress = true;
    }

    // 2. HID键盘事件格式：通常在特定位置有变化
    else if (value.length >= 8) {
      // HID报告格式，通常第3-8字节会包含按键码
      for (int i = 2; i < 8 && i < value.length; i++) {
        if (value[i] != 0) {
          isButtonPress = true;
          break;
        }
      }
    }

    // 3. 部分按键可能会在最后一个字节发生变化
    else if (value.length > 1 && value.last != 0) {
      isButtonPress = true;
    }

    // 4. 某些设备会以位变化方式报告
    else if (value.length > 0) {
      // 一般来说，任何非零值都可能表示按钮按下
      bool allZeros = value.every((element) => element == 0);
      if (!allZeros) {
        isButtonPress = true;
      }
    }

    // 如果判断为按钮按下，则触发相机拍照
    if (isButtonPress) {
      try {
        // 振动反馈
        HapticFeedback.mediumImpact();
      } catch (e) {
        // 忽略振动失败
      }

      // 触发拍照事件
      print('检测到远程触发！当前模式: $_currentTriggerType');
      onRemoteTriggerPressed();
    }
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
    // 如果类型没有变化，则不通知
    if (_currentTriggerType == type) return;

    print('设置触发类型: $type');
    _currentTriggerType = type;

    // 使用更安全的方式通知监听器，不会与小部件构建冲突
    Future.microtask(() {
      try {
        notifyListeners();
      } catch (e) {
        print('通知监听器错误: $e');
      }
    });
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