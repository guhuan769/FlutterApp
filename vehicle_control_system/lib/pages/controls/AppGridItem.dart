import 'package:flutter/material.dart';
import 'package:vehicle_control_system/models/AppItem.dart';

class AppGridItem extends StatelessWidget {
  final AppItem item;
  final bool isSelected;
  final VoidCallback onTap;

  AppGridItem({required this.item, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.blue.withAlpha(30),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: isSelected ? Colors.blue.withAlpha(50) : Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 50.0),
              SizedBox(height: 10.0),
              Text(item.label),
            ],
          ),
        ),
      ),
    );
  }
}