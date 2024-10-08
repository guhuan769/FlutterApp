import 'package:flutter/material.dart';
import 'package:navigation_map/navigation_page/TestJoystick.dart';
import 'package:navigation_map/navigation_page/wind_walker_lift_model.dart';
import 'package:navigation_map/navigation_page/wind_walker_standard.dart';
import 'executor_standard_library.dart';
import 'freelander_standard_model.dart';
import 'navigation.dart';
import 'navigation_new.dart';

class NavigationTabbar extends StatefulWidget {
  const NavigationTabbar({super.key});

  @override
  State<NavigationTabbar> createState() => _NavigationTabbarState();
}

class _NavigationTabbarState extends State<NavigationTabbar> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Column(
        children: [
          Container(
            // color: Colors.blue,
            child: const TabBar(
              isScrollable: true,

              tabs: [
                // Tab(icon: Icon(Icons.car_rental), text: '123'),
                Tab(
                  icon: Icon(Icons.speaker),
                  text: '智行者标准款',
                ),
                Tab(icon: Icon(Icons.message), text: '领航者标准款'),
                Tab(icon: Icon(Icons.message), text: '风行者升降款'),
                Tab(icon: Icon(Icons.message), text: '风行者标准款'),
                Tab(icon: Icon(Icons.message), text: '神行者标准款'),
                Tab(icon: Icon(Icons.message), text: '履行者标准库'),
                Tab(icon: Icon(Icons.message), text: 'TestJoystick'),
                // Tab(icon: Icon(Icons.directions_bike)),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              physics: NeverScrollableScrollPhysics(),//禁止滑动
              children: [
                Center(child: NavigationNew()),
                Center(child: NavigationNew()),
                Center(child: WindWalkerLiftModel()),
                Center(child: WindWalkerStandard()),
                Center(child: FreelanderStandardModel()),
                Center(child: ExecutorStandardLibrary()),
                Center(child: Testjoystick()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
