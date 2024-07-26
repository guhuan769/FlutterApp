import 'package:flutter/material.dart';
import 'dart:async';

class CounterWidget extends StatefulWidget {
  final num initialValue;
  final num step;
  final Color? backgroundColor;
  final Color? iconColor;
  final TextStyle? textStyle;
  final ValueChanged<num>? onChanged;
  final String? title;
  final TextStyle? titleStyle;
  final TextEditingController? controller;
  final double? width;
  final double? height;

  const CounterWidget({
    super.key,
    this.initialValue = 0.0,
    this.step = 1.0,
    this.backgroundColor,
    this.iconColor,
    this.textStyle,
    this.onChanged,
    this.title,
    this.titleStyle,
    this.controller,
    this.width,
    this.height,
  });

  @override
  _CounterWidgetState createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  late num _counter;
  late TextEditingController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _counter = widget.initialValue;
    _controller = widget.controller ?? TextEditingController();
    _controller.text = _formatValue(_counter);
  }

  String _formatValue(num value) {
    if (value is int) {
      return value.toString();
    } else {
      return value.toStringAsFixed(2);
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter += widget.step;
      _controller.text = _formatValue(_counter);
      widget.onChanged?.call(_counter);
    });
  }

  void _decrementCounter() {
    setState(() {
      _counter -= widget.step;
      _controller.text = _formatValue(_counter);
      widget.onChanged?.call(_counter);
    });
  }

  void _startTimer(Function action) {
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      action();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _onTextChanged(String value) {
    setState(() {
      _counter = num.tryParse(value) ?? _counter;
      widget.onChanged?.call(_counter);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(50.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 10,
            ),
            if (widget.title != null)
              Text(
                widget.title!,
                style: widget.titleStyle ??
                    const TextStyle(
                        fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onLongPressStart: (_) => _startTimer(_decrementCounter),
                  onLongPressEnd: (_) => _stopTimer(),
                  child: IconButton(
                    icon: Icon(Icons.remove,
                        size: 20, color: widget.iconColor ?? Colors.black),
                    onPressed: _decrementCounter,
                  ),
                ),
                SizedBox(
                  width: 80,
                  height: 45,
                  child: TextFormField(
                    controller: _controller,
                    textAlign: TextAlign.center,
                    style: widget.textStyle ?? const TextStyle(fontSize: 15.0),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      // labelText: widget.title,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: _onTextChanged,
                  ),
                ),
                GestureDetector(
                  onLongPressStart: (_) => _startTimer(_incrementCounter),
                  onLongPressEnd: (_) => _stopTimer(),
                  child: IconButton(
                    icon: Icon(Icons.add,
                        size: 20, color: widget.iconColor ?? Colors.black),
                    onPressed: _incrementCounter,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
