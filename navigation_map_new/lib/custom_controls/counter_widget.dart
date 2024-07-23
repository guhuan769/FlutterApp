import 'package:flutter/material.dart';

class CounterWidget extends StatefulWidget {
  final double initialValue;
  final double step;
  final Color? backgroundColor;
  final Color? iconColor;
  final TextStyle? textStyle;
  final ValueChanged<double>? onChanged;
  final String? title; // Add a title parameter
  final TextStyle? titleStyle; // Add a title style parameter

  const CounterWidget({
    super.key,
    this.initialValue = 0.0,
    this.step = 1.0,
    this.backgroundColor,
    this.iconColor,
    this.textStyle,
    this.onChanged,
    this.title, // Initialize the title parameter
    this.titleStyle, // Initialize the title style parameter
  });

  @override
  _CounterWidgetState createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  late double _counter;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _counter = widget.initialValue;
    _controller.text = _counter.toString();
  }

  void _incrementCounter() {
    setState(() {
      _counter += widget.step;
      _controller.text = _counter.toString();
      widget.onChanged?.call(_counter);
    });
  }

  void _decrementCounter() {
    setState(() {
      _counter -= widget.step;
      _controller.text = _counter.toString();
      widget.onChanged?.call(_counter);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(50.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            // spreadRadius: 2,
            // blurRadius: 5,
            // offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // if (widget.title != null) // Check if title is provided
          //   Text(
          //     widget.title!,
          //     style: widget.titleStyle ?? const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          //   ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.remove,
                    size: 20, color: widget.iconColor ?? Colors.black),
                onPressed: _decrementCounter,
              ),
              SizedBox(
                width: 80, // Set a fixed width for the text box
                height: 45,
                child: TextFormField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  style: widget.textStyle ?? const TextStyle(fontSize: 15.0),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    // hintText:'123',
                    labelText: widget.title,
                    // labelStyle: TextStyle(
                    //   color: Colors.green,
                    //   fontSize: 20,
                    //   fontStyle: FontStyle.italic, // 设置斜体
                    //   decoration: TextDecoration.underline, // 设置下划线
                    // ),
                  ),
                  readOnly: true, // Make the TextFormField read-only
                ),
              ),
              IconButton(
                icon: Icon(Icons.add,
                    size: 20, color: widget.iconColor ?? Colors.black),
                onPressed: _incrementCounter,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
