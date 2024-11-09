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

  void _onTextChanged(String value) {
    setState(() {
      _counter = num.tryParse(value) ?? _counter;
      widget.onChanged?.call(_counter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double containerWidth = widget.width ?? screenWidth * 0.6; // 60% of screen width

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
            // if (widget.title != null)
            //   Padding(
            //     padding: const EdgeInsets.only(bottom: 8.0),
            //     child: Text(
            //       widget.title!,
            //       style: widget.titleStyle ??
            //           TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.black87),
            //     ),
            //   ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onLongPressStart: (_) => _startTimer(_decrementCounter),
                  onLongPressEnd: (_) => _stopTimer(),
                  child: IconButton(
                    icon: Icon(Icons.remove, size: 28, color: widget.iconColor ?? Colors.blue),
                    onPressed: _decrementCounter,
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    width: screenWidth * 0.2, // Ensure the text box is responsive
                    height: 50,
                    child: TextFormField(
                      controller: _controller,
                      textAlign: TextAlign.center,
                      style: widget.textStyle ?? TextStyle(fontSize: 18.0),
                      decoration: InputDecoration(
                        labelText: widget.title!,
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
                GestureDetector(
                  onLongPressStart: (_) => _startTimer(_incrementCounter),
                  onLongPressEnd: (_) => _stopTimer(),
                  child: IconButton(
                    icon: Icon(Icons.add, size: 28, color: widget.iconColor ?? Colors.blue),
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
