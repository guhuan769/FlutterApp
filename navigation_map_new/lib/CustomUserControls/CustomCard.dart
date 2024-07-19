import 'package:flutter/material.dart';
import 'package:navigation_map/global_styles/CustomContainerTheme.dart';

class CustomCard extends StatelessWidget {
  final double screenWidth;
  final String title;
  final Widget child;

  const CustomCard({super.key, required this.screenWidth, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).customContainerTheme;
    return Row(
      children: [
        SizedBox(
          width: screenWidth * 0.97, // 设置宽度为屏幕宽度的97%
          child: Card(
            color: Colors.grey[100],
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 40), // 给标题留出空间
                      child
                    ],
                  ),
                ),
                Positioned(
                  top: 5,
                  left: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.titleColor,
                      borderRadius: BorderRadius.circular(10.0), // 设置圆角半径
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      title,
                      style: theme.textStyle,
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

