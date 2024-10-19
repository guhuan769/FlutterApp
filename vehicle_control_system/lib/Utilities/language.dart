import 'package:get/get.dart';

class Messages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    //按钮名称
    'zh_CN': {
      'FrontPage': '首页',
      'Function': '功能',
      'Information': '消息',
      'FocusOn': '关注',
      'Mine': '我的',
    },
    'en_US': {
      'FrontPage': 'Front Page',
      'Function': 'Function',
      'Information': 'Information',
      'FocusOn': 'FocusOn',
      'Mine': 'Mine',
    }
  };

}