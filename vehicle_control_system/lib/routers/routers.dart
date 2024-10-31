import 'package:get/get.dart';
import 'package:vehicle_control_system/pages/tabs/dark_setting.dart';
import 'package:vehicle_control_system/pages/tabs/focus_on.dart';
import 'package:vehicle_control_system/pages/tabs/language_settings.dart';
import 'package:vehicle_control_system/pages/tabs/setting.dart';
import '../pages/tabs.dart';
import '../pages/shop.dart';
import '../pages/user/login.dart';
import '../pages/user/registerFirst.dart';
import '../pages/user/registerSecond.dart';
import '../pages/user/registerThird.dart';
import '../middlewares/shopMiddleware.dart';

class AppPage {
  static final routes = [
    GetPage(name: "/", page: () => const Tabs()),
    GetPage(
        name: "/shop",
        page: () => const ShopPage(),
        middlewares: [ShopMiddleWare()]),
    GetPage(name: "/login", page: () => const LoginPage()),
    GetPage(
        name: "/registerFirst",
        page: () => const RegisterFirstPage(),
        transition: Transition.fade),
    GetPage(name: "/registerSecond", page: () => const RegisterSecondPage()),
    GetPage(name: "/registerThird", page: () => const RegisterThirdPage()),
    GetPage(name: "/setting", page: () => const SettingPage()),
    GetPage(name: "/dark_setting", page: () => const DarkSetting()),
    GetPage(name: "/focus_on", page: () => const FocusOn()),
    GetPage(name: "/language_settings", page:  ()=> const LanguageSettings()),
    //GetPage(name: "/", page: page:()=>)
  ];

}
