import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomCard extends StatelessWidget {
  final double screenWidth;
  final String title;
  final Widget child;
  final IconData? icon;
  final ImageProvider? image;
  final Color? color;

  const CustomCard({
    super.key,
    required this.screenWidth,
    required this.title,
    required this.child,
    this.icon,
    this.image,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Get.theme; // 使用 GetX 主题
    return Row(
      children: [
        SizedBox(
          width: screenWidth * 0.97,
          child: Card(
            color: color ?? theme.cardColor,
            child: Stack(
              children: [
                if (image != null)
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: image!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      child,
                    ],
                  ),
                ),
                Positioned(
                  top: 5,
                  left: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        if (icon != null)
                          Icon(
                            icon,
                            size: 20,
                            color: theme.iconTheme.color,
                          ),
                        const SizedBox(width: 7),
                        Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.primaryColorLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
