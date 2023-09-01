/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-19 16:35:56
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-19 17:03:31
 * @FilePath: \hook_up_rent\lib\pages\utils\common_toast.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CommonToast {
  static showToast(String msg) {
    Fluttertoast.showToast(
        msg: msg, gravity: ToastGravity.CENTER, backgroundColor: Colors.green);
  }
}
