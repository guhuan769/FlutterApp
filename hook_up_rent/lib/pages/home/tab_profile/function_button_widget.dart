/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-19 15:10:26
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-20 09:38:15
 * @FilePath: \hook_up_rent\lib\pages\home\tab_profile\function_button_widget.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hook_up_rent/pages/home/tab_profile/function_button_data.dart';
import 'package:hook_up_rent/pages/utils/common_toast.dart';
import 'package:hook_up_rent/widgets/common_image.dart';

class FuntionButtonWidget extends StatelessWidget {
  final FunctionButtonnItem data;
  const FuntionButtonWidget({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    // /GestureDetector 该组件可以加点击事件
    return GestureDetector(
      onTap: () {
        if (null != data.onTapHandle) {
          data.onTapHandle!(context);
        }
      },
      child: Container(
        margin: EdgeInsets.only(top: 30.0),
        width: MediaQuery.of(context).size.width * 0.33,
        child: Column(
          children: <Widget>[CommonImage(data.imageUri), Text(data.title)],
        ),
      ),
    );
  }
}
