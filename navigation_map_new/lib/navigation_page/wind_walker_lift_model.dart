import 'dart:io';

import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:navigation_map/utils/S7Client/S7Utils.dart';

import '../CustomUserControls/CustomCard.dart';
import '../custom_controls/custom_button.dart';

//风行者升降款
class WindWalkerLiftModel extends StatefulWidget {
  const WindWalkerLiftModel({super.key});

  @override
  State<WindWalkerLiftModel> createState() => _WindWalkerLiftModelState();
}

class _WindWalkerLiftModelState extends State<WindWalkerLiftModel> {
  final ScrollController _scrollController = ScrollController();
  late String writeStatusLog = "无日志";
  Color _iconColor = Colors.red;
  String _carOpen = "车辆已关闭";
  bool isActive = false;
  void _toggleIconColor() {
    setState(() {
      _iconColor = _iconColor == Colors.green ? Colors.red : Colors.green;
      _carOpen  != "车辆已开启" ? Colors.red : Colors.green;
      _carOpen = _iconColor == Colors.red ? "车辆已关闭" : "车辆已开启";
      // writeStatusLog != "已连接" == Colors.red ? "车辆已关闭" : "车辆已开启";
    });
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
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
                              final ping = Ping('192.168.0.5', count: 1);
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
                    child:  Column(
                      children: [
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CustomButton(
                              text: '上升启动',
                              icon: Icons.arrow_upward,
                              height: 50,
                              width: 200,
                              onPressed:() async {
                                //192.168.10.1
                                //192.168.0.5
                                final socket = await Socket.connect('192.168.10.1', 102);
                                print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
                                await S7utils.s7Connect(socket);
                                //此处还有地址没传
                                await S7utils.s7WriteUp(socket,0x00);
                                // await S7utils.s7Read(socket);
                                // 关闭连接
                                await socket.close();
                              }
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CustomButton(
                                text: '上升收起',
                                icon: Icons.arrow_downward,
                                height: 50,
                                width: 200,
                                onPressed:() async {
                                  //192.168.10.1
                                  //192.168.0.5
                                  final socket = await Socket.connect('192.168.10.1', 102);
                                  print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
                                  await S7utils.s7Connect(socket);
                                  await S7utils.s7WriteUp(socket,0x01);
                                  // await S7utils.s7Read(socket);
                                  // 关闭连接
                                  await socket.close();

                                }
                            ),
                          ],
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CustomButton(
                                text: '下降启动',
                                icon: Icons.arrow_downward,
                                height: 50,
                                width: 200,
                                onPressed:() async {
                                  //192.168.10.1
                                  //192.168.0.5
                                  final socket = await Socket.connect('192.168.10.1', 102);
                                  print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
                                  await S7utils.s7Connect(socket);
                                  await S7utils.s7WriteDown(socket,0x01);
                                  // await S7utils.s7Read(socket);
                                  // 关闭连接
                                  await socket.close();

                                }
                            ),
                          ],
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CustomButton(
                                text: '下降收起',
                                icon: Icons.arrow_downward,
                                height: 50,
                                width: 200,
                                onPressed:() async {
                                  //192.168.10.1
                                  //192.168.0.5
                                  final socket = await Socket.connect('192.168.10.1', 102);
                                  print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
                                  await S7utils.s7Connect(socket);
                                  await S7utils.s7WriteDown(socket,0x01);
                                  // await S7utils.s7Read(socket);
                                  // 关闭连接
                                  await socket.close();

                                }
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
