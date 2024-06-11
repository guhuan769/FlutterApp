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
}
