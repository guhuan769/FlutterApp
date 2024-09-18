import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'dart:math';

const ballSize = 20.0;
const step = 10.0;

class Testjoystick extends StatefulWidget {
  const Testjoystick({super.key});

  @override
  State<Testjoystick> createState() => _TestjoystickState();
}

class _TestjoystickState extends State<Testjoystick> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Flutter Joystick 示例'),
      // ),
      body: Center(
        child: Joystick(
          listener: (details) {
            double angle = atan2(details.y, details.x) * (180 / pi);
            if (angle < 0) angle += 360; // 将角度转换为0-360度范围
            print('操纵杆角度: $angle°');
            print('操纵杆移动到: ${details.x}, ${details.y}');

            String direction = getDirection(details.x, details.y);
            print('操纵杆方向: $direction');
          },
        ),
      ),
    );
  }

  String getDirection(double x, double y) {
    if (y < -0.5) {
      return '前';
    } else if (y > 0.5) {
      return '后';
    } else if (x < -0.5) {
      return '左';
    } else if (x > 0.5) {
      return '右';
    } else {
      return '中心';
    }
  }
}

