/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-16 14:50:34
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-23 11:07:02
 * @FilePath: \hook_up_rent\lib\pages\home\index.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:flutter/material.dart';
import 'package:hook_up_rent/pages/home/tab_Search/index.dart';
import 'package:hook_up_rent/pages/home/tab_index/index.dart';
import 'package:hook_up_rent/pages/home/tab_info/index.dart';
import 'package:hook_up_rent/pages/home/tab_profile/index.dart';
import 'package:hook_up_rent/widgets/common_image.dart';
import 'package:hook_up_rent/widgets/page_content.dart';

//需要准备 4个内容块  shared_preferences
List<Widget> tabViewList = [
  TabIndex(),
  // TabSearch(),
  // TabInfo(),
  TabProfile(),
];
//
List<BottomNavigationBarItem> barItemList = [
  // BottomNavigationBarItem(
  //     icon: CommonImage(
  //       'static/images/database.png',
  //       width: 16,
  //       height: 16,
  //     ),
  //     label: '产量'),
  BottomNavigationBarItem(icon: Icon(Icons.data_array_sharp), label: '产量'),
  // BottomNavigationBarItem(icon: Icon(Icons.search), label: '搜索'),
  // BottomNavigationBarItem(icon: Icon(Icons.info), label: '资讯'),
  BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: '我的'),
];

//有状态组件
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: tabViewList[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: barItemList,
        currentIndex: _selectedIndex,
        // selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
