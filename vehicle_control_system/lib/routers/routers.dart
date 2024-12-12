import 'package:get/get.dart';
import 'package:vehicle_control_system/pages/exercise_control/car_body_control.dart';
import 'package:vehicle_control_system/pages/exercise_control/configuration/configuration_manager.dart';
import 'package:vehicle_control_system/pages/exercise_control/configuration/welding_real_time_configuration_panel.dart';
import 'package:vehicle_control_system/pages/exercise_control/remote_control/executor_standard_library.dart';
import 'package:vehicle_control_system/pages/exercise_control/remote_control/freelander_standard_model.dart';
import 'package:vehicle_control_system/pages/exercise_control/remote_control/navigation.dart';
import 'package:vehicle_control_system/pages/exercise_control/remote_control/remote_control_manager.dart';
import 'package:vehicle_control_system/pages/exercise_control/remote_control/wind_walker_lift_model.dart';
import 'package:vehicle_control_system/pages/exercise_control/remote_control/wind_walker_standard.dart';
import 'package:vehicle_control_system/pages/exercise_control/robotic_control/roboti_control_panel.dart';
import 'package:vehicle_control_system/pages/exercise_control/robotic_control/robotic_control_manager.dart';
import 'package:vehicle_control_system/pages/feedback/feedback_binding.dart';
import 'package:vehicle_control_system/pages/feedback/feedback_page.dart';
import 'package:vehicle_control_system/pages/tabs/dark_setting.dart';
import 'package:vehicle_control_system/pages/tabs/focus_on.dart';
import 'package:vehicle_control_system/pages/tabs/language_settings.dart';
import 'package:vehicle_control_system/pages/tabs/setting.dart';
import 'package:vehicle_control_system/pages/user/register_page.dart';
import '../pages/tabs.dart';
import '../pages/shop.dart';
import '../pages/user/login.dart';
import '../pages/user/registerFirst.dart';
import '../pages/user/registerSecond.dart';
import '../pages/user/registerThird.dart';
import '../middlewares/shopMiddleware.dart';

class AppPage {
  static final routes = [
    //tabs
    GetPage(
      name: '/feedback',
      page: () => const FeedbackPage(),
      binding: FeedbackBinding(),
    ),

    GetPage(name: "/", page: () => const Tabs()),
    GetPage(
        name: "/shop",
        page: () => const ShopPage(),
        middlewares: [ShopMiddleWare()]),
    GetPage(name: "/login", page: () =>  LoginPage()),
    GetPage(name: "/register_page", page: () =>  RegisterPage()),


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
    GetPage(name: "/remote_control_manager", page:()=> const RemoteControlManager()),
    GetPage(name: "/robotic_control_manager", page:()=> const RoboticControlManager()),
    GetPage(name: "/car_body_control", page:()=>  CarBodyControl()),
    GetPage(name: "/roboti_control_panel", page:()=>  RobotiControlPanel()),
    //遥控器
    GetPage(name: "/navigation", page:()=> const Navigation()),
    GetPage(name: "/wind_walker_lift_model", page:()=> const WindWalkerLiftModel()),
    GetPage(name: "/wind_walker_standard", page:()=> const WindWalkerStandard()),
    GetPage(name: "/freelander_standard_model", page:()=> const FreelanderStandardModel()),
    GetPage(name: "/executor_standard_library", page:()=> const ExecutorStandardLibrary()),
    //配置
    GetPage(name: "/welding_real_time_configuration_panel", page:()=> const WeldingRealTimeConfigurationPanel()),
    GetPage(name: "/configuration_manager", page:()=> const ConfigurationManager()),

  ];

}
