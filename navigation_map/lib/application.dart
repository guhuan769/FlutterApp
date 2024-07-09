import 'package:flutter/material.dart';
import 'package:navigation_map/home_page.dart';

import 'GlobalStyles/app_theme.dart';

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
        theme:AppTheme.lightTheme ,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // 根据系统设置自动切换主题
        home:const HomePage()
    );
  }
}
