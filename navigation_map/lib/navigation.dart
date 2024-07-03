import 'dart:typed_data';

import 'package:crclib/catalog.dart';
import 'package:flutter/material.dart';
import 'package:navigation_map/Utils/common_toast.dart';

import 'model/send_data.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  // 创建一个 TextEditingController 并设置默认值 relativeOperation
  final TextEditingController _relativeOperation =
      TextEditingController(text: "0,0,0");

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
                onPressed: () {
                  // 获取value
                  var relativeOperation = _relativeOperation.text;
                  if (!relativeOperation.isNotEmpty) {
                    CommonToast.showToast('位置信息不能为空');
                    return;
                  }
                  //临时测试
                  List<dynamic> relativeOperationList =
                      relativeOperation.split(','); // 使用短横线和竖线作为分隔符

                  // int length = parts.length;
                  // var length1 = int.parse(parts[0]);
                  // CommonToast.showToast('相对运行 $length1');

                  //获取坐标
                  // List<dynamic> dataDynamic = [];
                  // dataDynamic = relativeOperationList;

                  Datas data_0x5e0 =
                      Datas(address: 0x5e0, length: 12, datas: relativeOperationList);
                  Datas data_0x5f1 =
                  Datas(address: 0x5f1, length: 1, data: 1);
                  List<Datas> dataList = [];
                  dataList.add(data_0x5e0);
                  dataList.add(data_0x5f1);


                  SendData sendData = SendData(
                      cRCHigh: null,
                      cRCLow: null,
                      cmd: 2,
                      sn: 3,
                      datas: dataList);

                  Uint8List buildData = sendData.buildBytes();
                  final crcValue = Crc16X25().convert(buildData);
                  // Crc16X25().
                  //String hexString = buildData.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
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
