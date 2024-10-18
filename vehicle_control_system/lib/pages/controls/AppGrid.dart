import 'package:flutter/material.dart';
import 'package:navigation_map/models/AppItem.dart';
import 'package:navigation_map/pages/controls/AppGridItem.dart';
import 'package:get/get.dart';

class AppGrid extends StatefulWidget {
  final ScrollController scrollController;

  AppGrid({required this.scrollController});

  @override
  _AppGridState createState() => _AppGridState();
}

class _AppGridState extends State<AppGrid> {
  int _selectedIndex = -1;

  final List<AppItem> items = [
    AppItem(icon: Icons.gamepad, label: '遥控器'),
    // AppItem(icon: Icons.message, label: '社交通讯'),
    // AppItem(icon: Icons.school, label: '教育'),
    // AppItem(icon: Icons.newspaper, label: '新闻阅读'),
    // AppItem(icon: Icons.food_bank, label: '美食'),
    // AppItem(icon: Icons.travel_explore, label: '出行导航'),
    // AppItem(icon: Icons.shopping_cart, label: '购物比价'),
    // AppItem(icon: Icons.business, label: '商务'),
    // AppItem(icon: Icons.child_care, label: '儿童'),
    // AppItem(icon: Icons.money, label: '金融理财'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch(index){
      case 0:
          Get.toNamed('/setting');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度
    double screenWidth = MediaQuery.of(context).size.width;
    // 根据屏幕宽度计算列数
    int crossAxisCount = (screenWidth / 130).floor();

    return GridView.builder(
      controller: widget.scrollController,
      padding: EdgeInsets.all(10.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return AppGridItem(
          item: items[index],
          isSelected: _selectedIndex == index,
          onTap: () => _onItemTapped(index),
        );
      },
    );
  }
}


