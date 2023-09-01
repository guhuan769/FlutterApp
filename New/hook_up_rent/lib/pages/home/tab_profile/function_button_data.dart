/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-19 14:11:27
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-21 15:42:47
 * @FilePath: \hook_up_rent\lib\pages\home\tab_profile\function_button_data.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:flutter/material.dart';

class FunctionButtonnItem {
  final String imageUri;
  final String title;
  final Function? onTapHandle;

  FunctionButtonnItem(
      {required this.imageUri, required this.title, this.onTapHandle});
}

final List<FunctionButtonnItem> list = [
  FunctionButtonnItem(
      imageUri: 'static/images/database.png',
      title: '生产管理子系统',
      onTapHandle: (context) {
        bool isLogin = true; //假设先设置未登录
        if (isLogin) {
          Navigator.pushNamed(context, 'productionmanager');
        }
      }),
  // FunctionButtonnItem(
  //     imageUri: 'static/images/device.png',
  //     title: '设备统计列表',
  //     onPanhandler: null),
];
