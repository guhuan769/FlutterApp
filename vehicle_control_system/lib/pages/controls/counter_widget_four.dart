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
  final ValueChanged<num>? onLeftPressed;  // 将传出当前输入框的值(负数)
  final ValueChanged<num>? onRightPressed; // 将传出当前输入框的值(正数)

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
      if (_counter - widget.step >= 0) {
        _counter -= widget.step;
        _controller.text = _formatValue(_counter);
        widget.onChanged?.call(_counter);
      }
    });
  }

  // 处理左按钮点击 (传出负值)
  void _handleLeftButtonPress() {
    final num currentValue = num.tryParse(_controller.text) ?? 0;
    widget.onLeftPressed?.call(-currentValue); // 传出当前值的负数
  }

  // 处理右按钮点击 (传出正值)
  void _handleRightButtonPress() {
    final num currentValue = num.tryParse(_controller.text) ?? 0;
    widget.onRightPressed?.call(currentValue); // 传出当前值的正数
  }

  void _startTimer(Function action) {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) => action());
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _startLeftTimer() {
    _leftTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _handleLeftButtonPress();
    });
  }

  void _stopLeftTimer() {
    _leftTimer?.cancel();
  }

  void _startRightTimer() {
    _rightTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _handleRightButtonPress();
    });
  }

  void _stopRightTimer() {
    _rightTimer?.cancel();
  }

  void _onTextChanged(String value) {
    if (value.isEmpty) {
      setState(() {
        _counter = 0;
        widget.onChanged?.call(_counter);
      });
      return;
    }

    num? newValue = num.tryParse(value);
    if (newValue != null && newValue >= 0) {
      setState(() {
        _counter = newValue;
        widget.onChanged?.call(_counter);
      });
    } else {
      _controller.text = _formatValue(_counter);
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height ?? 160,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onLongPressStart: (_) => _startTimer(_incrementCounter),
            onLongPressEnd: (_) => _stopTimer(),
            child: IconButton(
              icon: Icon(Icons.add, size: 24, color: widget.iconColor ?? Colors.blue),
              onPressed: _incrementCounter,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 左边减号按钮
              GestureDetector(
                onLongPressStart: (_) => _startLeftTimer(),
                onLongPressEnd: (_) => _stopLeftTimer(),
                child: IconButton(
                  icon: Icon(Icons.remove, size: 24, color: widget.iconColor ?? Colors.blue),
                  onPressed: _handleLeftButtonPress,
                ),
              ),
              // 中间输入框
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 45,
                  child: TextFormField(
                    controller: _controller,
                    textAlign: TextAlign.center,
                    style: widget.textStyle ?? const TextStyle(fontSize: 16.0),
                    decoration: InputDecoration(
                      labelText: widget.title,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
                      ),
                      errorText: num.tryParse(_controller.text) != null &&
                          num.tryParse(_controller.text)! < 0 ? '不能输入负数' : null,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                    onChanged: _onTextChanged,
                  ),
                ),
              ),
              // 右边加号按钮
              GestureDetector(
                onLongPressStart: (_) => _startRightTimer(),
                onLongPressEnd: (_) => _stopRightTimer(),
                child: IconButton(
                  icon: Icon(Icons.add, size: 24, color: widget.iconColor ?? Colors.blue),
                  onPressed: _handleRightButtonPress,
                ),
              ),
            ],
          ),
          GestureDetector(
            onLongPressStart: (_) => _startTimer(_decrementCounter),
            onLongPressEnd: (_) => _stopTimer(),
            child: IconButton(
              icon: Icon(Icons.remove, size: 24, color: widget.iconColor ?? Colors.blue),
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