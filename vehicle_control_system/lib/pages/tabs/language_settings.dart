import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LanguageSettings extends StatefulWidget {
  const LanguageSettings({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<LanguageSettings> {
  bool _darkMode = false;
  bool _followSystem = false;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("112222222222");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LanguageSettings'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Get.back();
            // 返回按钮的处理逻辑
          },
        ),
      ),
      body: ListView(
        children: <Widget>[
          _buildSwitchListTile(
            'LanguageSwitch'.tr,
            'Close Chinese or open Chinese'.tr,
            _darkMode,
            (bool value) {
              if (value) {
                var locale = const Locale('en', 'US');
                Get.updateLocale(locale);
              } else if (value == false) {
                var locale = const Locale('zh', 'CN');
                Get.updateLocale(locale);
              }
              print(value);
              setState(() {
                _darkMode = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchListTile(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}
