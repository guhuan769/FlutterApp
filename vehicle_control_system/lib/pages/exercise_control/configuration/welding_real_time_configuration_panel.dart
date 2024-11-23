import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vehicle_control_system/data/models/EnergyField.dart';
import 'package:vehicle_control_system/data/models/title_item.dart';
import 'package:get/get.dart';
import 'package:vehicle_control_system/pages/controls/counter_widget.dart';
import 'package:vehicle_control_system/pages/controls/custom_card_new.dart';
import 'package:vehicle_control_system/pages/controls/icon_text_button.dart';

class WeldingRealTimeConfigurationPanel extends StatefulWidget {
  const WeldingRealTimeConfigurationPanel({super.key});

  @override
  State<WeldingRealTimeConfigurationPanel> createState() => _WeldingRealTimeConfigurationPanelState();
}

class _WeldingRealTimeConfigurationPanelState extends State<WeldingRealTimeConfigurationPanel> {

  final TextEditingController ipController = TextEditingController();
  final TextEditingController portController = TextEditingController();

  // 存储错误信息
  String? ipError;
  String? portError;
  String? stepError;

  // 定义字段配置
  static const List<EnergyField> fields = [
    EnergyField(key:'current', label: '电流',unit:  '安',maxValue: 500,minValue: 100,autoIncrementValue: 1),
    EnergyField(key: 'voltage',label:  '电压',unit:  '伏特',maxValue: 40,minValue: 10,autoIncrementValue: 0.1),
  ];

  // 定义控制器
  final Map<String, TextEditingController> energyControllers = {
    'current': TextEditingController(text: '0'),
    'voltage': TextEditingController(text: '0'),
  };

  // 获取值的方法
  Map<String, double> getValues() {
    return {
      'current': double.tryParse(energyControllers['current']?.text ?? '0') ?? 0,
      'voltage': double.tryParse(energyControllers['voltage']?.text ?? '0') ?? 0,
    };
  }

  // 连接状态
  String? connectionStatus;

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

  Future<bool> testConnection(String ip, int port,
      {int timeoutSeconds = 5}) async {
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
  void initState() {
    // TODO: implement initState
    super.initState();

    ipController.text = '127.0.0.1';
    portController.text = '9998';
  }

  @override
  void dispose() {
    energyControllers.forEach((_, controller) => controller.dispose());
    // TODO: implement dispose
    super.dispose();
  }

  void _handleGoValueChanged(newValue,key) {
    setState(() {
      // _goValue = newValue;
    });
    print(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('焊接实时配置'),),
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
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            errorText: ipError,
                          ),
                          onChanged: (value) {
                            setState(() {
                              ipError =
                              _validateIP(value) ? null : '请输入有效的 IP 地址';
                            });
                          },
                          onEditingComplete: () {
                            setState(() {
                              ipError = _validateIP(ipController.text)
                                  ? null
                                  : '请输入有效的 IP 地址';
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
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            errorText: portError,
                          ),
                          onChanged: (value) {
                            setState(() {
                              portError = _validatePort(value)
                                  ? null
                                  : '请输入有效的端口号（1-65535）';
                            });
                          },
                          onEditingComplete: () {
                            setState(() {
                              portError = _validatePort(portController.text)
                                  ? null
                                  : '请输入有效的端口号（1-65535）';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          if (_validateIP(ipController.text) &&
                              _validatePort(portController.text)) {
                            int port = int.parse(portController.text);
                            //待处理
                            //_sendTCPData();
                            bool isConnected =
                            await testConnection(ipController.text, port);
                            if (isConnected) {
                              print('连接成功');
                              setState(() {
                                connectionStatus = "连接成功";
                              });
                              // 这里可以添加连接成功的处理逻辑
                            } else {
                              print('连接失败');
                              setState(() {
                                connectionStatus = "连接失败";
                              });
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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
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
                        color: connectionStatus == '连接成功'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                ],
              ),
            ),
            CustomCardNew(
              title: '能源监控',
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 10.0,
                  childAspectRatio: 3.0,  // 控制每个 TextField 的宽高比
                  physics: NeverScrollableScrollPhysics(), // 禁用滚动
                //     final Map<String, String> energyMap = {
                // 'current': '电流(安)',
                // 'voltage': '电压(伏特)',
                // };

                children: fields.map((field) {
                    return TextField(
                      controller: energyControllers[field.key],
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: '${field.label}(${field.unit})',
                        border: OutlineInputBorder(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            CustomCardNew(
              title: '调节电流电压',
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    GridView.count(
                      crossAxisCount: 1,
                      shrinkWrap: true,
                      mainAxisSpacing: 10.0,
                      crossAxisSpacing: 10.0,
                      childAspectRatio: 5.0,  // 控制每个 TextField 的宽高比
                      physics: NeverScrollableScrollPhysics(), // 禁用滚动
                      children: fields.map((field) {
                        return CounterWidget(
                          height: 80,
                          width: 200,
                          title: '${field.label} (${field.unit})',
                          initialValue: field.minValue!,
                          step: field.autoIncrementValue!,
                          maxValue: field.maxValue,  // 可选值
                          minValue: field.minValue,  // 可选值
                          maxErrorText: field.maxValue != null
                              ? '${field.label}不能超过${field.maxValue}${field.unit}'
                              : null,
                          minErrorText: field.minValue != null
                              ? '${field.label}不能小于${field.minValue}${field.unit}'
                              : null,
                          backgroundColor: Colors.transparent,
                          iconColor: Colors.black,
                          textStyle: const TextStyle(
                              fontSize: 25.0, color: Colors.black),
                          onChanged: (value)=>_handleGoValueChanged(value,field.key),
                        );

                        //   TextField(
                        //   controller: energyControllers[axis],
                        //   readOnly: true,
                        //   decoration: InputDecoration(
                        //     labelText: axis,
                        //     border: OutlineInputBorder(),
                        //   ),
                        // );
                      }).toList(),
                    )
                    ,
                    const SizedBox(
                      height: 20,
                    ),
                    GestureDetector(
                      onLongPressStart: (details) {
                        print('onLongPressStart');
                        // _startTimerPositon(1);
                      },
                      onLongPressEnd: (details) {
                        print('onLongPressEnd');
                        // _stopTimerPositon();
                      },
                      child: IconTextButton(
                        filled: true,
                        height: 50,
                        width: 150,
                        icon: Icons.send,
                        text: '发送',
                        iconColor: Colors.grey,
                        textColor: Colors.grey,
                        iconSize: 30.0,
                        textSize: 20.0,
                        onPressed: () {
                          // _sportControl(1);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CustomCardNew(
              title: '调节机器人偏移',
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 10.0,
                  childAspectRatio: 3.0,  // 控制每个 TextField 的宽高比
                  physics: NeverScrollableScrollPhysics(), // 禁用滚动
                  children: ['电流(安)', '电压(伏特)'].map((axis) {
                    return TextField(
                      controller: energyControllers[axis],
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: axis,
                        border: OutlineInputBorder(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
