import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StoreKeys { token, none }

//封装Store本地存储
class Store {
  //必须初始化
  static StoreKeys storeKeys = StoreKeys.none;
  late final SharedPreferences _Store;

  static Future<Store> getInstance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return Store._internal(prefs);
  }

  


  //初始化方法
  Store._internal(this._Store);
  getString(StoreKeys key) async {
    return _Store.get(key.toString());
  }

  setString(StoreKeys key, String value) async {
    return _Store.setString(key.toString(), value);
  }

  getStringList(StoreKeys key) async {
    return _Store.getStringList(key.toString());
  }

  setStringList(StoreKeys key, List<String> value) async {
    return _Store.setStringList(key.toString(), value);
  }
}
