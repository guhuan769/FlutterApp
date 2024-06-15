import 'package:flutter/material.dart';
import 'package:scan_system/scan_page.dart';
import 'package:scan_system/setting_page.dart';

import 'Utils/common_toast.dart';
import 'my_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<BottomNavigationBarItem> _items = <BottomNavigationBarItem>[
    const BottomNavigationBarItem(
      label: '扫描',
      icon: Icon(Icons.scanner),
    ),
    const BottomNavigationBarItem(
      label: '我的',
      icon: Icon(Icons.person),
    ),
  ];


  final List<Widget> _pages = [
    const ScanPage(),
    const MyPage(),
  ];

  int _selectIndex = 0;

  Widget _buildPage(int index) {
    return _pages[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.red,
      appBar: AppBar(
        elevation: 0,//边线
        actions: [
          if (_items[_selectIndex].label == "我的")
            IconButton(
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(
                      settings: const RouteSettings(
                          arguments: {"id": 10, "name": "_我爱你"}),
                      builder: (context) =>
                      const SettingPage()) //const PhotoPage()
                  );
                },
                color: Colors.white,
                icon: const Icon(Icons.settings)),
        ],
        title: Text('${_items[_selectIndex].label}'),
      ),
      body: _buildPage(_selectIndex),

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey[800],
        type: BottomNavigationBarType.fixed,
        items: _items,
        currentIndex: _selectIndex,
        onTap: (index) {
          setState(() {
            _selectIndex = index;
          });
        },
      ),
    );
  }
}
