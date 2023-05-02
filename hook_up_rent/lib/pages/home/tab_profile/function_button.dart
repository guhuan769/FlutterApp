import 'package:flutter/material.dart';
import 'package:hook_up_rent/pages/home/tab_profile/function_button_data.dart';
import 'package:hook_up_rent/pages/home/tab_profile/function_button_widget.dart';

class FunctionButton extends StatelessWidget {
  const FunctionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Wrap(
        spacing: 1.0, //边距 水平方向
        runSpacing: 1.0, //垂直方向
        children: list.map((item) => FuntionButtonWidget(data: item,)).toList(),
      ),
    );
  }
}
