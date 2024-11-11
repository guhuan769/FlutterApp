import 'package:flutter/material.dart';
import 'dart:async';

class CounterWidgetFour extends StatefulWidget {
  final num initialValue;
  final num step;
  final Color? backgroundColor;
  final Color? iconColor;
  final TextStyle? textStyle;
  final ValueChanged<num>? onChanged;
  final String? title;
  final TextStyle? titleStyle;
  final TextEditingController? controller;
  final double? height;
  final VoidCallback? onLeftPressed;
  final VoidCallback? onRightPressed;

  const CounterWidgetFour({
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
    this.height,
    this.onLeftPressed,
    this.onRightPressed,
  });

  @override
  _CounterWidgetFourState createState() => _CounterWidgetFourState();
}

class _CounterWidgetFourState extends State<CounterWidgetFour> {
  late num _counter;
  late TextEditingController _controller;
  Timer? _timer;
  Timer? _leftTimer;
  Timer? _rightTimer;

  @override
  void initState() {
    super.initState();
    _counter = widget.initialValue;
    _controller = widget.controller ?? TextEditingController();
    _controller.text = _formatValue(_counter);
  }

  String _formatValue(num value) {
    return value is int ? value.toString() : value.toStringAsFixed(2);
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
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) => action());
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _startLeftTimer() {
    _leftTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (widget.onLeftPressed != null) {
        widget.onLeftPressed!();
      }
    });
  }

  void _stopLeftTimer() {
    _leftTimer?.cancel();
  }

  void _startRightTimer() {
    _rightTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (widget.onRightPressed != null) {
        widget.onRightPressed!();
      }
    });
  }

  void _stopRightTimer() {
    _rightTimer?.cancel();
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
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onLongPressStart: (_) => _startTimer(_incrementCounter),
            onLongPressEnd: (_) => _stopTimer(),
            child: IconButton(
              icon: Icon(Icons.add, size: 28, color: widget.iconColor ?? Colors.blue),
              onPressed: _incrementCounter,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left Button
              GestureDetector(
                onLongPressStart: (_) => _startLeftTimer(),
                onLongPressEnd: (_) => _stopLeftTimer(),
                child: IconButton(
                  icon: Icon(Icons.add, size: 28, color: widget.iconColor ?? Colors.blue),
                  onPressed: widget.onLeftPressed,
                ),
              ),
              // Center input field
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: TextFormField(
                    controller: _controller,
                    textAlign: TextAlign.center,
                    style: widget.textStyle ?? const TextStyle(fontSize: 18.0),
                    decoration: InputDecoration(
                      labelText: widget.title,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: _onTextChanged,
                  ),
                ),
              ),
              // Right Button
              GestureDetector(
                onLongPressStart: (_) => _startRightTimer(),
                onLongPressEnd: (_) => _stopRightTimer(),
                child: IconButton(
                  icon: Icon(Icons.remove, size: 28, color: widget.iconColor ?? Colors.blue),
                  onPressed: widget.onRightPressed,
                ),
              ),
            ],
          ),
          GestureDetector(
            onLongPressStart: (_) => _startTimer(_decrementCounter),
            onLongPressEnd: (_) => _stopTimer(),
            child: IconButton(
              icon: Icon(Icons.remove, size: 28, color: widget.iconColor ?? Colors.blue),
              onPressed: _decrementCounter,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _leftTimer?.cancel();
    _rightTimer?.cancel();
    super.dispose();
  }
}
