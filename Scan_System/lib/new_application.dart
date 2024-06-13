import 'package:flutter/material.dart';
import 'package:scan_system/Utils/common_toast.dart';
import 'package:scan_system/home_page.dart';
import 'package:scan_system/my_page.dart';
import 'package:scan_system/scan_page.dart';
import 'package:scan_system/setting_page.dart';

class NewApplication extends StatefulWidget {
  const NewApplication({super.key});

  @override
  State<NewApplication> createState() => _NewApplicationState();
}

class _NewApplicationState extends State<NewApplication> {

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
      home:const HomePage()
    );
  }
}
