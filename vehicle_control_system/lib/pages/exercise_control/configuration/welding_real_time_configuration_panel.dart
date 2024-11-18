import 'package:flutter/material.dart';
import 'package:vehicle_control_system/data/models/title_item.dart';
import 'package:get/get.dart';

class WeldingRealTimeConfigurationPanel extends StatefulWidget {
  const WeldingRealTimeConfigurationPanel({super.key});

  @override
  State<WeldingRealTimeConfigurationPanel> createState() => _WeldingRealTimeConfigurationPanelState();
}

class _WeldingRealTimeConfigurationPanelState extends State<WeldingRealTimeConfigurationPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('焊接实时配置'),),
      body: Text('data'),
    );
  }
}
