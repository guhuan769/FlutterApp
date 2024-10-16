
import 'package:get/get.dart';
import '../pages/tabs.dart';
import '../pages/shop.dart';
import '../pages/user/login.dart';
import '../pages/user/registerFirst.dart';
import '../pages/user/registerSecond.dart';
import '../pages/user/registerThird.dart';
import '../middlewares/shopMiddleware.dart';
class AppPage{
  static final routes= [
        GetPage(name: "/", page: () => const Tabs()),
        GetPage(name: "/shop", page: () => const ShopPage(),
        middlewares:[
          ShopMiddleWare()
        ]),
        GetPage(name: "/login", page: () => const LoginPage()),
        GetPage(
            name: "/registerFirst",
            page: () => const RegisterFirstPage(),
            transition: Transition.fade),
        GetPage(
            name: "/registerSecond", page: () => const RegisterSecondPage()),
        GetPage(name: "/registerThird", page: () => const RegisterThirdPage()),
       
  ];
}
