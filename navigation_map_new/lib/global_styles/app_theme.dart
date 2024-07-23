import 'package:flutter/material.dart';

import 'CustomContainerTheme.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.yellow,
    // scaffoldBackgroundColor: Colors.grey[200],
    scaffoldBackgroundColor: Colors.grey[200],
    // 底部导航栏样式
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      // 设置背景颜色
      selectedItemColor: Colors.red,
      // 设置选中项颜色
      unselectedItemColor: Colors.grey,
      // 设置未选中项颜色
      selectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      // 设置选中项标签样式
      unselectedLabelStyle: TextStyle(fontSize: 12), // 设置未选中项标签样式
    ),
    // customContainerTheme: CustomContainerTheme(
    //   color: Colors.grey[100],
    //   border: Border.all(color: Colors.blue, width: 2.0),
    //   borderRadius: BorderRadius.circular(10.0),
    // ),
    //全局背景色
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.grey,
    ).copyWith(
      secondary: Colors.grey,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.greenAccent,
      elevation: 16,
    ),
    iconTheme: const IconThemeData(
      size: 35.0,
      color: Colors.greenAccent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.green,
        shadowColor: Colors.orange,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        textStyle: const TextStyle(fontSize: 20),
      ),
    ),
    textTheme: const TextTheme(
      // bodyLarge: TextStyle(color: Colors.white),
      // bodyMedium: TextStyle(color: Colors.black),
      displayLarge: TextStyle(
          color: Colors.white, fontSize: 72.0, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(
          color: Colors.white, fontSize: 36.0, fontStyle: FontStyle.italic),
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16.0),
      bodyMedium: TextStyle(
          color: Colors.grey, fontSize: 14.0, fontWeight: FontWeight.bold),
      bodySmall: TextStyle(fontSize: 12.0),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: Colors.white,
      titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20),
      contentTextStyle: const TextStyle(color: Colors.grey, fontSize: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Colors.red,
      textTheme: ButtonTextTheme.primary,
    ),

// colorScheme: const ColorScheme.light(
//   primary: Colors.orangeAccent,
// ),
// primaryColor: Colors.orangeAccent, // 设置按钮背景颜色
// primarySwatch: Colors.amber, // 设置主色，影响按钮等部件的颜色
// accentColor: Colors.green, // 设置强调色，通常用于按钮和其他交互元素
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.black),
      actionsIconTheme: IconThemeData(color: Colors.black38),
      centerTitle: false,
      elevation: 15,
      titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.dark,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 18),
      ),
    ),
    dialogTheme: const DialogTheme(
      backgroundColor: Colors.black,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
      contentTextStyle: TextStyle(color: Colors.white70, fontSize: 16),
    ),
  );
}
