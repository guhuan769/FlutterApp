// lib/screens/bluetooth_debug_screen.dart
// 蓝牙设备调试工具，帮助识别设备的服务和特征

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothDebugScreen extends StatefulWidget {
  final BluetoothDevice device;

  const BluetoothDebugScreen({Key? key, required this.device}) : super(key: key);

  @override
  _BluetoothDebugScreenState createState() => _BluetoothDebugScreenState();
}

class _BluetoothDebugScreenState extends State<BluetoothDebugScreen> {
  List<BluetoothService>? _services;
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, List<int>> _lastValues = {};

  @override
  void initState() {
    super.initState();
    _discoverServices();
  }

  Future<void> _discoverServices() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // 检查连接状态
      if (await widget.device.connectionState.first == BluetoothConnectionState.disconnected) {
        await widget.device.connect();
      }

      // 发现服务
      final services = await widget.device.discoverServices();

      setState(() {
        _services = services;
        _isLoading = false;
      });

      // 自动订阅所有通知特征
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify || characteristic.properties.indicate) {
            try {
              await characteristic.setNotifyValue(true);
              characteristic.value.listen((value) {
                if (value.isNotEmpty) {
                  print('收到通知: ${characteristic.uuid}, 值: $value');
                  setState(() {
                    _lastValues[characteristic.uuid.toString()] = value;
                  });
                }
              });
            } catch (e) {
              print('设置通知失败: ${characteristic.uuid}, 错误: $e');
            }
          }
        }
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '发现服务失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('蓝牙设备调试: ${widget.device.name}'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _discoverServices,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
          : _buildServicesList(),
    );
  }

  Widget _buildServicesList() {
    if (_services == null || _services!.isEmpty) {
      return Center(child: Text('没有发现服务'));
    }

    return ListView.builder(
      itemCount: _services!.length,
      itemBuilder: (context, index) {
        final service = _services![index];
        final serviceUuid = service.uuid.toString().toUpperCase();

        // 判断是否是已知服务
        String serviceName = '未知服务';
        if (serviceUuid.contains('1812')) serviceName = 'HID服务';
        else if (serviceUuid.contains('180F')) serviceName = '电池服务';
        else if (serviceUuid.contains('180A')) serviceName = '设备信息服务';
        else if (serviceUuid.contains('FFE0')) serviceName = '自定义控制服务';
        else if (serviceUuid.contains('1800')) serviceName = '通用访问服务';
        else if (serviceUuid.contains('1801')) serviceName = '通用属性服务';

        return ExpansionTile(
          title: Text('$serviceName ($serviceUuid)'),
          subtitle: Text('${service.characteristics.length} 个特征'),
          children: service.characteristics.map((characteristic) {
            final charUuid = characteristic.uuid.toString().toUpperCase();
            final props = _getCharacteristicProperties(characteristic);
            final hasValue = _lastValues.containsKey(charUuid);

            return ListTile(
              title: Text(charUuid),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('属性: $props'),
                  if (hasValue)
                    Text('最近值: ${_formatHexValue(_lastValues[charUuid]!)}',
                      style: TextStyle(color: Colors.blue),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 读取按钮
                  if (characteristic.properties.read)
                    IconButton(
                      icon: Icon(Icons.download, size: 20),
                      onPressed: () => _readCharacteristic(characteristic),
                      tooltip: '读取',
                    ),

                  // 写入按钮
                  if (characteristic.properties.write)
                    IconButton(
                      icon: Icon(Icons.upload, size: 20),
                      onPressed: () => _writeCharacteristicDialog(characteristic),
                      tooltip: '写入',
                    ),

                  // 通知开关
                  if (characteristic.properties.notify || characteristic.properties.indicate)
                    IconButton(
                      icon: Icon(
                        Icons.notifications,
                        size: 20,
                        color: hasValue ? Colors.blue : null,
                      ),
                      onPressed: () => _toggleNotification(characteristic),
                      tooltip: '通知',
                    ),
                ],
              ),
              onTap: () {
                // 复制UUID到剪贴板
                Clipboard.setData(ClipboardData(text: charUuid));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已复制特征UUID到剪贴板')),
                );
              },
              onLongPress: () => _showCharacteristicInfo(characteristic),
            );
          }).toList(),
        );
      },
    );
  }

  // 格式化特征属性
  String _getCharacteristicProperties(BluetoothCharacteristic char) {
    List<String> props = [];
    if (char.properties.broadcast) props.add('广播');
    if (char.properties.read) props.add('读');
    if (char.properties.writeWithoutResponse) props.add('无回应写');
    if (char.properties.write) props.add('写');
    if (char.properties.notify) props.add('通知');
    if (char.properties.indicate) props.add('指示');
    if (char.properties.authenticatedSignedWrites) props.add('认证写');

    return props.join(', ');
  }

  // 格式化十六进制显示
  String _formatHexValue(List<int> value) {
    if (value.isEmpty) return '空';
    return '[${value.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ')}]';
  }

  // 读取特征值
  Future<void> _readCharacteristic(BluetoothCharacteristic characteristic) async {
    try {
      final value = await characteristic.read();
      setState(() {
        _lastValues[characteristic.uuid.toString()] = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('读取成功: ${_formatHexValue(value)}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('读取失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 写入特征值对话框
  Future<void> _writeCharacteristicDialog(BluetoothCharacteristic characteristic) async {
    final TextEditingController controller = TextEditingController();

    final bool? writeConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('写入特征值'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('输入十六进制值 (如: 01, 02, FF)'),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '如: 01 02 FF',
                helperText: '用空格分隔多个值',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('写入'),
          ),
        ],
      ),
    );

    if (writeConfirmed == true && controller.text.isNotEmpty) {
      try {
        // 解析十六进制输入
        final List<int> valueToWrite = controller.text
            .split(RegExp(r'[,\s]+'))
            .where((s) => s.isNotEmpty)
            .map((s) => int.parse(s.replaceAll('0x', ''), radix: 16))
            .toList();

        if (valueToWrite.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('无效的输入'), backgroundColor: Colors.red),
          );
          return;
        }

        // 写入特征值
        await characteristic.write(valueToWrite);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('写入成功: ${_formatHexValue(valueToWrite)}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('写入失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 切换通知状态
  Future<void> _toggleNotification(BluetoothCharacteristic characteristic) async {
    try {
      final String uuid = characteristic.uuid.toString();
      final bool currentState = _lastValues.containsKey(uuid);

      if (currentState) {
        // 关闭通知
        await characteristic.setNotifyValue(false);
        setState(() {
          _lastValues.remove(uuid);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已关闭通知')),
        );
      } else {
        // 开启通知
        await characteristic.setNotifyValue(true);

        // 监听值更新
        characteristic.value.listen((value) {
          if (value.isNotEmpty) {
            setState(() {
              _lastValues[uuid] = value;
            });
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已开启通知')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('切换通知失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 显示特征详细信息
  void _showCharacteristicInfo(BluetoothCharacteristic characteristic) {
    final charUuid = characteristic.uuid.toString().toUpperCase();
    // 直接使用服务UUID，不尝试访问service属性
    final serviceUuid = "未知服务";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('特征详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('特征UUID: $charUuid'),
            Text('服务UUID: $serviceUuid'),
            Text('属性: ${_getCharacteristicProperties(characteristic)}'),
            Divider(),
            Text('建议添加到蓝牙提供者中的代码:'),
            SizedBox(height: 8),
            SelectableText(
                """// 添加到POSSIBLE_SERVICE_UUIDS列表:
"${serviceUuid.substring(0, 4)}",

// 添加到POSSIBLE_CHARACTERISTIC_UUIDS列表:
"${charUuid.substring(0, 4)}","""
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                  text:
                  """// 添加到POSSIBLE_SERVICE_UUIDS列表:
"${serviceUuid.substring(0, 4)}",

// 添加到POSSIBLE_CHARACTERISTIC_UUIDS列表:
"${charUuid.substring(0, 4)}","""
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已复制建议代码到剪贴板')),
              );
              Navigator.pop(context);
            },
            child: Text('复制代码'),
          ),
        ],
      ),
    );
  }
}