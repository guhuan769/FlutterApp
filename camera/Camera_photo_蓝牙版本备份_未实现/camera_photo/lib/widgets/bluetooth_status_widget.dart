// lib/widgets/bluetooth_status_widget.dart
import 'package:flutter/material.dart';
import '../providers/bluetooth_provider.dart';

class BluetoothStatusWidget extends StatelessWidget {
  final BtConnectionState connectionState;
  final String? deviceName;
  final VoidCallback onPressed;

  const BluetoothStatusWidget({
    Key? key,
    required this.connectionState,
    this.deviceName,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String statusText;

    switch (connectionState) {
      case BtConnectionState.disconnected:
        icon = Icons.bluetooth_disabled;
        color = Colors.grey;
        statusText = '蓝牙未连接';
        break;
      case BtConnectionState.connecting:
        icon = Icons.bluetooth_searching;
        color = Colors.blue;
        statusText = '正在连接蓝牙...';
        break;
      case BtConnectionState.connected:
        icon = Icons.bluetooth_connected;
        color = Colors.green;
        statusText = '已连接: ${deviceName ?? "未知设备"}';
        break;
      case BtConnectionState.disconnecting:
        icon = Icons.bluetooth_disabled;
        color = Colors.orange;
        statusText = '正在断开连接...';
        break;
      case BtConnectionState.error:
        icon = Icons.error;
        color = Colors.red;
        statusText = '蓝牙连接错误';
        break;
    }

    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}