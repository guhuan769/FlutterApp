import 'package:flutter/material.dart';
import 'VoiceControlWidget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Voice Control Example')),
        body: Center(
          child: VoiceControlWidget(),
        ),
      ),
    );
  }
}