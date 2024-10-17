import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DarkSetting extends StatefulWidget {
  const DarkSetting({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<DarkSetting> {
  bool _darkMode = false;
  bool _followSystem = false;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设置'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Get.back();
            // 返回按钮的处理逻辑
          },
        ),
      ),
      body: ListView(
        children: <Widget>[
          _buildSwitchListTile(
            '深色模式',
            '随系统设置开启深色模式',
            _darkMode,
                (bool value) {
              setState(() {
                _darkMode = value;
              });
            },
          ),
          _buildSwitchListTile(
            '深色跟随系统',
            '随系统设置开启深色模式',
            _followSystem,
                (bool value) {
              setState(() {
                _followSystem = value;
              });
            },
          ),
          _buildSwitchListTile(
            '深色模式',
            '随系统设置开启深色模式',
            _darkModeEnabled,
                (bool value) {
              setState(() {
                _darkModeEnabled = value;
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