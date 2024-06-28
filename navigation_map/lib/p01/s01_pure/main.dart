// ---->[p01/s01_pure/main.dart]----
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'paper.dart';

void main() {
  // flutter run -t lib/p01/s01_pure/main.dart

  WidgetsFlutterBinding.ensureInitialized(); // 确定初始化
  SystemChrome.setPreferredOrientations(// 使设备横屏显示
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []); // 全屏显示
  runApp(Paper());
}
