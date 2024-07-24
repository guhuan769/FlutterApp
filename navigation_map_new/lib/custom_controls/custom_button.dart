import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final double width;
  final double height;
  final VoidCallback onPressed; // 添加点击事件回调

  const CustomButton({
    super.key,
    required this.text,
    required this.icon,
    required this.width,
    required this.height,
    required this.onPressed, // 初始化点击事件回调
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10.0),
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200], // 按钮背景颜色
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // 圆角
          ),
          elevation: 5.0, // 阴影
        ),
        onPressed: onPressed, // 设置点击事件
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20.0,
              // color: Colors.white, // 图标颜色
            ),
            Text(
              text,
              style: const TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                // color: Colors.white, // 文字颜色
              ),
            ),
          ],
        ),
      ),
    );
  }
}
