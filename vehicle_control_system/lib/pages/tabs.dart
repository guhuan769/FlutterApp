import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vehicle_control_system/pages/feedback/feedback_page.dart';
import 'package:vehicle_control_system/pages/tabs/focus_on.dart';
import './tabs/home.dart';
import './tabs/category.dart';
import './tabs/message.dart';
import './tabs/setting.dart';
import './tabs/user.dart';
//import 'package:vehicle_control_system/pages/Utilities/language.dart';



class Tabs extends StatefulWidget {
  final int index;

  const Tabs({super.key, this.index = 0});

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  late int _currentIndex;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _currentIndex = widget.index;
  }

  final List<Widget> _pages =  [
    // HomePage(),
    CategoryPage(),
    FeedbackPage(),
    FocusOn(),
    // SettingPage(),
    // UserPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("")),//const Text("Flutter App")
      drawer: Drawer(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    flex: 1,
                    child: UserAccountsDrawerHeader(
                      accountName: const Text("Elon"),
                      accountEmail: const Text("ElonAlexander@qq.com"),
                      otherAccountsPictures: [
                        Image.network(
                            "https://www.itying.com/images/flutter/1.png"),
                        Image.network(
                            "https://www.itying.com/images/flutter/2.png"),
                        Image.network(
                            "https://www.itying.com/images/flutter/3.png"),
                      ],
                      currentAccountPicture: const CircleAvatar(
                          backgroundImage: NetworkImage(
                              "https://www.itying.com/images/flutter/3.png")),
                      decoration: const BoxDecoration(
                          image: DecorationImage(
                              fit: BoxFit.cover,
                              image: NetworkImage(
                                  "https://www.itying.com/images/flutter/2.png"))),
                    ))
              ],
            ),
             ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.people),
              ),
              title: Text("PersonalCenter".tr),
            ),
            const Divider(),
            ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.settings),
              ),
              title: Text("SystemSettings".tr),
              onTap: () {
                // 处理点击事件
                print('Phone 被点击');
                Get.toNamed('/setting');
              },
            ),
            const Divider(),
          ],
        ),
      ),

      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
          fixedColor: Colors.red,
          //选中的颜色
          // iconSize:35,           //底部菜单大小
          currentIndex: _currentIndex,
          //第几个菜单选中
          type: BottomNavigationBarType.fixed,
          //如果底部有4个或者4个以上的菜单的时候就需要配置这个参数
          onTap: (index) {
            //点击菜单触发的方法
            //注意
            setState(() {
              _currentIndex = index;
            });
          },
          items:  [
            // BottomNavigationBarItem(icon: Icon(Icons.home), label: 'FrontPage'.tr),
            BottomNavigationBarItem(icon: Icon(Icons.functions), label: "Function".tr),
            BottomNavigationBarItem(icon: Icon(Icons.message), label: "Information".tr),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: "FocusOn".tr),
            // BottomNavigationBarItem(icon: Icon(Icons.people), label: "Mine".tr)
          ]),
      floatingActionButton: Container(
        height: 60,
        //调整FloatingActionButton的大小
        width: 60,
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.only(top: 5),
        //调整FloatingActionButton的位置
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: FloatingActionButton(
            backgroundColor: _currentIndex == 2 ? Colors.red : Colors.blue,
            child: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _currentIndex = 1;
              });
            }),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked, //配置浮动按钮的位置
    );
  }
}
