import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomNormalTextField extends StatelessWidget {
  final TextEditingController controller;

  const CustomNormalTextField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 50,
      child: TextField(
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center, // 垂直居中
        autofocus: false,
        controller: controller,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.greenAccent), // 未选中时的边框颜色
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green), // 选中时的边框颜色
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
