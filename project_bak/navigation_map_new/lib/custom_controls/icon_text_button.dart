import 'package:flutter/material.dart';

class IconTextButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  final Color textColor;
  final double iconSize;
  final double textSize;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final bool filled;
  final Color fillColor;

  const IconTextButton({
    super.key,
    required this.icon,
    required this.text,
    required this.iconColor,
    required this.textColor,
    required this.iconSize,
    required this.textSize,
    required this.onPressed,
    required this.width,
    required this.height,
    this.filled = false,
    this.fillColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,

      decoration: BoxDecoration(
        color: filled ? fillColor : Colors.white,
        border: Border.all(color: filled ? Colors.black12 : Colors.white),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withOpacity(0.1),
            // spreadRadius: 2,
            // blurRadius: 5,
            // offset: const Offset(0, 0),
          ),
        ],
        gradient: filled
            ? LinearGradient(
          colors: [fillColor.withOpacity(0.7), fillColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        splashColor: Colors.grey.withOpacity(0.2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: iconSize,
              color: iconColor,
            ),
            const SizedBox(width: 5),
            Text(
              text,
              style: TextStyle(
                fontSize: textSize,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
