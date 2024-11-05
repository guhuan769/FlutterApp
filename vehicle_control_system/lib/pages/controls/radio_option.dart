import 'package:flutter/material.dart';

class RadioOption extends StatelessWidget {
  final String title;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  RadioOption({
    required this.title,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<String>(
          value: title,
          groupValue: groupValue,
          onChanged: onChanged,
        ),
        Text(title),
      ],
    );
  }
}
