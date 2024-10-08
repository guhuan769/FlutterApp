import 'package:flutter/material.dart';

class CustomContainerTheme {
  final Color color;
  final Color titleColor;
  final Color decimalBorder;
  final Color textStyleSelect;
  final Color textStyleUnselect;
  final TextStyle textStyle;
  final BoxBorder? border;
  final BorderRadiusGeometry? borderRadius;

  CustomContainerTheme( {required this.textStyleSelect, required this.textStyleUnselect,
    required this.titleColor, required this.textStyle,required this.color,
    required this.decimalBorder, this.border, this.borderRadius});
}

extension CustomThemeData on ThemeData {
  CustomContainerTheme get customContainerTheme => CustomContainerTheme(
    textStyleSelect: Colors.greenAccent,
    textStyleUnselect: Colors.green,
    titleColor: Colors.white,
    textStyle: const TextStyle(color: Colors.black),
    color: Colors.grey,
    decimalBorder: Colors.greenAccent,
    border: Border.all(color: Colors.blue, width: 2.0),
    borderRadius: BorderRadius.circular(10.0),
  );
}