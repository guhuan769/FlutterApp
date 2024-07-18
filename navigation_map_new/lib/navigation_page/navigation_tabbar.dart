import 'package:flutter/material.dart';
import 'navigation.dart';

class NavigationTabbar extends StatefulWidget {
  const NavigationTabbar({super.key});

  @override
  State<NavigationTabbar> createState() => _NavigationTabbarState();
}

class _NavigationTabbarState extends State<NavigationTabbar> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            // color: Colors.blue,
            child: const TabBar(
              tabs: [
                // Tab(icon: Icon(Icons.car_rental), text: '123'),
                Tab(
                  icon: Icon(Icons.car_rental),
                  text: '运动控制',
                ),
                Tab(icon: Icon(Icons.refresh), text: '最新消息'),
                // Tab(icon: Icon(Icons.directions_bike)),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                Center(child: Navigation()),
                Center(child: Text('待开发...')),
                // Center(child: Icon(Icons.directions_bike)),
              ],
            ),
          ),
        ],
      ),
    );
    //   DefaultTabController(
    //   length: 3,
    //   child: Scaffold(
    //     appBar: AppBar(
    //       title: Text('TabBar Example'),
    //       bottom: TabBar(
    //         tabs: [
    //           Tab(icon: Icon(Icons.home), text: "Home"),
    //           Tab(icon: Icon(Icons.search), text: "Search"),
    //           Tab(icon: Icon(Icons.person), text: "Profile"),
    //         ],
    //       ),
    //     ),
    //     body: TabBarView(
    //       children: [
    //         Center(child: Text('Home Content')),
    //         Center(child: Text('Search Content')),
    //         Center(child: Text('Profile Content')),
    //       ],
    //     ),
    //   ),
    // );
  }
}
