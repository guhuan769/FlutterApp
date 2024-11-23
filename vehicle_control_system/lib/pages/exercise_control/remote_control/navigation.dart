import 'dart:async';
import 'dart:convert';
// import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vehicle_control_system/data/models/send_data.dart';
import 'package:get/get.dart';
import 'package:vehicle_control_system/pages/communication/s7_utils.dart';
import 'package:vehicle_control_system/pages/communication/udp_helper.dart';
import 'package:vehicle_control_system/pages/controls/counter_widget.dart';
import 'package:vehicle_control_system/pages/controls/custom_button.dart';
import 'package:vehicle_control_system/pages/controls/custom_card.dart';
import 'package:vehicle_control_system/pages/controls/icon_text_button.dart';
import 'package:vehicle_control_system/tool_box/common_toast.dart';

//智行者/领航者通用
class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

// Text(
// '这是一个示例文本',
// textAlign: TextAlign.right,
// )

class _NavigationState extends State<Navigation> {
  late String writeLog = "无日志";
  late String writeStatusLog = "无日志";

  late UdpHelper _udpHelper;
  bool isActive = false;
  Timer? _timer;

  final ScrollController _scrollController = ScrollController();

  // 创建一个 TextEditingController 并设置默认值 relativeOperation
  // 相对运行
  final TextEditingController _relativeOperation =
  TextEditingController(text: "0.1,0,0");

  final FocusNode _focusNode = FocusNode();

  final TextEditingController _startController =
  TextEditingController(text: "0");
  final TextEditingController _endController = TextEditingController(text: "0");

  final TextEditingController _backStartController =
  TextEditingController(text: "0");
  final TextEditingController _backEndController =
  TextEditingController(text: "0");

  // 绝对运行
  final TextEditingController _absolutelyRunning =
  TextEditingController(text: "0,0,0");

  void _startUdpListener(Uint8List sendAll) async {
    var destinationAddress = InternetAddress("172.31.90.200"); // 替换为您的广播地址
    // Uint8List returnData = Uint8List(0);
    await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8456)
        .then((RawDatagramSocket udpSocket) async {
      udpSocket.broadcastEnabled = true;
      udpSocket.listen((e) {
        Datagram? dg = udpSocket.receive();
        if (dg != null) {
          // returnData = Uint8List(dg.data.length);
          // returnData = dg.data;
          // setState(() {
          _relativeOperation.text = "10,1,${dg.data}";
          // });
          print("接收到数据：${utf8.decode(dg.data)}");
          // showToast("接收到数据：${utf8.decode(dg.data)}");
        }
      });

      udpSocket.send(sendAll, destinationAddress, 9331);
    });
  }

  //
  //
  Timer? _timerPostion;
  int count = 0;

  // 定时器
  void _startTimerPositon(int value) {
    _timerPostion = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _sportControl(value, isTimer: true);
    });
  }

  void _sportControl(int value, {bool isTimer = false}) {
    String relativeOperation = "$_goValue,$_moveValue,$_themeValue";
    if (value == 1) {
      relativeOperation = "$_goValue,0,0"; // 前进后退
    } else if (value == 2) {
      relativeOperation = "0,$_moveValue,0"; //左右移动
    } else if (value == 3) {
      relativeOperation = "0,0,$_themeValue"; // 转弯
    }
    //临时测试
    List<dynamic> relativeOperationList =
    relativeOperation.split(','); // 使用短横线和竖线作为分隔符

    SendAddressData data_0x5e0 = SendAddressData(
        address: 0x5e0, length: 12, datas: relativeOperationList);
    SendAddressData data_0x5f1 =
    SendAddressData(address: 0x5f1, length: 1, data: 1);
    List<SendAddressData> dataList = [];
    dataList.add(data_0x5e0);
    dataList.add(data_0x5f1);

    SendData sendData = SendData(
        cRCHigh: null, cRCLow: null, cmd: 2, sn: 10, sendAddressData: dataList);

    sendData.buildBytesAddCrc();

    // sendData
    Uint8List sendAll = sendData.buildAllBytes();
    _sendUdpMessage(sendAll);

    SendData sendParseData = SendData(
        cRCHigh: null, cRCLow: null, cmd: 0, sn: 0, sendAddressData: null);
    sendParseData.Parse(sendAll);

    if (isTimer) {
      setState(() {
        count++;
        writeLog = "数据已发送 +$count";
      });
      // print('任务执行中...');
    } else {
      setState(() {
        writeLog = "数据已发送";
      });
    }
  }

  void _stopTimerPositon() {
    setState(() {
      count = 0;
    });
    _timerPostion?.cancel();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _startTimer();
    // _focusNode.addListener(() {
    //   if (_focusNode.hasFocus) {
    //     _focusNode.unfocus();
    //   }
    // });

    _udpHelper = UdpHelper(_onUdpDataReceived, _onErrorMessageReceived);
    _udpHelper.startListening();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        // _controller.clear();
        writeLog = "无";
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onUdpDataReceived(String data) {
    // setState(() {
    // 处理接收到的数据
    print('Received: $data');
    _relativeOperation.text = "10,1,$data";
    // });
  }

  void _onErrorMessageReceived(int code, String msg) {
    CommonToast.showToastNew(
      context,
      "提示",
      msg,
      [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // 关闭对话框
          },
          child: Text(
            "关闭",
            style: Theme.of(context).dialogTheme.titleTextStyle,
          ),
        ),
      ],
    );
  }

  void _sendUdpMessage(Uint8List data) {
    //TODO: 该处IP 应该从本地数据库取
    var destinationAddress = InternetAddress("192.168.31.7"); // 替换为您的广播地址
    _udpHelper.sendMsgDataFrame(data, destinationAddress, 9331);
  }

  final TextEditingController _controller = TextEditingController();
  Color _indicatorColor = Colors.grey;

  void _updateIndicatorColor(String text) {
    setState(() {
      if (text.isEmpty) {
        _indicatorColor = Colors.grey;
      } else if (text.length < 3) {
        _indicatorColor = Colors.red;
      } else {
        _indicatorColor = Colors.green;
      }
    });
  }

  double _goValue = 0.0;
  double _moveValue = 0.0;
  double _themeValue = 0.0;

  void _handleGoValueChanged(newValue) {
    setState(() {
      _goValue = newValue;
    });
    print(newValue);
  }

  void _handleMoveValueChanged(newValue) {
    setState(() {
      _moveValue = newValue;
    });
  }

  void _handleThemeValueChanged(newValue) {
    setState(() {
      _themeValue = newValue;
    });
    // _onErrorMessageReceived(0, newValue);
  }

  //图标
  Color _iconColor = Colors.red;
  String _carOpen = "车辆已关闭";

  void _toggleIconColor() {
    setState(() {
      _iconColor = _iconColor == Colors.green ? Colors.red : Colors.green;
      writeStatusLog  != "已连接" ? Colors.red : Colors.green;
      _carOpen = _iconColor == Colors.red ? "车辆已关闭" : "车辆已开启";
      // writeStatusLog != "已连接" == Colors.red ? "车辆已关闭" : "车辆已开启";
    });
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    final args = Get.arguments as Map<String, dynamic>?;
    final title = args?['title'] ?? 'Default Title';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          // 确保SingleChildScrollView 与Scrollbar使用相同的 _scrollController ，否则会报错
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
                              final ping = Ping('192.168.31.7', count: 1);
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
                                  }
                                } catch (e, stackTrace) {
                                  // _onErrorMessageReceived(0, "请接入目标设备局域网.");
                                  setState(() {
                                    writeStatusLog = '请接入目标设备局域网';
                                  });
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
                        Row(
                          children: [
                            Expanded(
                              child: CounterWidget(
                                height: 80,
                                width: 200,
                                title: '前进后退',
                                initialValue: 0.0,
                                step: 0.01,
                                backgroundColor: Colors.grey[200],
                                iconColor: Colors.black,
                                textStyle: const TextStyle(
                                    fontSize: 25.0, color: Colors.black),
                                onChanged: _handleGoValueChanged,
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            GestureDetector(
                              onLongPressStart: (details) {
                                print('onLongPressStart');
                                _startTimerPositon(1);
                              },
                              onLongPressEnd: (details) {
                                print('onLongPressEnd');
                                _stopTimerPositon();
                              },
                              child: IconTextButton(
                                filled: true,
                                height: 60,
                                width: 120,
                                icon: Icons.send,
                                text: '发送',
                                iconColor: Colors.grey,
                                textColor: Colors.grey,
                                iconSize: 30.0,
                                textSize: 20.0,
                                onPressed: () {
                                  _sportControl(1);
                                  // _onErrorMessageReceived(0, "数据发送成功");
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: CounterWidget(
                                height: 80,
                                width: 200,
                                title: '左右移动',
                                initialValue: 0.0,
                                step: 0.01,
                                backgroundColor: Colors.grey[200],
                                iconColor: Colors.black,
                                textStyle: const TextStyle(
                                    fontSize: 25.0, color: Colors.black),
                                onChanged: _handleMoveValueChanged,
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            GestureDetector(
                              onLongPressStart: (details) {
                                print('onLongPressStart');
                                _startTimerPositon(2);
                              },
                              onLongPressEnd: (details) {
                                print('onLongPressEnd');
                                _stopTimerPositon();
                              },
                              child: IconTextButton(
                                filled: true,
                                height: 60,
                                width: 120,
                                icon: Icons.send,
                                text: '发送',
                                iconColor: Colors.grey,
                                textColor: Colors.grey,
                                iconSize: 30.0,
                                textSize: 20.0,
                                onPressed: () {
                                  _sportControl(2);
                                  // _onErrorMessageReceived(0, "数据发送成功");
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: CounterWidget(
                                height: 80,
                                width: 200,
                                title: '车辆角度',
                                initialValue: 0.0,
                                step: 0.01,
                                backgroundColor: Colors.grey[200],
                                iconColor: Colors.black,
                                textStyle: const TextStyle(
                                    fontSize: 25.0, color: Colors.black),
                                onChanged: _handleThemeValueChanged,
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            GestureDetector(
                              onLongPressStart: (details) {
                                print('onLongPressStart');
                                _startTimerPositon(3);
                              },
                              onLongPressEnd: (details) {
                                print('onLongPressEnd');
                                _stopTimerPositon();
                              },
                              child: IconTextButton(
                                filled: true,
                                height: 60,
                                width: 120,
                                icon: Icons.send,
                                text: '发送',
                                iconColor: Colors.grey,
                                textColor: Colors.grey,
                                iconSize: 30.0,
                                textSize: 20.0,
                                onPressed: () {
                                  _sportControl(3);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(
                          color: Colors.grey, // 直线的颜色
                          thickness: 2.0, // 直线的厚度
                          indent: 0.0, // 左侧缩进
                          endIndent: 0.0, // 右侧缩进
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconTextButton(
                              filled: true,
                              height: 40,
                              width: 100,
                              icon: FontAwesomeIcons.readme,
                              text: '说明书',
                              iconColor: Colors.grey,
                              textColor: Colors.grey,
                              iconSize: 20.0,
                              textSize: 15.0,
                              onPressed: () {
                                _onErrorMessageReceived(0,
                                    "注意\n (坐标X,坐标Y,角度Theta -3.14~3.14) \n相对运行(x(前进 (x为1的时候就是前进1米 -1就是当前位置倒退1米),-1 为x后退)),y(左移，右移)\n,z(角度，弧度1.57为旋转90° \n 3.17为旋转180°),\n 发送按钮支持【持续点击、单击】");
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const SizedBox(
                                width: 70,
                                child: Text(
                                  '车辆状态:',
                                  textAlign: TextAlign.right,
                                )),
                            const SizedBox(width: 10),
                            Text(writeLog),
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
                      title: '基本控制',
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CustomButton(
                                text: '设置手动模式',
                                icon: Icons.waving_hand,
                                height: 50,
                                width: 200,
                                onPressed: () {
                                  SendAddressData data_0x3c = SendAddressData(
                                      address: 0x3c, length: 1, data: 1);
                                  List<SendAddressData> dataList = [];
                                  dataList.add(data_0x3c);

                                  SendData sendData = SendData(
                                      cRCHigh: null,
                                      cRCLow: null,
                                      cmd: 2,
                                      sn: 10,
                                      sendAddressData: dataList);

                                  sendData.buildBytesAddCrc();

                                  // sendData
                                  Uint8List sendAll = sendData.buildAllBytes();
                                  _sendUdpMessage(sendAll);

                                  _onErrorMessageReceived(0, "数据已发送。");
                                },
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CustomButton(
                                text: '关闭激光雷达',
                                icon: Icons.radar,
                                height: 50,
                                width: 200,
                                onPressed: () {
                                  SendAddressData data_0x162 = SendAddressData(
                                      address: 0x162, length: 1, data: 1);
                                  List<SendAddressData> dataList = [];
                                  dataList.add(data_0x162);

                                  SendData sendData = SendData(
                                      cRCHigh: null,
                                      cRCLow: null,
                                      cmd: 2,
                                      sn: 10,
                                      sendAddressData: dataList);

                                  sendData.buildBytesAddCrc();

                                  // sendData
                                  Uint8List sendAll = sendData.buildAllBytes();
                                  _sendUdpMessage(sendAll);

                                  _onErrorMessageReceived(0, "数据已发送。");
                                },
                              ),
                            ],
                          )
                        ],
                      ))
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomCard(
                    screenWidth: MediaQuery.of(context).size.width,
                    title: '支撑电机运动控制',
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Column(
                            children: [
                              // const SizedBox(height: 40), // 给标题留出空间
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CustomButton(
                                    text: '降',
                                    icon: Icons.download,
                                    height: 50,
                                    width: 200,
                                    onPressed: () {
                                      SendAddressData data_0x71 =
                                      SendAddressData(
                                          address: 0x71,
                                          length: 1,
                                          data: 1);

                                      SendAddressData data_0x73 =
                                      SendAddressData(
                                          address: 0x73,
                                          length: 1,
                                          data: 1);

                                      SendAddressData data_0x75 =
                                      SendAddressData(
                                          address: 0x75,
                                          length: 1,
                                          data: 1);

                                      SendAddressData data_0x77 =
                                      SendAddressData(
                                          address: 0x77,
                                          length: 1,
                                          data: 1);

                                      List<SendAddressData> dataList = [];
                                      dataList.add(data_0x71);
                                      dataList.add(data_0x73);
                                      // 控制4支撑电机
                                      dataList.add(data_0x75);
                                      dataList.add(data_0x77);

                                      SendData sendData = SendData(
                                          cRCHigh: null,
                                          cRCLow: null,
                                          cmd: 2,
                                          sn: 10,
                                          sendAddressData: dataList);

                                      sendData.buildBytesAddCrc();
                                      Uint8List sendAll =
                                      sendData.buildAllBytes();
                                      _sendUdpMessage(sendAll);

                                      _onErrorMessageReceived(0, "数据已发送。");
                                    },
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CustomButton(
                                    text: '升',
                                    icon: FontAwesomeIcons.upload,
                                    height: 50,
                                    width: 200,
                                    onPressed: () {
                                      SendAddressData data_0x70 =
                                      SendAddressData(
                                          address: 0x70,
                                          length: 1,
                                          data: 1);

                                      SendAddressData data_0x72 =
                                      SendAddressData(
                                          address: 0x72,
                                          length: 1,
                                          data: 1);

                                      SendAddressData data_0x74 =
                                      SendAddressData(
                                          address: 0x74,
                                          length: 1,
                                          data: 1);

                                      SendAddressData data_0x76 =
                                      SendAddressData(
                                          address: 0x76,
                                          length: 1,
                                          data: 1);

                                      List<SendAddressData> dataList = [];
                                      dataList.add(data_0x70);
                                      dataList.add(data_0x72);

                                      // 控制4支撑电机
                                      dataList.add(data_0x74);
                                      dataList.add(data_0x76);

                                      SendData sendData = SendData(
                                          cRCHigh: null,
                                          cRCLow: null,
                                          cmd: 2,
                                          sn: 10,
                                          sendAddressData: dataList);

                                      sendData.buildBytesAddCrc();
                                      Uint8List sendAll =
                                      sendData.buildAllBytes();
                                      _sendUdpMessage(sendAll);
                                      _onErrorMessageReceived(0, "数据已发送。");
                                    },
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Visibility(
                visible: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomCard(
                        screenWidth: MediaQuery.of(context).size.width,
                        title: '节点运行',
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                CounterWidget(
                                  height: 50,
                                  width: 120,
                                  title: '开始节点',
                                  initialValue: 0,
                                  step: 1,
                                  backgroundColor: Colors.grey[200],
                                  iconColor: Colors.black,
                                  textStyle: const TextStyle(
                                      fontSize: 25.0, color: Colors.black),
                                  // onChanged: _handleGoValueChanged,
                                  controller: _startController,
                                ),
                                const SizedBox(height: 10),
                                CounterWidget(
                                  height: 50,
                                  width: 120,
                                  title: '结束节点',
                                  initialValue: 0,
                                  step: 1,
                                  backgroundColor: Colors.grey[200],
                                  iconColor: Colors.black,
                                  textStyle: const TextStyle(
                                      fontSize: 25.0, color: Colors.black),
                                  // onChanged: _handleGoValueChanged,
                                  controller: _endController,
                                ),
                                CustomButton(
                                  text: '目的地',
                                  icon: Icons.location_on,
                                  height: 50,
                                  width: 120,
                                  onPressed: () {
                                    // CommonToast.showToast(_startController.text);
                                    SendAddressData data_0x3d0 = SendAddressData(
                                        address: 0x3d0,
                                        length: 4,
                                        data: int.parse(_startController.text));
                
                                    SendAddressData data_0x3d4 = SendAddressData(
                                        address: 0x3d4,
                                        length: 4,
                                        data: int.parse(_endController.text));
                
                                    SendAddressData data_0x250 = SendAddressData(
                                        address: 0x250, length: 1, data: 1);
                
                                    List<SendAddressData> dataList = [];
                                    dataList.add(data_0x3d0);
                                    dataList.add(data_0x3d4);
                                    dataList.add(data_0x250);
                
                                    SendData sendData = SendData(
                                        cRCHigh: null,
                                        cRCLow: null,
                                        cmd: 2,
                                        sn: 10,
                                        sendAddressData: dataList);
                
                                    sendData.buildBytesAddCrc();
                                    Uint8List sendAll = sendData.buildAllBytes();
                                    _sendUdpMessage(sendAll);
                                    _onErrorMessageReceived(0, "数据已发送。");
                                  },
                                ),
                              ],
                            ),
                            Container(
                              height: 200,
                              width: 1,
                              color: Colors.grey,
                            ),
                            Column(
                              children: [
                                CounterWidget(
                                  height: 50,
                                  width: 120,
                                  title: '开始节点',
                                  initialValue: 0,
                                  step: 1,
                                  backgroundColor: Colors.grey[200],
                                  iconColor: Colors.black,
                                  textStyle: const TextStyle(
                                      fontSize: 25.0, color: Colors.black),
                                  // onChanged: _handleGoValueChanged,
                                  controller: _backStartController,
                                ),
                                const SizedBox(height: 10),
                                CounterWidget(
                                  height: 50,
                                  width: 120,
                                  title: '结束节点',
                                  initialValue: 0,
                                  step: 1,
                                  backgroundColor: Colors.grey[200],
                                  iconColor: Colors.black,
                                  textStyle: const TextStyle(
                                      fontSize: 25.0, color: Colors.black),
                                  // onChanged: _handleGoValueChanged,
                                  controller: _backEndController,
                                ),
                                CustomButton(
                                  text: '回到原点',
                                  icon: Icons.location_on,
                                  height: 50,
                                  width: 120,
                                  onPressed: () {
                                    SendAddressData data_0x3d0 = SendAddressData(
                                        address: 0x3d0,
                                        length: 4,
                                        data:
                                        int.parse(_backStartController.text));
                
                                    SendAddressData data_0x3d4 = SendAddressData(
                                        address: 0x3d4,
                                        length: 4,
                                        data: int.parse(_backEndController.text));
                
                                    SendAddressData data_0x250 = SendAddressData(
                                        address: 0x250, length: 1, data: 1);
                
                                    List<SendAddressData> dataList = [];
                                    dataList.add(data_0x3d0);
                                    dataList.add(data_0x3d4);
                                    dataList.add(data_0x250);
                
                                    SendData sendData = SendData(
                                        cRCHigh: null,
                                        cRCLow: null,
                                        cmd: 2,
                                        sn: 10,
                                        sendAddressData: dataList);
                
                                    sendData.buildBytesAddCrc();
                                    Uint8List sendAll = sendData.buildAllBytes();
                                    _sendUdpMessage(sendAll);
                
                                    _onErrorMessageReceived(0,
                                        "数据已发送。  ${_backStartController.text}  ${_backEndController.text} ");
                                  },
                                ),
                              ],
                            ),
                          ],
                        ))
                  ],
                ),
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}
