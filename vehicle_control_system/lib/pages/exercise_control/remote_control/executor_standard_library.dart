//履行者标准库
import 'dart:io';

import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:get/get.dart';
import 'package:vehicle_control_system/pages/communication/s7_utils.dart';
import 'dart:math';

import 'package:vehicle_control_system/pages/controls/custom_button.dart';
import 'package:vehicle_control_system/pages/controls/custom_card.dart';

class ExecutorStandardLibrary extends StatefulWidget {
  const ExecutorStandardLibrary({super.key});

  @override
  State<ExecutorStandardLibrary> createState() => _WindWalkerLiftModelState();
}

class _WindWalkerLiftModelState extends State<ExecutorStandardLibrary> {
  final ScrollController _scrollController = ScrollController();
  late String writeStatusLog = "无日志";
  Color _iconColor = Colors.red;
  String _carOpen = "车辆已关闭";

  //tcp
  final String ip = '192.168.0.10'; // 替换为你的服务器 IP 地址
  Socket? _socket;

  //PLC默认IP  192.168.10.1
  // final String ip = "192.168.10.1";
  bool isActive = false;

  @override
  void initState() {
    super.initState();
    print('initState');
    _connectToServer();
  }

  Future<void> _connectToServer() async {
    _socket = await Socket.connect(ip, 102);
    print(
        'Connected to: ${_socket!.remoteAddress.address}:${_socket!.remotePort}');
    await S7utils.s7Connect(_socket!);
  }

  @override
  void dispose() {
    print('dispose');
    _socket?.close();
    super.dispose();
  }

  void _sendCommand(String direction) async {
    if (_socket != null) {
      if (direction == "前") {
        print('前');
        await S7utils.s7Write(_socket!, 0x02, 0x20,0x0c);
      } else if (direction == "后") {
        print('后');
        await S7utils.s7Write(_socket!, 0x04, 0x20,0x0c);
      } else if (direction == "左") {
        print('左');
        // await S7utils.s7WriteUp(_socket!, 0x80, 0x07);
        await S7utils.s7Write(_socket!, 0x08, 0x20,0x0c);
      } else if (direction == "右") {
        print('右');
        await S7utils.s7Write(_socket!, 0x10, 0x20,0x0c);
      } else {
        print('中心');
        await S7utils.s7Write(_socket!, 0x00, 0x20,0x0c);
      }
    }
  }

  void _toggleIconColor() {
    setState(() {
      _iconColor = _iconColor == Colors.green ? Colors.red : Colors.green;
      _carOpen != "车辆已开启" ? Colors.red : Colors.green;
      _carOpen = _iconColor == Colors.red ? "车辆已关闭" : "车辆已开启";
      // writeStatusLog != "已连接" == Colors.red ? "车辆已关闭" : "车辆已开启";
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final title = args?['title'] ?? 'Default Title';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Scrollbar(
        // thumbVisibility: true,//始终显示滚动条
        // thickness: 30.0,//设置滚动条的厚度,
        controller: _scrollController,
        child: SingleChildScrollView(
          // physics: const NeverScrollableScrollPhysics(), //禁止上下滑动
          controller: _scrollController,
          child: Column(
            children: [
              const SizedBox(height: 5),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                CustomCard(
                  screenWidth: MediaQuery.of(context).size.width,
                  title: '',
                  icon: FontAwesomeIcons.landMineOn,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(children: [
                              // const SizedBox(width: 10),
                              Text(
                                _carOpen,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ]),
                          ),
                          IconButton(
                            onPressed: () {
                              // pingIP('8.8.8.8'); // 替换为你想要 ping 的 IP 地址
                              // CommonToast.pingIP('192.168.31.7').then((status) {
                              // });
                              // _toggleIconColor();
                              final ping = Ping(ip, count: 1);
                              ping.stream.listen((event) {
                                try {
                                  PingResponse entity =
                                  event.response as PingResponse;
                                  // if (event.response != null) {
                                  if (entity.ip != null) {
                                    print(
                                        'Ping response time: ${event.response!.time!.inMilliseconds} ms');
                                    setState(() {
                                      isActive = true;
                                    });
                                    setState(() {
                                      writeStatusLog = '已连接';
                                    });
                                    _toggleIconColor();
                                    // _onErrorMessageReceived(0, "已连接");
                                  } else if (entity.ip == null) {
                                    setState(() {
                                      isActive = false;
                                    });

                                    setState(() {
                                      writeStatusLog = '请接入目标设备局域网';
                                    });
                                  }
                                } catch (e, stackTrace) {
                                  // _onErrorMessageReceived(0, "请接入目标设备局域网.");
                                  // setState(() {
                                  //   writeStatusLog = '请接入目标设备局域网';
                                  // });
                                }
                              });
                            },
                            icon: const Icon(Icons.power_settings_new),
                            color: _iconColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      const Divider(
                        color: Colors.grey, // 直线的颜色
                        thickness: 2.0, // 直线的厚度
                        indent: 0.0, // 左侧缩进
                        endIndent: 0.0, // 右侧缩进
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const SizedBox(
                            // width: 0,
                              child: Text(
                                '车辆状态:',
                                textAlign: TextAlign.right,
                              )),
                          const SizedBox(width: 10),
                          Text(writeStatusLog),
                        ],
                      ),
                    ],
                  ),
                ),
              ]),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomCard(
                    screenWidth: MediaQuery.of(context).size.width,
                    title: '',
                    icon: FontAwesomeIcons.locationCrosshairs,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTapDown: (value) async {
                                    // CommonToast.showToastNew(context, "title", "onTapDown", [
                                    //   Text('data')
                                    // ]);
                                    // CommonToast.showToast('onTapDown');
                                    final socket = await Socket.connect(ip, 102);
                                    print(
                                        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
                                    await S7utils.s7Connect(socket);
                                    //此处还有地址没传
                                    await S7utils.s7Write(socket, 0x01, 0x30,0x14);
                                    // await S7utils.s7Read(socket);
                                    // 关闭连接
                                    await socket.close();
                                  },
                                  onTapUp: (value) async {
                                    // CommonToast.showToastNew(context, "title", "onTapUp", [
                                    //   Text('data')
                                    // ]);
                                    // CommonToast.showToast('onTapUp');
                                  },
                                  onTapCancel: () async {
                                    // CommonToast.showToast('onTapCancel');
                                    final socket = await Socket.connect(ip, 102);
                                    print(
                                        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
                                    await S7utils.s7Connect(socket);
                                    //此处还有地址没传
                                    await S7utils.s7Write(socket, 0x00, 0x30,0x14);
                                    // await S7utils.s7Read(socket);
                                    // 关闭连接
                                    await socket.close();
                                  },
                                  child: CustomButton(
                                      text: '电机上升',
                                      icon: Icons.arrow_downward,
                                      height: 50,
                                      width: 110,
                                      onPressed: () async {}),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTapDown: (value) async {
                                    // CommonToast.showToastNew(context, "title", "onTapDown", [
                                    //   Text('data')
                                    // ]);
                                    // CommonToast.showToast('onTapDown');
                                    final socket = await Socket.connect(ip, 102);
                                    print(
                                        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
                                    await S7utils.s7Connect(socket);
                                    //此处还有地址没传
                                    await S7utils.s7Write(socket, 0x02, 0x30,0x14);
                                    // await S7utils.s7Read(socket);
                                    // 关闭连接
                                    await socket.close();
                                  },
                                  onTapUp: (value) async {
                                    // CommonToast.showToastNew(context, "title", "onTapUp", [
                                    //   Text('data')
                                    // ]);
                                    // CommonToast.showToast('onTapUp');
                                  },
                                  onTapCancel: () async {
                                    // CommonToast.showToast('onTapCancel');
                                    final socket = await Socket.connect(ip, 102);
                                    print(
                                        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
                                    await S7utils.s7Connect(socket);
                                    //此处还有地址没传
                                    await S7utils.s7Write(socket, 0x00, 0x30,0x14);
                                    // await S7utils.s7Read(socket);
                                    // 关闭连接
                                    await socket.close();
                                  },
                                  child: CustomButton(
                                      text: '电机下降',
                                      icon: Icons.arrow_downward,
                                      height: 50,
                                      width: 110,
                                      onPressed: () async {
                                        // final socket = await Socket.connect(ip, 102);
                                        // print(
                                        //     'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
                                        // await S7utils.s7Connect(socket);
                                        // await S7utils.s7WriteDown(socket, 0x02, 0x30);
                                        // // await S7utils.s7Read(socket);
                                        // // 关闭连接
                                        // await socket.close();
                                      }),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Center(
                          child: Joystick(
                            listener: (details) {
                              //async
                              String direction =
                              getDirection(details.x, details.y);
                              print('操纵杆方向: $direction');
                              _sendCommand(direction);

                              // double angle = atan2(details.y, details.x) * (180 / pi);
                              // if (angle < 0) angle += 360; // 将角度转换为0-360度范围
                              // print('操纵杆角度: $angle°');
                              // print('操纵杆移动到: ${details.x}, ${details.y}');
                              //
                              //  String direction = getDirection(details.x, details.y);
                              //  // print('操纵杆方向: $direction');

                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }

  String getDirection(double x, double y) {
    if (y < -0.5) {
      return '前';
    } else if (y > 0.5) {
      return '后';
    } else if (x < -0.5) {
      return '左';
    } else if (x > 0.5) {
      return '右';
    } else {
      return '中心';
    }
  }
}
