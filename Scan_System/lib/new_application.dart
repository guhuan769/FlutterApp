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
      label:'扫描',
      icon: Icon(Icons.scanner),
    ),
    const BottomNavigationBarItem(
      label:'我的',
      icon: Icon(Icons.person),
    ),
  ];

  final List<Widget> _pages = [
    const ScanPage(),
    const HomePage(),
  ];

  int _selectIndex = 0;

  Widget _buildPage(int index){
    return _pages[index];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: '扫描系统',
        theme: ThemeData(
            // primarySwatch: Colors.orange,
            appBarTheme: const AppBarTheme(
            backgroundColor: Colors.pink,
            titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
              )
            )
        ),
        home:Scaffold(
          appBar: AppBar(
          title: const Text("扫描"),
        ),

        body:  _buildPage(_selectIndex),

        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: Colors.pink,
          unselectedItemColor:Colors.grey[800],
          type: BottomNavigationBarType.fixed,
          items:_items,
          currentIndex: _selectIndex,
          onTap: (index){
            setState(() {
              _selectIndex = index;
            });
          },
      ),
    ),
    );
  }
}
