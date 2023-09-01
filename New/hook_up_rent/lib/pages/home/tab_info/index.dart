/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-19 10:45:29
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-21 14:54:06
 * @FilePath: \hook_up_rent\lib\pages\home\tab_info\index.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:flutter/material.dart';
import 'package:hook_up_rent/pages/home/info/index.dart';
import 'package:hook_up_rent/widgets/search_bar/index.dart';

class TabInfo extends StatefulWidget {
  const TabInfo({super.key});

  @override
  State<TabInfo> createState() => _TabInfoState();
}

class _TabInfoState extends State<TabInfo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:  SearchBarCustom(
          onSearch: () {
            Navigator.of(context).pushNamed('search');
          },
        ),),
      body: ListView(children: [
        Info()
      ],),
      );
  }
}