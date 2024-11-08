import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vehicle_control_system/data/models/protocol_packet.dart';
import 'package:vehicle_control_system/pages/controls/counter_widget.dart';
import 'package:vehicle_control_system/pages/controls/custom_card_new.dart';
import 'package:vehicle_control_system/pages/controls/radio_option.dart';

class RobotiControlPanel extends StatefulWidget {
  @override
  _RobotiControlPanelState createState() => _RobotiControlPanelState();
}

class _RobotiControlPanelState extends State<RobotiControlPanel> {
  final TextEditingController ipController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController stepController = TextEditingController();
  String selectedOption = '基础';
  double _moveValue = 0.0;
  String selectedCoordinate = 'X'; // 默认坐标类型

  // 存储错误信息
  String? ipError;
  String? portError;
  String? stepError;

  // 连接状态
  String? connectionStatus;

  // 获取模式类型的整数值
  int get modeType {
    switch (selectedOption) {
      case '基础':
        return 1;
      case '工具':
        return 2;
      case '轴':
        return 3;
      default:
        return 1;
    }
  }

  // 获取坐标类型的整数值
  int get coordinateType {
    switch (selectedCoordinate) {
      case 'X':
        return 1;
      case 'Y':
        return 2;
      case 'Z':
        return 3;
      case 'RX':
        return 4;
      case 'RY':
        return 5;
      case 'RZ':
        return 6;
      default:
        return 1;
    }
  }

  @override
  void initState() {
    super.initState();
    // 设置默认值
    ipController.text = '127.0.0.1';
    portController.text = '8080';
    stepController.text = '1';  // 默认步长设置为 1 毫米
  }

  void _handleMoveValueChanged(newValue) {
    setState(() {
      _moveValue = newValue.toDouble();;
    });
  }

  // 验证 IP 地址
  bool _validateIP(String ip) {
    final RegExp ipRegExp = RegExp(r'^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.'
    r'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.'
    r'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.'
    r'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
    return ipRegExp.hasMatch(ip);
  }

  // 验证端口
  bool _validatePort(String port) {
    final int? portInt = int.tryParse(port);
    return portInt != null && portInt >= 1 && portInt <= 65535;
  }

  // 验证步长
  bool _validateStep(String step) {
    final double? stepValue = double.tryParse(step);
    return stepValue != null && stepValue >= 1 && stepValue <= 500;
  }

  // 发送 TCP 数据
// 发送 TCP 数据
  Future<void> _sendTCPData() async {
    final String ip = ipController.text;
    final String port = portController.text;

    if (!_validateIP(ip) || !_validatePort(port)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无效的 IP 或端口')),
      );
      return;
    }

    final stepLength = double.tryParse(stepController.text) ?? 1.0;
    final packet = ProtocolPacket(
      modeType: modeType,
      stepLength: stepLength,
      coordinateType: coordinateType,
      coordinateValue: _moveValue,
    );

    try {
      final socket = await Socket.connect(ip, int.parse(port), timeout: Duration(seconds: 5));
      print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');

      // 发送协议包数据
      final data = packet.toProtocolString();
      socket.write(data);
      print('Data sent: $data');

      socket.close();

      setState(() {
        connectionStatus = '连接成功';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('连接成功')),
      );
    } catch (e) {
      print('Error connecting to the socket: $e');

      setState(() {
        connectionStatus = '连接失败';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TCP 连接失败')),
      );
    }
  }

  Future<bool> testConnection(String ip, int port, {int timeoutSeconds = 5}) async {
    try {
      // 创建一个套接字连接
      final socket = await Socket.connect(
        ip,
        port,
        timeout: Duration(seconds: timeoutSeconds),
      );

      // 连接成功，关闭连接并返回 true
      socket.destroy();
      return true;
    } catch (e) {
      // 连接失败，返回 false
      print('连接失败: $e');
      return false;
    }
  }


  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final title = args?['title'] ?? 'Default Title';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _sendTCPData,  // 发送数据的回调
            child: const Text('数据发送', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            CustomCardNew(
              title: '连接设置',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ipController,
                          decoration: InputDecoration(
                            labelText: 'IP 地址',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            errorText: ipError,
                          ),
                          onChanged: (value) {
                            setState(() {
                              ipError = _validateIP(value) ? null : '请输入有效的 IP 地址';
                            });
                          },
                          onEditingComplete: () {
                            setState(() {
                              ipError = _validateIP(ipController.text) ? null : '请输入有效的 IP 地址';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: portController,
                          decoration: InputDecoration(
                            labelText: '端口',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            errorText: portError,
                          ),
                          onChanged: (value) {
                            setState(() {
                              portError = _validatePort(value) ? null : '请输入有效的端口号（1-65535）';
                            });
                          },
                          onEditingComplete: () {
                            setState(() {
                              portError = _validatePort(portController.text) ? null : '请输入有效的端口号（1-65535）';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          if (_validateIP(ipController.text) && _validatePort(portController.text)) {
                             int port = int.parse(portController.text);
                            //待处理
                            //_sendTCPData();
                             bool isConnected = await testConnection(ipController.text, port);
                             if (isConnected) {
                               print('连接成功');
                               connectionStatus = "连接成功";
                               // 这里可以添加连接成功的处理逻辑
                             } else {
                               print('连接失败');
                               connectionStatus = "连接失败";
                               // 这里可以添加连接失败的处理逻辑
                             }
                          } else {
                            // Show an error message if validation fails
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('IP 地址或端口无效，请检查')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('连接'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 连接状态提示
                  if (connectionStatus != null)
                    Text(
                      '连接状态: $connectionStatus',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: connectionStatus == '连接成功' ? Colors.green : Colors.red,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CustomCardNew(
              title: '模式选择',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => selectedOption = '基础'),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: '基础',
                          groupValue: selectedOption,
                          onChanged: (value) => setState(() => selectedOption = value!),
                        ),
                        const Text('基础'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => setState(() => selectedOption = '工具'),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: '工具',
                          groupValue: selectedOption,
                          onChanged: (value) => setState(() => selectedOption = value!),
                        ),
                        const Text('工具'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => setState(() => selectedOption = '轴'),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: '轴',
                          groupValue: selectedOption,
                          onChanged: (value) => setState(() => selectedOption = value!),
                        ),
                        const Text('轴'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CustomCardNew(
              title: '步长',
              child: Row(
                children: [
                  const Text('步长', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: stepController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        labelText: '1毫米到500毫米',
                        errorText: stepError,
                      ),
                      onChanged: (value) {
                        setState(() {
                          stepError = _validateStep(value) ? null : '请输入有效的步长（1-500毫米）';
                        });
                      },
                      onEditingComplete: () {
                        setState(() {
                          stepError = _validateStep(stepController.text) ? null : '请输入有效的步长（1-500毫米）';
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CustomCardNew(
              title: '坐标',
              child: Column(
                children: List.generate(6, (index) {
                  final axis = ['X', 'Y', 'Z', 'RX', 'RY', 'RZ'][index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: CounterWidget(
                      height: 80,
                      width: double.infinity,
                      title: axis,
                      initialValue: 0.0,
                      step: 0.01,
                      backgroundColor: Colors.grey[200],
                      iconColor: Colors.black,
                      textStyle: const TextStyle(fontSize: 18.0, color: Colors.black),
                      onChanged: _handleMoveValueChanged,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
