import 'package:flutter/material.dart';
import 'package:vehicle_control_system/models/AppItem.dart';
import 'package:vehicle_control_system/pages/controls/AppGrid.dart';
import 'package:vehicle_control_system/pages/controls/AppGridItem.dart';

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