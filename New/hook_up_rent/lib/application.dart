/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-16 14:58:13
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-05-22 09:06:52
 * @FilePath: \hook_up_rent\lib\application.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:hook_up_rent/pages/home/index.dart';
import 'package:hook_up_rent/pages/login.dart';
import 'package:hook_up_rent/routes.dart';
import 'package:hook_up_rent/scoped_model/auth.dart';
import 'package:scoped_model/scoped_model.dart';

class Application extends StatelessWidget {
  const Application({super.key});
  @override
  Widget build(BuildContext context) {
    FluroRouter router = FluroRouter();
    Routes.configureRoutes(router);
    return ScopedModel<AuthModel>(
        model: AuthModel(),
        child: MaterialApp(
          theme: ThemeData(primarySwatch: Colors.green),
          home: const LoginPage(),
          // home: HomePage(),
          onGenerateRoute: router.generator,
        ));
  }
}
