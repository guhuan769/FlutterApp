import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:navigation_map/global_styles/CustomContainerTheme.dart';

class CustomNormalTextField extends StatefulWidget {
  final TextEditingController controller;

  const CustomNormalTextField({super.key, required this.controller});

  @override
  _CustomNormalTextFieldState createState() => _CustomNormalTextFieldState();
}

class _CustomNormalTextFieldState extends State<CustomNormalTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.addListener(_updateBorderColor);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateBorderColor);
    super.dispose();
  }

  void _updateBorderColor() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).customContainerTheme;
    return SizedBox(
      width: 70,
      height: 50,
      child: TextField(
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        autofocus: false,
        controller: _controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: _controller.text.isEmpty ? Colors.red : theme.textStyleSelect,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: _controller.text.isEmpty ? Colors.red : theme.textStyleUnselect,
            ),
          ),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly
        ],
        onChanged: (text) {
          print('输入内容: $text');
        },
        onSubmitted: (text) {
          print('提交内容: $text');
        },
        style: const TextStyle(color: Colors.black),
      ),
    );
  }
}
