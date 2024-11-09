import 'dart:io';
import 'package:vehicle_control_system/data/models/protocol_packet.dart';// 引入上面的协议类

class TcpClient {
  final String ip;
  final int port;

  TcpClient({required this.ip, required this.port});

  // 发送协议包
  Future<void> sendData(ProtocolPacket packet) async {
    try {
      // 连接到服务器
      final socket = await Socket.connect(ip, port, timeout: Duration(seconds: 5));
      print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');

      // 构造协议包并发送
      String data = packet.toProtocolString();
      socket.write(data);
      print('Data sent: $data');

      socket.close();  // 关闭连接
    } catch (e) {
      print('Error connecting to the socket: $e');
      rethrow; // 将错误抛出，方便主界面处理
    }
  }
}