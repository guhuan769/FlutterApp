import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vehicle_control_system/data/enum/ToastType.dart';
import 'package:vehicle_control_system/data/models/protocol_packet.dart';
import 'package:vehicle_control_system/pages/communication/tcp_server.dart';
import 'package:vehicle_control_system/pages/controls/counter_widget_four.dart';
import 'package:vehicle_control_system/pages/controls/custom_card_new.dart';
import 'package:vehicle_control_system/pages/controls/toast.dart';

class RobotiControlPanel extends StatefulWidget {
  @override
  _RobotiControlPanelState createState() => _RobotiControlPanelState();
}

class _RobotiControlPanelState extends State<RobotiControlPanel> {
  final TextEditingController ipController = TextEditingController();
  final TextEditingController portController = TextEditingController();

  final Map<String, TextEditingController> coordinateControllers = {
    'X': TextEditingController(text: '0'),
    'Y': TextEditingController(text: '0'),
    'Z': TextEditingController(text: '0'),
    'RX': TextEditingController(text: '0'),
    'RY': TextEditingController(text: '0'),
    'RZ': TextEditingController(text: '0'),
  };

  //是否收到信息
  bool isInformation = true;

  Socket? _socket;
  StreamSubscription? _subscription;

  final TcpServer _tcpServer = TcpServer();
  String _receivedData = '等待数据...';

  Future<void> _startTcpServer() async {
    // 启动 TCP 服务端，监听地址为 0.0.0.0，端口为 9098
    await _tcpServer.startServer(address: '0.0.0.0', port: 9999);

    // 订阅数据流
    _tcpServer.dataStream.listen((data) {
      setState(() {
        _receivedData = data; // 更新界面显示
      });

      setState(() {
        isInformation = true;
      });

      Toast.show(
        context,
        "收到一条来自服务端的消息 ",
        type: ToastType.success,
      );

      print("订阅数据" + _receivedData);

      ProtocolPacket packet = ProtocolPacket.fromProtocolString(_receivedData);

      _updateCoordinates(_receivedData);

      String coordinateType = getCoordinateType(packet.coordinateType);

      if (coordinateControllers.containsKey(coordinateType)) {
        setState(() {
          coordinateControllers[coordinateType]!.text = packet.coordinateValue.toString();
        });
      }

    });
  }

  String getCoordinateType(int coordinateType) {
    switch (coordinateType) {
      case 1:
        return 'X';
      case 2:
        return 'Y';
      case 3:
        return 'Z';
      case 4:
        return 'RX';
      case 5:
        return 'RY';
      case 6:
        return 'RZ';
      default:
        return 'Unknown';
    }
  }

  // 连接并接收数据
  Future<void> _connectAndListen() async {
    final ip = ipController.text;
    final port = int.parse(portController.text);

    print('我爱你${ip} : ${port}');
    try {
      // _socket = await Socket.connect(ip, port);
      _socket = await Socket.connect("0.0.0.0", 9999);
      _subscription = _socket!.listen((data) {
        String receivedData = String.fromCharCodes(data);
        print('我爱你  ====== object');
        _updateCoordinates(receivedData);
      });
      setState(() {
        connectionStatus = '连接成功';
      });
    } catch (e) {
      setState(() {
        connectionStatus = '连接失败';
      });
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('TCP 连接失败')),
      // );
      Toast.show(
        context,
        "TCP 连接失败 ",
        type: ToastType.error,
      );
    }
  }

  // 解析并更新坐标
  void _updateCoordinates(String data) {
    final Map<String, double> coordinates = parseData(data);

    coordinates.forEach((axis, value) {
      if (coordinateControllers.containsKey(axis)) {
        setState(() {
          coordinateControllers[axis]!.text = value.toString();
        });
      }
    });
  }

  @override
  void dispose() {
    // _socket?.close();
    // _subscription?.cancel();
    // super.dispose();
    print("dispose");
    _tcpServer.stopServer();
    super.dispose();
  }

  // 假设数据格式为 "X:1.0,Y:2.0,Z:3.0,RX:4.0,RY:5.0,RZ:6.0"
  Map<String, double> parseData(String data) {
    final Map<String, double> result = {};
    final pairs = data.split(',');

    for (var pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = double.tryParse(parts[1].trim()) ?? 0.0;
        result[key] = value;
      }
    }
    return result;
  }

  String selectedOption = '基础';
  num _moveValue = 0.0;
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
    portController.text = '9999';
    _startTcpServer();
  }

  void _handleMoveValueChanged(newValue) {
    setState(() {
      _moveValue = newValue.toDouble();
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
    print(_moveValue);
    if (!_validateIP(ip) || !_validatePort(port)) {
      Toast.show(
        context,
        "无效的 IP 或端口",
        type: ToastType.warning,
      );
      return;
    }

    final packet = ProtocolPacket(
      modeType: modeType,
      coordinateType: coordinateType,
      coordinateValue: _moveValue,
    );

    try {
      final socket = await Socket.connect(ip, int.parse(port),
          timeout: Duration(seconds: 5));
      print(
          'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');

      // 发送协议包数据
      final data = packet.toProtocolString();
      socket.write(data);
      print('Data sent: $data');

      socket.close();

      setState(() {
        connectionStatus = '连接成功';
      });
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('连接成功-数据发送')),
      // );
      // 提示信息
      Toast.show(
        context,
        "连接成功-数据发送 ",
        type: ToastType.success,
      );
    } catch (e) {
      print('Error connecting to the socket: $e');

      setState(() {
        connectionStatus = '连接失败';
      });
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('TCP 连接失败')),
      // );

      Toast.show(
        context,
        "连接失败 ",
        type: ToastType.error,
      );

    }
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
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final title = args?['title'] ?? 'Default Title';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // TextButton(
          //   onPressed: _sendTCPData, // 发送数据的回调
          //   child: const Text('数据发送', style: TextStyle(color: Colors.black)),
          // ),
          // TextButton(
          //   onPressed: _startTcpServer, // 开始 TCP 连接
          //   child: const Text('连接', style: TextStyle(color: Colors.black)),
          // ),
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
                          onChanged: (value) =>
                              setState(() => selectedOption = value!),
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
                          onChanged: (value) =>
                              setState(() => selectedOption = value!),
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
                          onChanged: (value) =>
                              setState(() => selectedOption = value!),
                        ),
                        const Text('轴'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 连接设置、模式选择等...
            CustomCardNew(
              title: '当前位置',
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 10.0,
                  physics: NeverScrollableScrollPhysics(), // 禁用滚动
                  children: ['X', 'Y', 'Z', 'RX', 'RY', 'RZ'].map((axis) {
                    return TextField(
                      controller: coordinateControllers[axis],
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


            // CustomCardNew(
            //   title: '当前位置',
            //   child: Column(
            //     children: ['X', 'Y', 'Z', 'RX', 'RY', 'RZ'].map((axis) {
            //       return Padding(
            //         padding: EdgeInsets.symmetric(vertical: 5.0),
            //         child: TextField(
            //           controller: coordinateControllers[axis],
            //           readOnly: true,
            //           decoration: InputDecoration(
            //             labelText: axis,
            //             border: OutlineInputBorder(),
            //           ),
            //         ),
            //       );
            //     }).toList(),
            //   ),
            // ),
            // 其他控件...
            const SizedBox(height: 20),
            CustomCardNew(
              title: '机器人坐标',
              child: Column(
                children: List.generate(6, (index) {
                  final axis = ['X', 'Y', 'Z', 'RX', 'RY', 'RZ'][index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child:CounterWidgetFour(
                      initialValue: 0,
                      step: 1,
                      title: axis,
                      backgroundColor: Colors.grey.shade200,
                      iconColor: Colors.blue,
                      textStyle: const TextStyle(fontSize: 20, color: Colors.black),
                      titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      onLeftPressed: (value){
                        setState(() {
                          _moveValue = value;
                          selectedCoordinate = axis;
                        });
                        if(isInformation == true)
                        {
                          _sendTCPData();
                          setState(() {
                            isInformation = false;
                          });
                        }
                        else
                        {
                          Toast.show(
                            context,
                            "没有收到服务端回传信息!",
                            type: ToastType.error,
                          );
                        }

                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   const SnackBar(content: Text('Left')),
                        //
                        // );
                        print('left---${value}');
                      },
                      onRightPressed: (value){
                        setState(() {
                          _moveValue = value;
                          selectedCoordinate = axis;
                        });
                        // 提示信息
                        if(isInformation == true)
                        {
                          _sendTCPData();
                          setState(() {
                            isInformation = false;
                          });
                        }
                        else
                        {
                          Toast.show(
                            context,
                            "没有收到服务端回传信息!",
                            type: ToastType.error,
                          );
                        }

                      },
                      onChanged: _handleMoveValueChanged,
                    ),
                    // CounterWidgetFour(
                    //   height: 80,
                    //   width: double.infinity,
                    //   title: axis,
                    //   initialValue: 0,
                    //   step: 1,
                    //   backgroundColor: Colors.grey[200],
                    //   iconColor: Colors.black,
                    //   textStyle:
                    //       const TextStyle(fontSize: 18.0, color: Colors.black),
                    //   onChanged: _handleMoveValueChanged,
                    // ),
                  );
                }),
              ),
            ),
            // CustomCardNew(
            //   title: "日志",
            //   child: StreamBuilder<String>(
            //     stream: _tcpServer.dataStream,
            //     builder: (context, snapshot) {
            //       print('Connection State: ${snapshot.connectionState}');
            //       print('Has Data: ${snapshot.hasData}');
            //       print('Data: ${snapshot.data}');
            //
            //       if (snapshot.connectionState == ConnectionState.waiting) {
            //         return Center(child: CircularProgressIndicator());
            //       } else if (snapshot.hasError) {
            //         return Center(child: Text('发生错误: ${snapshot.error}'));
            //       } else if (!snapshot.hasData) {
            //         return Center(child: Text('等待数据...'));
            //       } else {
            //         return ListView(
            //           children: [
            //             Text(snapshot.data!),
            //           ],
            //         );
            //       }
            //     },
            //   ),
            // )
          ],
        ),
      ),
    );
  }
}
