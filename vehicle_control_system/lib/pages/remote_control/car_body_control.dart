import 'package:flutter/material.dart';

class CarBodyControl extends StatelessWidget {
  final String title;

  const CarBodyControl({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('这是 $title 的控制界面'),
      ),
    );
  }
}
