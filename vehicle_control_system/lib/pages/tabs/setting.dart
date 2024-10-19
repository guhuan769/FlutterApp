import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('设置'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {

              // 返回按钮的处理逻辑
              Get.back();
            },
          ),
        ),
        body: ListView(
          children: <Widget>[
            _buildListTile(context, '账号资料'),
            _buildListTile(context, '安全隐私'),
            _buildListTile(context, '开屏画面设置'),
            _buildListTile(context, '首页推荐设置'),
            _buildListTile(context, '首页头像入口设置'),
            _buildListTile(context, '深色设置'),
            _buildListTile(context, '语言设置'),
            _buildListTile(context, '消息设置'),
            _buildListTile(context, '下载管理'),
            _buildListTile(context, '清理存储空间'),
          ].map((widget) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: widget,
          )).toList(),
        ),
        // bottomNavigationBar: BottomNavigationBar(
        //   items: [
        //     BottomNavigationBarItem(
        //       icon: Icon(Icons.home),
        //       label: '首页',
        //     ),
        //     BottomNavigationBarItem(
        //       icon: Icon(Icons.search),
        //       label: '搜索',
        //     ),
        //     BottomNavigationBarItem(
        //       icon: Icon(Icons.person),
        //       label: '我的',
        //     ),
        //   ],
        // ),
    );
  }

  Widget _buildListTile(BuildContext context, String title) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      tileColor: Colors.white,
      onTap: () {
        // 点击事件处理逻辑
        // ScaffoldMessenger.of(fvmcontext).showSnackBar(
        //   SnackBar(content: Text('$title 被点击')),
        // );
        switch(title){
          case "深色设置":
            // print('今天是星期一');
            Get.toNamed('/dark_setting');
            break;
          case "语言设置":
            Get.toNamed('/language_settings');
            break;
        }
      },
    );
  }
}