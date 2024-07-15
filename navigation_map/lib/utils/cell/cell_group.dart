import 'package:flutter/material.dart';
import 'cell.dart';

class CellGroup extends StatelessWidget {
  final List<Cell?> children;
  BorderRadius? borderRadius;

  CellGroup({super.key, required this.children, this.borderRadius}) {
    for (var element in children) {
      if (element == null) {
        continue;
      }
      element.margin = const EdgeInsets.all(0);
      element.borderRadius = const BorderRadius.all(Radius.circular(0));
      element.backgroundColor = Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:  Theme.of(context).colorScheme.secondary,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
      child: Column(
        children: () {
          List<Widget> childs = [];
          for (var element in children) {
            if (element == null) {
              continue;
            }
            childs.add(element);
            childs.add(Divider());
          }
          return childs;
        }(),
      ),
    );
  }
}
