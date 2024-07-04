import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../base/constants.dart';

class UdpHelper {
  final UdpCallback callback;
  RawDatagramSocket? _socket;

  UdpHelper(this.callback);

  void startListening() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8456);
    _socket?.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? datagram = _socket?.receive();
        if (datagram != null) {
          String message = String.fromCharCodes(datagram.data);
          callback(message); // 调用回调函数
        }
      }
    });
  }

  void sendMsgDataFrame(Uint8List message, InternetAddress address, int port) {
    _socket?.send(message, address, port);
  }

  void sendMessage(String message, InternetAddress address, int port) {
    _socket?.send(message.codeUnits, address, port);
  }

  void stopListening() {
    _socket?.close();
  }
}
