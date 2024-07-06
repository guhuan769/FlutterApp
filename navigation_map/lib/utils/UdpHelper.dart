import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:navigation_map/Utils/common_toast.dart';

import '../CustomUserControls/custom_dialog.dart';
import '../base/constants.dart';

class UdpHelper {
  final UdpCallback callback;
  final ErrorCallback errorCallback;
  RawDatagramSocket? _socket;

  UdpHelper(this.callback,this.errorCallback);

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
    }, onError: (e, s) {
      // var aa = e is SocketException;
      // var bb =aa.toString();
      dynamic errorCode = e.osError.errorCode;
      dynamic errorMessage = "远程端口未监听,请开启目标设备";
      errorCallback(errorCode,errorMessage);
      // print('123');
      // CommonToast.showToast('远程端口未监听,请开启目标设备.');
      // if (errorCode == "1234") {
      //   CommonToast.showToast('远程端口未监听,请开启目标设备.');
      // }
      return;
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
