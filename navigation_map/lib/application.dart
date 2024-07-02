import 'package:flutter/material.dart';
import 'package:navigation_map/home_page.dart';

class Application extends StatefulWidget {
  const Application({super.key});

  @override
  State<Application> createState() => _NewApplicationState();
}

class _NewApplicationState extends State<Application> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: '导航系统',
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
