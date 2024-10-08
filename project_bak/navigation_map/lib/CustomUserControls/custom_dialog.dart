import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String description;
  final List<TextButton> actions;

  const CustomDialog({super.key, required this.title, required this.description, required this.actions});

  @override
  Widget build(BuildContext context) {
    // Schedule the dialog to close after 2 seconds

    return AlertDialog(
      backgroundColor: Colors.red,
      title: Text(title),
      content: Text(description),
      actions: actions,
    );
  }
}
