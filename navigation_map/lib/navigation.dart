import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crclib/catalog.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/material.dart';
import 'package:navigation_map/Utils/common_toast.dart';
import 'package:navigation_map/utils/UdpHelper.dart';
import 'CustomUserControls/CustomCircle.dart';
import 'model/send_data.dart';

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
      TextEditingController(text: "0,0,0");

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
          child: const Text("关闭"),
        ),
      ],
    );
  }

  void _sendUdpMessage(Uint8List data) {
    //TODO: 该处IP 应该从本地数据库取
    var destinationAddress = InternetAddress("192.168.31.7"); // 替换为您的广播地址
    _udpHelper.sendMsgDataFrame(data, destinationAddress, 9331);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomCircle(
                diameter: 20.0,
                color: isActive ? Colors.green : Colors.red,
              ),
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
                    if (entity.ip  != null ){
                      print(
                          'Ping response time: ${event.response!.time!.inMilliseconds} ms');
                      setState(() {
                        isActive = true;
                      });
                      CommonToast.showToastNew(
                        context,
                        "提示",
                        '已连接',
                        [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // 关闭对话框
                            },
                            child: const Text("关闭"),
                          ),
                        ],
                      );
                    } else if (entity.ip == null) {
                      setState(() {
                        isActive = false;
                      });

                      CommonToast.showToastNew(
                        context,
                        "提示",
                        '未连接',
                        [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // 关闭对话框
                            },
                            child: const Text("关闭"),
                          ),
                        ],
                      );

                    }
                  });
                },
                icon: const Icon(Icons.network_wifi)),
            // ElevatedButton(onPressed: (){}, child: Text('data'))
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _relativeOperation,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "相对运行",
                  hintText: "请输入坐标",
                  prefixIcon: Icon(Icons.table_view),
                ),
              ),
            ),
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
                      address: 0x5e0, length: 12, datas: relativeOperationList);
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

                  CommonToast.showToastNew(
                    context,
                    "提示",
                    '数据已发送',
                    [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // 关闭对话框
                        },
                        child: const Text("关闭"),
                      ),
                    ],
                  );
                },
                icon: const Icon(Icons.send)),
          ],
        ),
        Row(
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
                        child: const Text("关闭"),
                      ),
                    ],
                  );
                },
                icon: const Icon(Icons.send)),
            // ElevatedButton(onPressed: (){}, child: Text('data'))
          ],
        ),
        // Row(
        //   children: [
        //
        //   ],
        // ),
      ],
    );
  }
}
