import 'package:flutter/material.dart';
import 'package:navigation_map/models/AppItem.dart';
import 'package:navigation_map/pages/controls/AppGrid.dart';
import 'package:navigation_map/pages/controls/AppGridItem.dart';

class CategoryPage extends StatelessWidget {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: AppGrid(scrollController: _scrollController),
      ),
    );
  }
}