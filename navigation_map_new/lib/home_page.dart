import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:navigation_map/my_page/settting_page/setting_page.dart';
import 'Utils/common_toast.dart';
import 'company/CompanyProfile.dart';
import 'my_page/my_page.dart';
import 'navigation_page/navigation_tabbar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<BottomNavigationBarItem> _items = <BottomNavigationBarItem>[
    const BottomNavigationBarItem(
      label: '导航',
      icon: Icon(Icons.map),
    ),
    const BottomNavigationBarItem(
      label: '我的',
      icon: Icon(Icons.person),
    ),
  ];

  final List<Widget> _pages = [
    const NavigationTabbar(),
    // const Navigation(),
    const MyPage(),
  ];

  int _selectIndex = 0;

  Widget _buildPage(int index) {
    return _pages[index];
  }

  void msgShow(String msg) {
    CommonToast.showToastNew(
      context,
      "提示",
      msg,
      [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // 关闭对话框
          },
          child: Text(
            "关闭",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.transparent, // 使 Scaffold 背景透明
      drawer: Drawer(
        child: ListView(
          // padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              padding: EdgeInsets.zero, // 移除内边距
              decoration: BoxDecoration(
                color: Theme.of(context).drawerTheme.backgroundColor,
                image: DecorationImage(
                  image: AssetImage('assets/images/car_logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(), // 保持空容器
            ),

            ListTile(
              leading: FaIcon(
                FontAwesomeIcons.building,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                size: 40,
              ),
              // Icon(Icons.settings,
              //     color: Theme.of(context).textTheme.bodyLarge?.color),
              title: Text(
                '公司介绍',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                ),
              ),
              onTap: () {
                // 处理点击事件
                // Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                        settings: const RouteSettings(
                            arguments: {"id": 10, "name": "_我爱你"}),
                        builder: (context) =>
                            const Companyprofile()) //const PhotoPage()
                    );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings,
                  color: Theme.of(context).textTheme.bodyLarge?.color),
              title: Text(
                '设置',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                ),
              ),
              onTap: () {
                // 处理点击事件
                // Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                        settings: const RouteSettings(
                            arguments: {"id": 10, "name": "_我爱你"}),
                        builder: (context) =>
                            const SettingPage()) //const PhotoPage()
                    );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        // 使 AppBar 背景透明        // leading:const Icon(Icons.menu) ,
        elevation: 0,
        //边线
        toolbarHeight: 40,
        // 设置 AppBar 的高度
        flexibleSpace: const SafeArea(
          child: Stack(
            children: <Widget>[
              Align(
                alignment: Alignment.center,
                child: Image(
                  height: 20,
                  image: AssetImage('assets/images/logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        // 确保标题在中心
        actions: [
          if (_items[_selectIndex].label == "我的")
            IconButton(
                onPressed: () {
                  msgShow('换肤功能暂未开发');
                },
                icon: const FaIcon(
                  FontAwesomeIcons.shirt,
                  // color: Theme,
                  size: 25,
                )),
          if (_items[_selectIndex].label == "我的")
            IconButton(
                onPressed: () {
                  msgShow('该功能迁移到侧边栏“设置”');
                  // Navigator.of(context).push(MaterialPageRoute(
                  //         settings: const RouteSettings(
                  //             arguments: {"id": 10, "name": "_我爱你"}),
                  //         builder: (context) =>
                  //             const SettingPage()) //const PhotoPage()
                  //     );
                },
                // color: Colors.white,
                icon: const FaIcon(
                  FontAwesomeIcons.gear,
                  // color: Theme,
                  size: 25,
                )),
        ],
        //背景图

        // title: Text('${_items[_selectIndex].label}'),
      ),
      body: _buildPage(_selectIndex),
      bottomNavigationBar: BottomNavigationBar(
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
