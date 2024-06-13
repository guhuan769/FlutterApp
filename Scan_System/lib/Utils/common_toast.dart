import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
    return value == 1 ? true : value == 0 ? false : null;
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
  static void deleteFolder(String path) async {
    final dir = Directory(path);
    dir.deleteSync(recursive: true);
  }


}
