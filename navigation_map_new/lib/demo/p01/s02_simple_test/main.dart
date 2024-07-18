import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'paper.dart';

void main() {
  // flutter run -t lib/p01/s02_simple_test/main.dart
  // 确定初始化
  WidgetsFlutterBinding.ensureInitialized();
  //横屏
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  //全屏显示
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

  runApp(Paper());
}