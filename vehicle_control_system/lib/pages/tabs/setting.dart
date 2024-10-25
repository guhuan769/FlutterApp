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
        title: Text('Setting'.tr),
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
          _buildListTile(context, 'AccountInformation'.tr),
          _buildListTile(context, 'SecurityPrivacy'.tr),
          _buildListTile(context, 'OpenScreenSetting'.tr),
          _buildListTile(context, 'HomepageRecommendationSettings'.tr),
          _buildListTile(context, 'HomepageEntrySettings'.tr),
          _buildListTile(context, 'DarkSettings'.tr),
          _buildListTile(context, 'LanguageSettings'.tr),
          _buildListTile(context, 'MessageSettings'.tr),
          _buildListTile(context, 'DownloadManagement'.tr),
          _buildListTile(context, 'CleanUpStorageSpace'.tr),
        ]
            .map((widget) =>
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: widget,
            ))
            .toList(),
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
        String LanguageSettings = "LanguageSettings".tr;
        String translatedTitle = "11".tr;

        if (title == 'LanguageSettings'.tr) {
          Get.toNamed('/language_settings');
        }
         else if (title == "DarkSettings".tr) {
          Get.toNamed('/dark_setting');
        }
      },
    );
  }
}
