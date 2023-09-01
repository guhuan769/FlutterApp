/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-18 13:47:59
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-21 11:59:29
 * @FilePath: \hook_up_rent\lib\pages\home\tab_index\index_navigator.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:hook_up_rent/widgets/common_image.dart';
import './index_navigator_item.dart';

class IndexNavigator extends StatelessWidget {
  const IndexNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 6.0, bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: navigatorItemList
            .map((item) => InkWell(
                  onTap: () {
                    item.onTap(context);
                  },
                  child: Column(
                    children: <Widget>[
                      // Image.asset(
                      //   item.imageUri,
                      // )
                      CommonImage(item.imageUri, width: 47.5,),
                      Text(
                        item.title,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
