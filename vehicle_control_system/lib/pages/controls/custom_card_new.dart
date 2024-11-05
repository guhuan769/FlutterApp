import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomCardNew extends StatelessWidget {
  final String title;
  final Widget child;

  CustomCardNew({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: Get.theme.cardColor, // 使用 GetX 主题的卡片颜色
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Get.textTheme.titleLarge?.copyWith( // 使用 GetX 主题的文本样式
                fontWeight: FontWeight.bold,
                color: Get.theme.primaryColor,
              ),
            ),
            SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
