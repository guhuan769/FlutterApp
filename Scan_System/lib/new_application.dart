import 'package:flutter/material.dart';
import 'package:scan_system/home_page.dart';
import 'package:scan_system/scan_page.dart';

class NewApplication extends StatefulWidget {
  const NewApplication({super.key});

  @override
  State<NewApplication> createState() => _NewApplicationState();
}

class _NewApplicationState extends State<NewApplication> {
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
    const HomePage(),
  ];

  int _selectIndex = 0;

  Widget _buildPage(int index) {
    return _pages[index];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '扫描系统',
      theme: ThemeData(
        primaryColor: Colors.orangeAccent, // 设置按钮背景颜色
        // primarySwatch: Colors.red, // 设置主色，影响按钮等部件的颜色
        // accentColor: Colors.green, // 设置强调色，通常用于按钮和其他交互元素
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.pink,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
            )),
      ),
      home: Scaffold(
        // backgroundColor: Colors.red,
        appBar: AppBar(
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
      ),
    );
  }
}
