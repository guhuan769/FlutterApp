import 'package:flutter/material.dart';
import './routers/routers.dart';
import 'package:get/get.dart';
import './Utilities/language.dart';

void main() {

  runApp(const MyApp());
}

// Future<String> getSavedLanguage() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   return prefs.getString('language_code') ?? 'zh'; // 默认语言为中文
// }

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: '',
      translations: Messages(), // 你的翻译
      locale: const Locale('zh', 'CN'), // 将会按照此处指定的语言翻译
      fallbackLocale: const Locale('en', 'US'), // 添加
      theme: ThemeData(
          primarySwatch: Colors.blue,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
          )),
      initialRoute: "/login",
      // onGenerateRoute: onGenerateRoute,
      defaultTransition: Transition.rightToLeft,
      getPages:AppPage.routes,
    );
  }
}
