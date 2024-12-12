// dio_http.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:vehicle_control_system/config/config.dart';

class DioHttp {
  late Dio _client;
  late BuildContext context;

  static DioHttp of(BuildContext context) {
    return DioHttp._internal(context);
  }

  DioHttp._internal(BuildContext context) {
    this.context = context;
    var options = BaseOptions(
      baseUrl: Config.BaseUrl,
      connectTimeout: Duration(milliseconds: 1000 * 10),
      receiveTimeout: Duration(milliseconds: 1000 * 3),
      extra: {'context': context},
    );
    var client = Dio(options);
    this._client = client;
  }

  Future<Response<Map<String, dynamic>>> get(String path,
      [Map<String, dynamic>? params, String? token]) async {
    var options = Options(headers: {'Authorization': token != null ? 'Bearer $token' : null});
    return await _client.get(path, queryParameters: params, options: options);
  }

  Future<Response<Map<String, dynamic>>> put(String path,
      [Map<String, dynamic>? params, String? token]) async {
    var options = Options(headers: {'Authorization': token != null ? 'Bearer $token' : null});
    return await _client.put(path, queryParameters: params, options: options);
  }

  Future<Response<Map<String, dynamic>>> putFormData(String path,
      [Map<String, dynamic>? params, String? token]) async {
    var options = Options(headers: {'Authorization': token != null ? 'Bearer $token' : null});
    return await _client.put(path, data: params, options: options);
  }

  Future<Response<Map<String, dynamic>>> post(String path,
      [Map<String, dynamic>? params, String? token]) async {
    var options = Options(headers: {'Authorization': token != null ? 'Bearer $token' : null});
    return await _client.post(path, data: params, options: options);
  }

  Future<Response<Map<String, dynamic>>> postFormData(
      String path,
      dynamic params,  // 修改为 dynamic 类型
      [String? token]
      ) async {
    var options = Options(
      contentType: 'multipart/form-data',
      headers: {'Authorization': token != null ? 'Bearer $token' : null},
    );

    // 如果参数是 Map 类型，转换为 FormData
    final formData = params is FormData ? params : FormData.fromMap(params ?? {});

    return await _client.post(
      path,
      data: formData,
      options: options,
    );
  }
}