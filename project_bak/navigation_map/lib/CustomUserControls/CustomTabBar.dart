import 'package:flutter/material.dart';

class CustomTabBar extends StatelessWidget {
  final TabController tabController;
  final List<Tab> tabs;
  final BoxDecoration? indicatorDecoration;
  final bool isScrollable;

  const CustomTabBar({super.key,
    required this.tabController,
    required this.tabs,
    this.indicatorDecoration,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: tabController,
      tabs: tabs,
      indicator: indicatorDecoration ?? BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(10),
      ),
      isScrollable: isScrollable,
    );
  }
}
