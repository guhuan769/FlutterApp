import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: TextField(
        controller: controller,
        autofocus: false,
        //   // 带下线的
        //   // decoration: const InputDecoration(
        //   //   labelText: "相对运行",
        //   //   hintText: "请输入坐标",
        //   //   prefixIcon: Icon(Icons.table_view),
        //   // ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.blueAccent.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide.none,
          ),
          hintText: hintText,
          hintStyle: Theme.of(context).textTheme.bodyMedium,
          labelText: labelText,
          labelStyle: Theme.of(context).textTheme.bodyMedium,
          prefixIcon:
              Icon(prefixIcon, color: Theme.of(context).colorScheme.secondary),
        ),
        style: const TextStyle(color: Colors.black),
        cursorColor: Colors.blue,
      ),
    );
  }
}
