import 'dart:io';
import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:vehicle_control_system/pages/communication/s7_utils.dart';
import 'package:vehicle_control_system/pages/controls/custom_button.dart';
import 'package:vehicle_control_system/pages/controls/custom_card.dart';

//风行者标准款
class WindWalkerStandard extends StatefulWidget {
  const WindWalkerStandard({super.key});

  @override
  State<WindWalkerStandard> createState() => _WindWalkerLiftModelState();
}

class _WindWalkerLiftModelState extends State<WindWalkerStandard> {
  final ScrollController _scrollController = ScrollController();
  late String writeStatusLog = "无日志";
  Color _iconColor = Colors.red;
  String _carOpen = "车辆已关闭";

  //PLC默认IP  192.168.10.1
  final String ip = "192.168.10.1";
  bool isActive = false;

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
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              const SizedBox(height: 5),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                CustomCard(
                  screenWidth: MediaQuery.of(context).size.width,
                  title: '状态',
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
                      const SizedBox(height: 10),
                      const Divider(
                        color: Colors.grey, // 直线的颜色
                        thickness: 2.0, // 直线的厚度
                        indent: 0.0, // 左侧缩进
                        endIndent: 0.0, // 右侧缩进
                      ),
                      const SizedBox(height: 10),
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
                    title: '相对运行',
                    icon: FontAwesomeIcons.locationCrosshairs,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        //前进点动
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
                                final socket =
                                await Socket.connect(ip, 102);
                                print(
                                    'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
                                await S7utils.s7Connect(socket);
                                //此处还有地址没传
                                await S7utils.s7Write(socket, 0x10, 0x00,0x14);
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
                                final socket =
                                await Socket.connect(ip, 102);
                                print(
                                    'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
                                await S7utils.s7Connect(socket);
                                //此处还有地址没传
                                await S7utils.s7Write(socket, 0x00, 0x00,0x14);
                                // await S7utils.s7Read(socket);
                                // 关闭连接
                                await socket.close();
                              },
                              child: CustomButton(
                                  text: '前进点动',
                                  icon: Icons.arrow_upward,
                                  height: 50,
                                  width: 200,
                                  onPressed: () async {

                                  }),
                            ),
                          ],
                        ),
                        //后退点动
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
                                final socket =
                                await Socket.connect(ip, 102);
                                print(
                                    'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
                                await S7utils.s7Connect(socket);
                                //此处还有地址没传
                                await S7utils.s7Write(socket, 0x20, 0x00,0x14);
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
                                final socket =
                                await Socket.connect(ip, 102);
                                print(
                                    'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
                                await S7utils.s7Connect(socket);
                                //此处还有地址没传
                                await S7utils.s7Write(socket, 0x00, 0x00,0x14);
                                // await S7utils.s7Read(socket);
                                // 关闭连接
                                await socket.close();
                              },
                              child: CustomButton(
                                  text: '后退点动',
                                  icon: Icons.arrow_downward,
                                  height: 50,
                                  width: 200,
                                  onPressed: () async {

                                  }),
                            ),
                          ],
                        ),

                        //左转弯 未实现
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
                                final socket =
                                await Socket.connect(ip, 102);
                                print(
                                    'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
                                await S7utils.s7Connect(socket);
                                //此处还有地址没传
                                await S7utils.s7Write(socket, 0x80, 0x00,0x14);
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
                                final socket =
                                await Socket.connect(ip, 102);
                                print(
                                    'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
                                await S7utils.s7Connect(socket);
                                //此处还有地址没传
                                await S7utils.s7Write(socket, 0x00, 0x00,0x14);
                                // await S7utils.s7Read(socket);
                                // 关闭连接
                                await socket.close();
                              },
                              child: CustomButton(
                                  text: '左转弯',
                                  icon: Icons.arrow_back,
                                  height: 50,
                                  width: 200,
                                  onPressed: () async {

                                  }),
                            ),
                          ],
                        ),
                        //右转弯 未实现
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
                                final socket =
                                await Socket.connect(ip, 102);
                                print(
                                    'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
                                await S7utils.s7Connect(socket);
                                //此处还有地址没传
                                await S7utils.s7Write(socket, 0x40, 0x00,0x14);
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
                                final socket =
                                await Socket.connect(ip, 102);
                                print(
                                    'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
                                await S7utils.s7Connect(socket);
                                //此处还有地址没传
                                await S7utils.s7Write(socket, 0x00, 0x00,0x14);
                                // await S7utils.s7Read(socket);
                                // 关闭连接
                                await socket.close();
                              },
                              child: CustomButton(
                                  text: '右转弯',
                                  icon: Icons.arrow_forward,
                                  height: 50,
                                  width: 200,
                                  onPressed: () async {

                                  }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomCard(
                    screenWidth: MediaQuery.of(context).size.width,
                    title: '支撑电机运动控制',
                    icon: FontAwesomeIcons.elementor,
                    child: Column(
                      children: [
                        SizedBox(height: 20),
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
                                final socket =
                                await Socket.connect(ip, 102);
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
                                final socket =
                                await Socket.connect(ip, 102);
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
                                  text: '上升启动',
                                  icon: Icons.arrow_downward,
                                  height: 50,
                                  width: 200,
                                  onPressed: () async {
                                  }),
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
                                final socket =
                                await Socket.connect(ip, 102);
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
                                final socket =
                                await Socket.connect(ip, 102);
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
                                  text: '下降启动',
                                  icon: Icons.arrow_downward,
                                  height: 50,
                                  width: 200,
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
