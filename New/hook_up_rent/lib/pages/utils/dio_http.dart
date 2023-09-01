// ignore_for_file: empty_constructor_bodies

/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-23 09:51:05
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-25 10:27:23
 * @FilePath: \hook_up_rent\lib\pages\utils\dio_http.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */

// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:hook_up_rent/config.dart';

class DioHttp {
  //在 Flutter 中，late 关键字用于声明一个非空的变量，
  //但不初始化。如果你在类中声明一个字段或顶级变量，它应该是非空的，
  //但不能立即给它赋值，那么你可以使用 late 关键字。当你把 late 放在变量声明的前面时，
  //会告诉 Dart 以下信息：先不要给变量赋值。稍后将为它赋值；你会在使用前对这个变量赋值

  late Dio _client;
  late BuildContext context;

  static DioHttp of(BuildContext context) {
    return DioHttp._internal(context);
  }

  DioHttp._internal(BuildContext context) {
    // if (_client != null || context != this.context) {
    this.context = context;
    var options = BaseOptions(
        baseUrl: Config.BaseUrl,
        connectTimeout: Duration(milliseconds: 1000 * 10),
        receiveTimeout: Duration(milliseconds: 1000 * 3),
        extra: {'context': context});

    var client = Dio(options);
    this._client = client;
    // }
  }

  Future<Response<Map<String, dynamic>>> get(String path,
      [Map<String, dynamic>? params, String? token]) async {
    var options = Options(headers: {'Authorization': 'Bearer ${token}'});
    return await _client.get(path, queryParameters: params, options: options);
  }

  Future<Response<Map<String, dynamic>>> put(String path,
      [Map<String, dynamic>? params, String? token]) async {
    var options = Options(headers: {'Authorization': 'Bearer ${token}'});
    return await _client.put(path, queryParameters: params, options: options);
  }

  Future<Response<Map<String, dynamic>>> putFormData(String path,
      [Map<String, dynamic>? params, String? token]) async {
    var options = Options(headers: {'Authorization': 'Bearer ${token}'});
    return await _client.put(path, data: params, options: options);
  }

  Future<Response<Map<String, dynamic>>> post(String path,
      [Map<String, dynamic>? params, String? token]) async {
    var options = Options(headers: {'Authorization': 'Bearer ${token}'});
    return await _client.post(path, data: params, options: options);
  }

  Future<Response<Map<String, dynamic>>> postFormData(String path,
      [Map<String, dynamic>? params, String? token]) async {
    var options = Options(
        contentType:
            'multipart/form-data', //ContentType.parse('multipart/form-data')
        headers: {'Authorization': 'Bearer ${token}'});
    //,"Access-Control-Allow-Headers": "access-control-allow-origin, authority, content-type, version-info, X-Requested-With",
    return await _client.post(path, data: params, options: options);
  }
}
