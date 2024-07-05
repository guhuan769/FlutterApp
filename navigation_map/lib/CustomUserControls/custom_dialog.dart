import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String description;
  final List<TextButton> actions;

  CustomDialog({required this.title, required this.description, required this.actions});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(description),
      actions: actions,
    );
  }
}
