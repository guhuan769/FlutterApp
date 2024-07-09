import 'package:flutter/material.dart';
import 'package:navigation_map/GlobalStyles/app_theme.dart';

class Cell extends StatefulWidget {
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
  State<Cell> createState() => _CellState();
}

class _CellState extends State<Cell> {
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) {
        widget.onClick?.call();
      },
      child: Container(
        margin: widget.margin ??
            const EdgeInsets.only(top: 10, left: 10, right: 10),
        padding: widget.padding ??
            const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        decoration: BoxDecoration(
          color: widget.backgroundColor ??
              AppTheme.of(context).colors.backgroundSecond,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                children: <Widget>[
                  widget.icon ?? Container(),
                  widget.icon != null ? const SizedBox(width: 8) : Container(),
                  widget.title,
                  const Spacer(),
                  widget.value ?? Container(),
                  widget.rightIcon != null
                      ? const SizedBox(width: 8)
                      : Container(),
                  widget.rightIcon ?? Container(),
                ],
              ),
            ),
            widget.content != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: widget.content,
                  )
                : Container(),
          ],
        ),
      ),
    ); // 1;
  }
}
