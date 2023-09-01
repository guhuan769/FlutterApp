/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-23 12:38:42
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-23 12:52:16
 * @FilePath: \hook_up_rent\lib\scoped_model\auth.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */

import 'package:flutter/material.dart';
import 'package:hook_up_rent/pages/utils/store.dart';
import 'package:scoped_model/scoped_model.dart';

class AuthModel extends Model {
  String _token = '';

  String get Token => _token;
  bool get isLogin => _token is String && _token != null;
  void initApp(BuildContext context) async {
    Store store = await Store.getInstance();
    //拿到道歉Store
    String token = await store.getString(StoreKeys.token);
    if (token != '') {
      login(token, context);
    }
  }

  void login(String token, BuildContext context) {
    _token = token;
    //告诉所有使用得组件我要更新了
    notifyListeners();
  }

  void logout() {
    _token = '';
    notifyListeners();
  }
}
