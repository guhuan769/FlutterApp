import 'package:flutter/material.dart';
import 'package:vehicle_control_system/data/enum/ToastType.dart';
import 'dart:async';

import 'package:vehicle_control_system/pages/controls/toast.dart';

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
  // 可选的最大值和最小值
  final num? maxValue;
  final num? minValue;
  // 可选的错误提示文本
  final String? maxErrorText;
  final String? minErrorText;

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
    this.maxValue,  // 可选参数
    this.minValue,  // 可选参数
    this.maxErrorText = '超过最大值',
    this.minErrorText = '低于最小值',
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
    return value is int ? value.toString() : value.toStringAsFixed(2);
  }

  // 显示错误提示的方法
  void _showErrorMessage(String message) {

  Toast.show(
    context,
    message,
    type: ToastType.error,
  );

    //自定义
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(message),
    //     duration: const Duration(seconds: 2),
    //     behavior: SnackBarBehavior.floating,
    //     margin: const EdgeInsets.all(10),
    //     backgroundColor: Colors.red.shade700,
    //     action: SnackBarAction(
    //       label: '关闭',
    //       textColor: Colors.white,
    //       onPressed: () {
    //         ScaffoldMessenger.of(context).hideCurrentSnackBar();
    //       },
    //     ),
    //   ),
    // );
  }

  bool _validateValue(num value) {
    if (widget.maxValue != null && value > widget.maxValue!) {
      _showErrorMessage(widget.maxErrorText ?? '超过最大值');
      return false;
    }
    if (widget.minValue != null && value < widget.minValue!) {
      _showErrorMessage(widget.minErrorText ?? '低于最小值');
      return false;
    }
    return true;
  }

  void _incrementCounter() {
    final newValue = _counter + widget.step;
    if (widget.maxValue != null || widget.minValue != null) {
      if (!_validateValue(newValue)) return;
    }
    setState(() {
      _counter = newValue;
      _controller.text = _formatValue(_counter);
      widget.onChanged?.call(_counter);
    });
  }

  void _decrementCounter() {
    final newValue = _counter - widget.step;
    if (widget.maxValue != null || widget.minValue != null) {
      if (!_validateValue(newValue)) return;
    }
    setState(() {
      _counter = newValue;
      _controller.text = _formatValue(_counter);
      widget.onChanged?.call(_counter);
    });
  }

  void _startTimer(Function action) {
    action();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) => action());
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _onTextChanged(String value) {
    if (value.isEmpty) return;

    final newValue = num.tryParse(value);
    if (newValue == null) return;

    if (widget.maxValue != null || widget.minValue != null) {
      if (!_validateValue(newValue)) return;
    }

    setState(() {
      _counter = newValue;
      widget.onChanged?.call(_counter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double containerWidth = widget.width ?? screenWidth * 0.6;

    bool isDecrementDisabled = widget.minValue != null && _counter <= widget.minValue!;
    bool isIncrementDisabled = widget.maxValue != null && _counter >= widget.maxValue!;

    return Container(
      width: containerWidth,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Tooltip(
                  message: isDecrementDisabled ? widget.minErrorText ?? '已达最小值' : '',
                  child: GestureDetector(
                    onLongPressStart: isDecrementDisabled ? null : (_) => _startTimer(_decrementCounter),
                    onLongPressEnd: isDecrementDisabled ? null : (_) => _stopTimer(),
                    child: IconButton(
                      icon: Icon(
                          Icons.remove,
                          size: 28,
                          color: isDecrementDisabled
                              ? Colors.grey
                              : widget.iconColor ?? Colors.blue
                      ),
                      onPressed: isDecrementDisabled ? null : _decrementCounter,
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    width: screenWidth * 0.2,
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
                Tooltip(
                  message: isIncrementDisabled ? widget.maxErrorText ?? '已达最大值' : '',
                  child: GestureDetector(
                    onLongPressStart: isIncrementDisabled ? null : (_) => _startTimer(_incrementCounter),
                    onLongPressEnd: isIncrementDisabled ? null : (_) => _stopTimer(),
                    child: IconButton(
                      icon: Icon(
                          Icons.add,
                          size: 28,
                          color: isIncrementDisabled
                              ? Colors.grey
                              : widget.iconColor ?? Colors.blue
                      ),
                      onPressed: isIncrementDisabled ? null : _incrementCounter,
                    ),
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
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }
}