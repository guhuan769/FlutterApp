import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crclib/catalog.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/material.dart';
import 'package:navigation_map/Utils/common_toast.dart';
import 'package:navigation_map/utils/UdpHelper.dart';
import '../CustomUserControls/CustomCircle.dart';
import '../model/send_data.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  late UdpHelper _udpHelper;
  bool isActive = false;

  // 创建一个 TextEditingController 并设置默认值 relativeOperation
  // 相对运行
  final TextEditingController _relativeOperation =
      TextEditingController(text: "0.1,0,0");

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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _udpHelper = UdpHelper(_onUdpDataReceived, _onErrorMessageReceived);
    _udpHelper.startListening();
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
            style: Theme.of(context).textTheme.bodyLarge,
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

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 10),

          Row(children: [
            Expanded(
              child: Row(children: [
                const SizedBox(width: 10),
                const Text('状态: '),
                const SizedBox(width: 10),
                CustomCircle(
                  diameter: 15.0,
                  color: isActive ? Colors.green : _indicatorColor,
                ),
              ]),
            ),
            IconButton(
                onPressed: () {
                  // pingIP('8.8.8.8'); // 替换为你想要 ping 的 IP 地址

                  // CommonToast.pingIP('192.168.31.7').then((status) {
                  // });
                  final ping = Ping('192.168.31.7', count: 1);
                  ping.stream.listen((event) {
                    PingResponse entity = event.response as PingResponse;
                    // if (event.response != null) {
                    if (entity.ip != null) {
                      print(
                          'Ping response time: ${event.response!.time!.inMilliseconds} ms');
                      setState(() {
                        isActive = true;
                      });

                      _onErrorMessageReceived(0, "已连接");
                    } else if (entity.ip == null) {
                      setState(() {
                        isActive = false;
                      });

                      _onErrorMessageReceived(0, "未连接");
                    }
                  });
                },
                icon: const Icon(Icons.network_wifi)),
          ]),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _relativeOperation,
                  autofocus: true,

                  // 带下线的
                  // decoration: const InputDecoration(
                  //   labelText: "相对运行",
                  //   hintText: "请输入坐标",
                  //   prefixIcon: Icon(Icons.table_view),
                  // ),

                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.blueAccent.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide.none,
                    ),
                    hintText: '请输入坐标',
                    hintStyle: Theme.of(context).textTheme.bodyMedium,
                    labelText: '相对运行',
                    // labelStyle: const TextStyle(color: Colors.blue),
                    labelStyle: Theme.of(context).textTheme.bodyMedium,
                    prefixIcon: Icon(Icons.table_view,
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                  style: const TextStyle(color: Colors.black),
                  cursorColor: Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                  onPressed: () {
                    _onErrorMessageReceived(0,
                        "注意\n相对运行(x(前进 (x为1的时候就是前进1米 -1就是当前位置倒退1米),-1 为x后退)),y(左移，右移)\n,z(角度，弧度1.57为旋转90° \n 3.17为旋转180°),");
                  },
                  child: Text('说明书',
                      style: Theme.of(context).textTheme.bodyMedium)),
              const SizedBox(width: 10),
              IconButton(
                  onPressed: () async {
                    // 获取value
                    var relativeOperation = _relativeOperation.text;
                    if (!relativeOperation.isNotEmpty) {
                      CommonToast.showToast('位置信息不能为空');
                      return;
                    }
                    //临时测试
                    List<dynamic> relativeOperationList =
                        relativeOperation.split(','); // 使用短横线和竖线作为分隔符

                    SendAddressData data_0x5e0 = SendAddressData(
                        address: 0x5e0,
                        length: 12,
                        datas: relativeOperationList);
                    SendAddressData data_0x5f1 =
                        SendAddressData(address: 0x5f1, length: 1, data: 1);
                    List<SendAddressData> dataList = [];
                    dataList.add(data_0x5e0);
                    dataList.add(data_0x5f1);

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

                    SendData sendParseData = SendData(
                        cRCHigh: null,
                        cRCLow: null,
                        cmd: 0,
                        sn: 0,
                        sendAddressData: null);
                    sendParseData.Parse(sendAll);
                    // sendParseData.Parse(sendAll);

                    _onErrorMessageReceived(0, "数据已发送。");
                  },
                  icon: const Icon(Icons.send)),
            ],
          ),
          Visibility(
            visible: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _absolutelyRunning,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: "绝对运行",
                      hintText: "请输入坐标",
                      prefixIcon: Icon(Icons.table_view),
                    ),
                  ),
                ),
                IconButton(
                    onPressed: () {
                      CommonToast.showToastNew(
                        context,
                        "提示",
                        '绝对坐标',
                        [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // 关闭对话框
                            },
                            child: Text(
                              "关闭",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      );
                    },
                    icon: const Icon(Icons.send)),
                // ElevatedButton(onPressed: (){}, child: Text('data'))
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: screenWidth * 0.97, // 设置宽度为屏幕宽度的80%
                child: Card(
                  color: Colors.grey[100],
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 40), // 给标题留出空间
                            Row(
                              children: [
                                const SizedBox(width: 10),
                                ElevatedButton(
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

                                      // SendData sendParseData = SendData(
                                      //     cRCHigh: null,
                                      //     cRCLow: null,
                                      //     cmd: 0,
                                      //     sn: 0,
                                      //     sendAddressData: null);
                                      // sendParseData.Parse(sendAll);
                                      // sendParseData.Parse(sendAll);

                                      _onErrorMessageReceived(0, "数据已发送。");
                                    },
                                    child: Text('降',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium)),
                                const SizedBox(width: 10),
                                ElevatedButton(
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
                                    child: Text('升',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium)),
                              ],
                            )
                          ],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10.0), // 设置圆角半径
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '支撑电击运动控制',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
          // Row(
          //   children: [
          //
          //   ],
          // ),
        ],
      ),
    );
  }
}
