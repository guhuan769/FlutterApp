// lib/providers/bluetooth_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
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

  // 可能的服务UUID列表
  static const List<String> POSSIBLE_SERVICE_UUIDS = [
    "1812",    // HID服务
    "180F",    // 电池服务
    "180A",    // 设备信息服务
    "FFE0",    // 自定义控制服务
  ];

  // 拍照模式
  PhotoTriggerType _currentTriggerType = PhotoTriggerType.model;

  // 错误信息
  String _errorMessage = '';

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
        // 蓝牙开启
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
            device.name.contains("LP848") ||
            device.name == DEVICE_NAME_FILTER) {
          if (!_devicesList.contains(device)) {
            _devicesList.add(device);
            print('找到已连接的设备: ${device.name} [${device.id}]');
            // 自动连接
            connectToDevice(device);
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
      _setConnectionState(BtConnectionState.error);
      _errorMessage = '连接失败: $e';
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

  // ========== 服务发现方法 ==========
  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      print('开始发现设备服务...');
      List<BluetoothService> services = await device.discoverServices();
      print('发现了 ${services.length} 个服务');

      // 记录所有服务和特征
      for (var service in services) {
        print('服务: ${service.uuid.toString()}');
        for (var characteristic in service.characteristics) {
          print('  特征: ${characteristic.uuid.toString()}');
          print('  特征属性: ${characteristic.properties}');
        }
      }

      // 查找可用的服务
      bool foundTriggerService = false;

      // 尝试所有可能的服务UUID
      for (String serviceUuid in POSSIBLE_SERVICE_UUIDS) {
        print('尝试查找服务: $serviceUuid');

        for (BluetoothService service in services) {
          if (service.uuid.toString().toUpperCase().contains(serviceUuid)) {
            print('找到可能的触发服务: ${service.uuid.toString()}');
            _triggerService = service;

            // 查找可用的特征
            for (BluetoothCharacteristic characteristic in service.characteristics) {
              print('检查特征: ${characteristic.uuid.toString()}');

              if (characteristic.properties.notify ||
                  characteristic.properties.indicate ||
                  characteristic.properties.write) {
                print('找到可能的触发特征: ${characteristic.uuid.toString()}');
                _triggerCharacteristic = characteristic;

                // 尝试设置通知
                if (characteristic.properties.notify || characteristic.properties.indicate) {
                  try {
                    await characteristic.setNotifyValue(true);
                    _buttonPressSubscription = characteristic.value.listen(
                            (value) {
                          print('接收到特征值更新: $value');
                          if (value.isNotEmpty) {
                            // 触发对应的拍照事件
                            onRemoteTriggerPressed();
                          }
                        }
                    );

                    foundTriggerService = true;
                    print('成功设置特征通知');
                    break;
                  } catch (e) {
                    print('设置特征通知失败: $e');
                  }
                }
              }
            }

            if (foundTriggerService) break;
          }
        }

        if (foundTriggerService) break;
      }

      if (!foundTriggerService) {
        _errorMessage = '未找到兼容的设备服务';
        print(_errorMessage);
        notifyListeners();
      } else {
        print('成功找到并设置触发服务');
      }
    } catch (e) {
      _errorMessage = '服务发现失败: $e';
      print(_errorMessage);
      _setConnectionState(BtConnectionState.error);
    }
  }

  // ========== 触发方法 ==========
  void onRemoteTriggerPressed() {
    print('检测到远程触发！当前模式: $_currentTriggerType');
    // 这个方法会被外部监听，触发对应的拍照功能
    notifyListeners();
  }

  // 设置当前的触发类型
  void setTriggerType(PhotoTriggerType type) {
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