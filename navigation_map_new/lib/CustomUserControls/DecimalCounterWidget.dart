import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:navigation_map/global_styles/CustomContainerTheme.dart';

///
/// 允许输入的加减器并且支持小数点
///
class DecimalCounterWidget extends StatefulWidget {
  final ValueChanged<String> onValueChanged;

  const DecimalCounterWidget({super.key, required this.onValueChanged});

  @override
  _DecimalCounterWidgetState createState() => _DecimalCounterWidgetState();
}

class _DecimalCounterWidgetState extends State<DecimalCounterWidget> {
  final TextEditingController _controller = TextEditingController();

  Color _borderColor = Colors.greenAccent; // Default border color

  @override
  void initState() {
    super.initState();
    _controller.text = '0.0';
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      if (_controller.text.isEmpty) {
        _borderColor = Colors.red; // Change border color to red if empty
      } else {
        _borderColor = Colors.greenAccent; // Reset to default color if not empty
      }
    });
    widget.onValueChanged(_controller.text);
  }

  void _incrementCounter() {
    setState(() {
      double currentValue = double.tryParse(_controller.text) ?? 0.0;
      currentValue += 0.1;
      _controller.text = currentValue.toStringAsFixed(1);
    });
  }

  void _decrementCounter() {
    setState(() {
      double currentValue = double.tryParse(_controller.text) ?? 0.0;
      currentValue -= 0.1;
      _controller.text = currentValue.toStringAsFixed(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).customContainerTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: _decrementCounter,
        ),
        Container(
          width: 100,
          decoration: BoxDecoration(
            // border: Border.all(color:theme.decimalBorder, width: 2.0),
          ),
          child: TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'^[+-]?([0-9]*[.]?[0-9]*)$')),
            ],
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _controller.text.isEmpty ? Colors.red : theme.textStyleSelect,), // Use dynamic border color
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _controller.text.isEmpty ? Colors.red : theme.textStyleUnselect,), // Use dynamic border color
              ),
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _incrementCounter,
        ),
      ],
    );
  }
}
