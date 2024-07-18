import 'package:flutter/material.dart';

///
/// 不允许输入的 加减器
///
class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});

  @override
  _CounterWidgetState createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _decrementCounter() {
    setState(() {
      _counter--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.remove),
          onPressed: _decrementCounter,
        ),
        Text('$_counter', style: TextStyle(fontSize: 20.0)),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: _incrementCounter,
        ),
      ],
    );
  }
}
