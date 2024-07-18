import 'package:flutter/material.dart';

class Cell extends StatelessWidget {
  final Widget title;
  final Widget? value;

  Widget? content;

  final Widget? icon;
  final Widget? rightIcon;

  EdgeInsets? margin;
  EdgeInsets? padding;

  BorderRadius? borderRadius;

  Color? backgroundColor;
  final void Function()? onClick;

  Cell(
      {super.key,
      required this.title,
      this.value,
      this.icon,
      this.rightIcon,
      this.margin,
      this.padding,
      this.borderRadius,
      this.backgroundColor,
      this.content,
      this.onClick});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) {
        onClick?.call();
      },
      child: Container(
        margin: margin ??
            const EdgeInsets.only(top: 10, left: 10, right: 10),
        padding: padding ??
            const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor ??
              Theme.of(context).colorScheme.secondary,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                children: <Widget>[
                  icon ?? Container(),
                  icon != null ? const SizedBox(width: 8) : Container(),
                  title,
                  const Spacer(),
                  value ?? Container(),
                  rightIcon != null
                      ? const SizedBox(width: 8)
                      : Container(),
                  rightIcon ?? Container(),
                ],
              ),
            ),
            content != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: content,
                  )
                : Container(),
          ],
        ),
      ),
    ); // 1;
  }
}
