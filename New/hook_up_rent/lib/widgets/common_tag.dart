/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-20 15:28:04
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-20 15:55:27
 * @FilePath: \hook_up_rent\lib\widgets\common_tag.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:flutter/material.dart';

class CommonTag extends StatelessWidget {
  final String title;
  final Color color;
  final Color backgroundColor;

  //自定义颜色机制
  const CommonTag.origin(
      {super.key,
      required this.title,
      this.color = Colors.black,
      this.backgroundColor = Colors.grey});

  ///封装固定标签固定颜色
  factory CommonTag(String title) {
    switch (title) {
      //标签名称
      case '1':
        return CommonTag.origin(
            title: title,
            color: Colors.red,
            backgroundColor: Colors.red.shade50);
      default:
        return CommonTag.origin(
            title: title, color: Colors.black, backgroundColor: Colors.black);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 4.0),
      padding: EdgeInsets.only(left: 4.0, right: 4.0, top: 2.0, bottom: 2.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        title,
        style: TextStyle(fontSize: 10.0, color: color),
      ),
    );
  }
}
