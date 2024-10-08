import 'package:flutter/material.dart';
// import 'package:desktop_window/desktop_window.dart';
import 'package:navigation_map/application.dart';
import 'dart:math';

void main() async  {
    // WidgetsFlutterBinding.ensureInitialized();
    // await DesktopWindow.setWindowSize(const Size(1280, 720)); // Set your desired width and height

    double degrees = 90;
    double radians = degreesToRadians(degrees);
    print('$degrees 度 = $radians 弧度');
    runApp(const Application());
}

double degreesToRadians(double degrees) {
    return degrees * pi / 180;
}