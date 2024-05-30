// import 'dart:io';
//
// import 'package:flutter/cupertino.dart';
// import 'package:lianyun_driver/util/cy_dialog.dart';
// import 'package:lianyun_driver/util/log.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:device_info_plus/device_info_plus.dart';
//
// class Validator {
//   static bool isEmpty(Object? a) {
//     if (a == null) {
//       return true;
//     } else if (a is String) {
//       return a.isEmpty;
//     } else if (a is List) {
//       return a.isEmpty;
//     } else {
//       return false;
//     }
//   }
//
//   static Future<bool> isGalleryGranted({BuildContext? context}) async {
//     var res = false;
//     // 根据android版本进行判断
//     if (Platform.isAndroid) {
//       DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//       AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//       if (androidInfo.version.sdkInt < 33) {
//         res = await Permission.storage.request().isGranted;
//       } else {
//         res = await Permission.photos.request().isGranted;
//       }
//     } else {
//       res = await Permission.photos.request().isGranted;
//     }
//     if (context == null) {
//       return res;
//     }
//     // 去权限页面
//     cyPrint(res);
//     if (!res) {
//       CyDialog.showPermissionDialog(context, '需要您允许访问相册');
//     }
//     return res;
//   }
//
//   static Future<bool> isCameraGranted({BuildContext? context}) async {
//     var res = await Permission.camera.request().isGranted;
//     if (context == null) {
//       return res;
//     }
//     // 去权限页面
//     if (!res) {
//       CyDialog.showPermissionDialog(context, '需要您允许访问摄像头');
//     }
//     return res;
//   }
//
//   static Future<bool> isLocationGranted({BuildContext? context}) async {
//     var res = await Permission.location.request().isGranted;
//     if (context == null) {
//       return res;
//     }
//     // 去权限页面
//     if (!res) {
//       CyDialog.showPermissionDialog(context, '需要您开启定位权限');
//     }
//     return res;
//   }
// }
