// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
//
// import 'package:vehicle_control_system/data/models/protocol_packet.dart';
//
// class TcpServer {
//   late ServerSocket _serverSocket;
//   final List<Socket> _clientSockets = [];
//
//   Future<void> startServer({required String address, required int port}) async {
//     try {
//       // 启动 TCP 服务端，监听指定地址和端口
//       _serverSocket = await ServerSocket.bind(address, port);
//       print('TCP 服务端已启动，监听 $address:$port');
//
//       // 监听客户端连接
//       _serverSocket.listen((clientSocket) {
//         print('客户端连接: ${clientSocket.remoteAddress.address}:${clientSocket.remotePort}');
//         _clientSockets.add(clientSocket);
//
//         // 启动接收数据
//         _receiveData(clientSocket);
//       });
//     } catch (e) {
//       print('启动 TCP 服务时发生错误: $e');
//     }
//   }
//
//   Future<void> _receiveData(Socket clientSocket) async {
//     clientSocket.listen(
//           (List<int> data) async {
//         try {
//           // 将接收到的数据转换为字符串
//           String dataString = utf8.decode(data);
//           print('接收到数据: $dataString');
//
//           // 解析数据为 ProtocolPacket 实体
//           ProtocolPacket packet = ProtocolPacket.fromProtocolString(dataString);
//           print('解析后的数据: $packet');
//
//           // 处理完数据后返回给客户端响应
//           String response = '数据已接收并解析: ${packet.toProtocolString()}';
//           clientSocket.add(utf8.encode(response));
//         } catch (e) {
//           print('数据处理错误: $e');
//           clientSocket.add(utf8.encode('数据处理错误: $e'));
//         }
//       },
//       onError: (e) {
//         print('接收数据时发生错误: $e');
//         clientSocket.close();
//       },
//       onDone: () {
//         print('客户端连接关闭');
//         clientSocket.close();
//         _clientSockets.remove(clientSocket);
//       },
//     );
//   }
//
//   Future<void> stopServer() async {
//     await Future.wait(_clientSockets.map((socket) async {
//       await socket.close();
//     }));
//     await _serverSocket.close();
//     print('TCP 服务端已停止');
//   }
// }
//



import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:vehicle_control_system/data/models/protocol_packet.dart';

class TcpServer {
  late ServerSocket _serverSocket;
  final List<Socket> _clientSockets = [];

  // 创建一个 StreamController，用于向 UI 传递数据
  final StreamController<String> _dataStreamController = StreamController<String>.broadcast();

  // 获取数据流
  Stream<String> get dataStream => _dataStreamController.stream;

  Future<void> startServer({required String address, required int port}) async {
    try {
      // 启动 TCP 服务端，监听指定地址和端口
      _serverSocket = await ServerSocket.bind(address, port);
      print('TCP 服务端已启动，监听 $address:$port');

      // 监听客户端连接
      _serverSocket.listen((clientSocket) {
        print('客户端连接: ${clientSocket.remoteAddress.address}:${clientSocket.remotePort}');
        _clientSockets.add(clientSocket);

        // 启动接收数据
        _receiveData(clientSocket);
      });
    } catch (e) {
      print('启动 TCP 服务时发生错误: $e');
    }
  }

  Future<void> _receiveData(Socket clientSocket) async {
    clientSocket.listen(
          (List<int> data) async {
        try {
          // 将接收到的数据转换为字符串
          String dataString = utf8.decode(data);
          print('接收到数据: $dataString');

          // 解析数据为 ProtocolPacket 实体
          ProtocolPacket packet = ProtocolPacket.fromProtocolString(dataString);
          print('解析后的数据: $packet');

          // 将数据推送到数据流
          // _dataStreamController.add('接收到数据: $dataString\n解析后的数据: $packet');
          _dataStreamController.add('$dataString');

          // 处理完数据后返回给客户端响应
          String response = '数据已接收并解析: ${packet.toProtocolString()}';
          clientSocket.add(utf8.encode(response));
        } catch (e) {
          print('数据处理错误: $e');
          clientSocket.add(utf8.encode('数据处理错误: $e'));
        }
      },
      onError: (e) {
        print('接收数据时发生错误: $e');
        clientSocket.close();
      },
      onDone: () {
        print('客户端连接关闭');
        clientSocket.close();
        _clientSockets.remove(clientSocket);
      },
    );
  }

  Future<void> stopServer() async {
    await Future.wait(_clientSockets.map((socket) async {
      await socket.close();
    }));
    await _serverSocket.close();
    print('TCP 服务端已停止');

    // 关闭 StreamController
    await _dataStreamController.close();
  }
}
