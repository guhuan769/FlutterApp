/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-16 16:24:12
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-24 15:44:50
 * @FilePath: \hook_up_rent\lib\routes.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:hook_up_rent/pages/home/index.dart';
import 'package:hook_up_rent/pages/login.dart';
import 'package:hook_up_rent/pages/not_found.dart';
import 'package:hook_up_rent/pages/production/line_detail/index.dart';
import 'package:hook_up_rent/pages/production_detail/index.dart';
import 'package:hook_up_rent/pages/production_manager/index.dart';
import 'package:hook_up_rent/pages/register.dart';
import 'package:hook_up_rent/pages/setting.dart';

class Routes {
  //定义路由明长城
  static String home = '/home';
  static String login = '/login';
  static String productionDetail = '/production/:detailId';
  static String register = '/register';
  static String setting = '/setting';
  static String productionmanager = '/productionmanager';
  static String linedetail = '/linedetail/:detailId';

  //定义路由处理函数
  static final Handler _homeHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, dynamic> params) {
    return const HomePage();
  });

  static final Handler _loginHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, dynamic> params) {
    return const LoginPage();
  });

  static final Handler _notFoundHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, dynamic> params) {
    return const NotFoundPage();
  });

  static Handler _productionDetailHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, dynamic> params) {
    return ProductionDetailPage(detailId: params['detailId'][0]);
    //  return ProductionDetailPage(params["id"][0]);
  });

  static Handler _registerHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, dynamic> params) {
    return RegisterPage();
    //  return ProductionDetailPage(params["id"][0]);
  });

  static Handler _settingHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, dynamic> params) {
    return SettingPage();
    //  return ProductionDetailPage(params["id"][0]);
  });

  static Handler _productionmanagerHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, dynamic> params) {
    return ProductionManagerPage();
    //  return ProductionDetailPage(params["id"][0]);
  });
  static Handler _linedetailHandler = Handler(
      handlerFunc: (BuildContext? context, Map<String, dynamic> params) {
    return LineDetail(
      detailId: params["detailId"][0],
    );
    //  return ProductionDetailPage(params["id"][0]);
  });

  //编写函数 configureRoutes 关联路由名称和处理函数
  static void configureRoutes(FluroRouter router) {
    router.define(home, handler: _homeHandler);
    router.define(login, handler: _loginHandler);
    router.define(register, handler: _registerHandler);
    router.define(productionDetail, handler: _productionDetailHandler);
    router.define(setting, handler: _settingHandler);
    router.define(productionmanager, handler: _productionmanagerHandler);
    router.define(linedetail, handler: _linedetailHandler);
    router.notFoundHandler = _notFoundHandler;
  }
}
