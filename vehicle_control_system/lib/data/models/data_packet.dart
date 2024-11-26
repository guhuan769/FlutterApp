import 'dart:io';
import 'dart:convert';

class DataPacket {
  final String current;
  final double currentValue;
  final String voltage;
  final double voltageValue;

  DataPacket({
    required this.current,
    required this.currentValue,
    required this.voltage,
    required this.voltageValue,
  });

  // 构造协议字符串
  String toProtocolString() {
    final Map<String, dynamic> data = {
      'current': current,
      'currentValue': currentValue,
      'voltage': voltage,
      'voltageValue': voltageValue,
    };
    return json.encode(data);
  }
}
