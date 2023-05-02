/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-19 10:53:52
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-23 17:05:43
 * @FilePath: \hook_up_rent\lib\pages\home\tab_profile\index.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */

// import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:hook_up_rent/pages/home/tab_profile/function_button.dart';
import 'package:hook_up_rent/pages/home/tab_profile/header.dart';

class TabProfile extends StatelessWidget {
  const TabProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0, //边线
        title: Text('我的'),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed('setting');
              },
              icon: Icon(Icons.settings)),
        ],
      ),
      body: ListView(
        children: [
          Header(),
          Text('待开发'),
          // FunctionButton(),
        ],
      ),
    );
  }
}
