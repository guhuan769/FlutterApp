import 'package:flutter/material.dart';

class CustomCircle extends StatelessWidget {
  final double diameter;
  final Color color;

  const CustomCircle({super.key, required this.diameter, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
