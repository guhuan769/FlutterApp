import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crclib/catalog.dart';
import 'package:flutter/material.dart';
import 'package:navigation_map/Utils/common_toast.dart';
import 'package:navigation_map/utils/UdpHelper.dart';
import 'model/send_data.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {

  late UdpHelper _udpHelper;

  // 创建一个 TextEditingController 并设置默认值 relativeOperation
  final TextEditingController _relativeOperation =
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

    _udpHelper = UdpHelper(_onUdpDataReceived);
    _udpHelper.startListening();
  }

  void _onUdpDataReceived(String data) {
    setState(() {
      // 处理接收到的数据
      print('Received: $data');
    });
  }

  void _sendUdpMessage(Uint8List data) {
    //TODO: 该处IP 应该从本地数据库取
    var destinationAddress = InternetAddress("172.31.90.200"); // 替换为您的广播地址
    _udpHelper.sendMsgDataFrame(data, destinationAddress, 9331);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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

                  Datas data_0x5e0 = Datas(
                      address: 0x5e0, length: 12, datas: relativeOperationList);
                  Datas data_0x5f1 = Datas(address: 0x5f1, length: 1, data: 1);
                  List<Datas> dataList = [];
                  dataList.add(data_0x5e0);
                  dataList.add(data_0x5f1);

                  SendData sendData = SendData(
                      cRCHigh: null,
                      cRCLow: null,
                      cmd: 2,
                      sn: 10,
                      datas: dataList);

                  sendData.buildBytesAddCrc();

                  // sendData
                  Uint8List sendAll = sendData.buildAllBytes();
                  _sendUdpMessage(sendAll);

                  // 当前UI 方法封装
                  // _startUdpListener(sendAll);

                  // 工具类的监听数据
                  // udpUtil.startListening('127.0.0.1', 8080);


                  // Uint8List result = await CommonToast.udpSend(sendAll);
                  // Uint8List aa = await CommonToast.udpSend(sendAll);
                  // print("gh 接收到数据：${utf8.decode(aa2)}");

                },
                icon: const Icon(Icons.send)),
            // ElevatedButton(onPressed: (){}, child: Text('data'))
          ],
        ),
        Row(
          children: [
            const Expanded(
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "绝对运行",
                  hintText: "请输入坐标",
                  prefixIcon: Icon(Icons.table_view),
                ),
              ),
            ),
            IconButton(
                onPressed: () {
                  CommonToast.showToast('绝对运行');
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
