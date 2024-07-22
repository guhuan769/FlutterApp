import 'package:flutter/material.dart';

class CounterWidget extends StatefulWidget {
  final double initialValue;
  final double step;
  final Color? backgroundColor;
  final Color? iconColor;
  final TextStyle? textStyle;
  final ValueChanged<double>? onChanged;

  const CounterWidget({
    super.key,
    this.initialValue = 0.0,
    this.step = 1.0,
    this.backgroundColor,
    this.iconColor,
    this.textStyle,
    this.onChanged,
  });

  @override
  _CounterWidgetState createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  late double _counter;

  @override
  void initState() {
    super.initState();
    _counter = widget.initialValue;
  }

  void _incrementCounter() {
    setState(() {
      _counter += widget.step;
      widget.onChanged?.call(_counter);
    });
  }

  void _decrementCounter() {
    setState(() {
      _counter -= widget.step;
      widget.onChanged?.call(_counter);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(50.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.remove, color: widget.iconColor ?? Colors.black),
            onPressed: _decrementCounter,
          ),
          const SizedBox(width: 10,),
          Text(
            '$_counter',
            style: widget.textStyle ?? const TextStyle(fontSize: 24.0),
          ),
          const SizedBox(width: 10,),
          IconButton(
            icon: Icon(Icons.add, color: widget.iconColor ?? Colors.black),
            onPressed: _incrementCounter,
          ),
        ],
      ),
    );
  }
}
