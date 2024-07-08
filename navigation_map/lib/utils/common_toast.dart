import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_ping/dart_ping.dart';

Color? bgColor = Colors.pink;
var textStyle = const TextStyle(
  color: Colors.white,
);

class CommonToast {
  /// 提示框
  static showToast(String msg) {
    Fluttertoast.showToast(
        msg: msg, gravity: ToastGravity.CENTER, backgroundColor: bgColor);
  }

  ///
  ///
  ///
  /// 前端使用
  ///CustomDialog.show(
  //   context: context,
  //   title: "自定义对话框",
  //   content: "这是一个自定义对话框示例。",
  //   actions: [
  //     TextButton(
  //       onPressed: () {
  //         Navigator.of(context).pop(); // 关闭对话框
  //       },
  //       child: Text("关闭"),
  //     ),
  //   ],
  // );
  ///
  ///
  static Future<void> showToastNew(BuildContext context, String title,
      String content, List<Widget>? actions) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: bgColor,
          title: Text(title, style: textStyle),
          content: Text(content, style: textStyle),
          actions: actions ?? [],
        );
      },
    );
  }

  /// 阻止弹窗
  static Future<bool?> showHint(BuildContext context) {
    return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: bgColor,
            title: Text('提示', style: textStyle),
            content: Text('您确定要退出当前页面吗?', style: textStyle),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  // Navigator.of(context).pop(true);
                  exit(0);
                },
                child: const Text('确定'),
              ),
              ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('取消'))
            ],
          );
        });
  }

  static Future<bool?> deleteImgMsg(BuildContext context) {
    return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: bgColor,
            title: Text('提示', style: textStyle),
            content: Text('您确认删除吗?', style: textStyle),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop(true);
                },
                child: const Text('确定'),
              ),
              ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('取消'))
            ],
          );
        });
  }

  static Future<bool?> deleteImgMsgAll(BuildContext context) {
    return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: bgColor,
            title: Text('提示', style: textStyle),
            content: Text('您确认删除所有图片吗?', style: textStyle),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop(true);
                },
                child: const Text('确定'),
              ),
              ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('取消'))
            ],
          );
        });
  }

  // 将bool?转换为int
  // int boolToInt(bool? value) {
  //   return value ?? 0; // 如果value是null，则返回0
  // }

// 将int转换回bool?
  static bool? intToBool(int value) {
    return value == 1
        ? true
        : value == 0
            ? false
            : null;
  }

  static Future<bool> deleteFile(String filePath) async {
    File file = File(filePath);
    if (await file.exists()) {
      await file.delete();
      return true;
    } else {
      print('文件不存在：$filePath');
      return false;
    }
  }

  static void deleteFolder(path) async {
    final dir = Directory(path);
    dir.deleteSync(recursive: true);
  }

  ///
  /// ping IP 需要使用回调
  ///

  static Future<bool> pingIP(String ipAddress) async {
    final ping = Ping(ipAddress, count: 5);
    bool state = false;
    ping.stream.listen((event) {
      if (event.response != null) {
        print('Ping response time: ${event.response!.time!.inMilliseconds} ms');
        state = true;
      }
      // else {
      //   print('Ping failed: ${event.error}');
      //   state = false;
      // }
    });
    return state;
  }

// static Future<Uint8List> udpSend(Uint8List data) async {
//   // var destinationAddress = InternetAddress("192.168.31.7"); // 替换为您的广播地址
//   var destinationAddress = InternetAddress("172.31.90.200"); // 替换为您的广播地址
//   Uint8List returnData = Uint8List(0);
//   await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8456)
//       .then((RawDatagramSocket udpSocket) {
//     udpSocket.broadcastEnabled = true;
//     udpSocket.listen((e) {
//       Datagram? dg = udpSocket.receive();
//       if (dg != null) {
//         returnData = Uint8List(dg.data.length);
//         returnData = dg.data;
//         print("接收到数据：${utf8.decode(dg.data)}");
//         // showToast("接收到数据：${utf8.decode(dg.data)}");
//       }
//     });
//
//     // List<int> data = utf8.encode('TEST');
//     udpSocket.send(data, destinationAddress, 9331);
//   });
//   return returnData;
// }
}
