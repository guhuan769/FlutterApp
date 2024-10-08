import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math';
import '../CustomUserControls/CustomCard.dart';
import '../custom_controls/SpeechToTextWidget.dart';
import '../custom_controls/VoiceControlWidget.dart';

const ballSize = 20.0;
const step = 10.0;

class Testjoystick extends StatefulWidget {
  const Testjoystick({super.key});

  @override
  State<Testjoystick> createState() => _TestjoystickState();
}

class _TestjoystickState extends State<Testjoystick> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Flutter Joystick 示例 页面不能带有滚动条否则 上下左右 手机触控会失灵。'),
      // ),
      // body: Center(
      //   child: Column(
      //     children: [
      //       Joystick(
      //         listener: (details) {
      //           double angle = atan2(details.y, details.x) * (180 / pi);
      //           if (angle < 0) angle += 360; // 将角度转换为0-360度范围
      //           print('操纵杆角度: $angle°');
      //           print('操纵杆移动到: ${details.x}, ${details.y}');
      //
      //           String direction = getDirection(details.x, details.y);
      //           print('操纵杆方向: $direction');
      //         },
      //       ),
      //       Row(
      //         mainAxisAlignment: MainAxisAlignment.center,
      //         children: [
      //           CustomCard(
      //             screenWidth: MediaQuery.of(context).size.width,
      //             title: '相对运行',
      //             icon: FontAwesomeIcons.locationCrosshairs,
      //             child: Column(
      //               children: [
      //                 Center(
      //                   child: Joystick(
      //                     listener: (details) {
      //                       //async
      //                       String direction =
      //                       getDirection(details.x, details.y);
      //                       print('操纵杆方向: $direction');
      //                       // _sendCommand(direction);
      //
      //                       // double angle = atan2(details.y, details.x) * (180 / pi);
      //                       // if (angle < 0) angle += 360; // 将角度转换为0-360度范围
      //                       // print('操纵杆角度: $angle°');
      //                       // print('操纵杆移动到: ${details.x}, ${details.y}');
      //                       //
      //                       //  String direction = getDirection(details.x, details.y);
      //                       //  // print('操纵杆方向: $direction');
      //                       //  if(direction == "前"){
      //                       //    print('前');
      //                       //    final socket =
      //                       //    await Socket.connect(ip, 102);
      //                       //    print(
      //                       //        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
      //                       //    await S7utils.s7Connect(socket);
      //                       //    //此处还有地址没传
      //                       //    await S7utils.s7WriteUp(socket, 0x10, 0x00);
      //                       //    // await S7utils.s7Read(socket);
      //                       //    // 关闭连接
      //                       //    await socket.close();
      //                       //
      //                       //
      //                       //  }
      //                       //  else if(direction == "后")
      //                       //  {
      //                       //    print('后');
      //                       //    final socket =
      //                       //    await Socket.connect(ip, 102);
      //                       //    print(
      //                       //        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
      //                       //    await S7utils.s7Connect(socket);
      //                       //    //此处还有地址没传
      //                       //    await S7utils.s7WriteUp(socket, 0x20, 0x00);
      //                       //    // await S7utils.s7Read(socket);
      //                       //    // 关闭连接
      //                       //    await socket.close();
      //                       //
      //                       //
      //                       //  }
      //                       //  else if(direction == "左")
      //                       //  {
      //                       //    print('左');
      //                       //    final socket =
      //                       //    await Socket.connect(ip, 102);
      //                       //    print(
      //                       //        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
      //                       //    await S7utils.s7Connect(socket);
      //                       //    //此处还有地址没传
      //                       //    await S7utils.s7WriteUp(socket, 0x80, 0x00);
      //                       //    // await S7utils.s7Read(socket);
      //                       //    // 关闭连接
      //                       //    await socket.close();
      //                       //
      //                       //  }
      //                       //  else if(direction == "右")
      //                       //  {print('右');
      //                       //    final socket =
      //                       //    await Socket.connect(ip, 102);
      //                       //    print(
      //                       //        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
      //                       //    await S7utils.s7Connect(socket);
      //                       //    //此处还有地址没传
      //                       //    await S7utils.s7WriteUp(socket, 0x40, 0x00);
      //                       //    // await S7utils.s7Read(socket);
      //                       //    // 关闭连接
      //                       //    await socket.close();
      //                       //
      //                       //  }
      //                       //  else{
      //                       //    print('中心');
      //                       //    final socket =
      //                       //        await Socket.connect(ip, 102);
      //                       //    print(
      //                       //        'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
      //                       //    await S7utils.s7Connect(socket);
      //                       //    //此处还有地址没传
      //                       //    await S7utils.s7WriteUp(socket, 0x00, 0x00);
      //                       //    // await S7utils.s7Read(socket);
      //                       //    // 关闭连接
      //                       //    await socket.close();
      //                       //  }
      //                     },
      //                   ),
      //                 ),
      //                 const SizedBox(height: 20),
      //                 // //前进点动
      //                 // Row(
      //                 //   mainAxisAlignment: MainAxisAlignment.center,
      //                 //   crossAxisAlignment: CrossAxisAlignment.center,
      //                 //   children: [
      //                 //     GestureDetector(
      //                 //       onTapDown: (value) async {
      //                 //           // CommonToast.showToastNew(context, "title", "onTapDown", [
      //                 //           //   Text('data')
      //                 //           // ]);
      //                 //         // CommonToast.showToast('onTapDown');
      //                 //         final socket =
      //                 //             await Socket.connect(ip, 102);
      //                 //         print(
      //                 //             'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
      //                 //         await S7utils.s7Connect(socket);
      //                 //         //此处还有地址没传
      //                 //         await S7utils.s7WriteUp(socket, 0x10, 0x00);
      //                 //         // await S7utils.s7Read(socket);
      //                 //         // 关闭连接
      //                 //         await socket.close();
      //                 //       },
      //                 //       onTapUp: (value) async {
      //                 //         // CommonToast.showToastNew(context, "title", "onTapUp", [
      //                 //         //   Text('data')
      //                 //         // ]);
      //                 //         // CommonToast.showToast('onTapUp');
      //                 //       },
      //                 //       onTapCancel: () async {
      //                 //         // CommonToast.showToast('onTapCancel');
      //                 //         final socket =
      //                 //         await Socket.connect(ip, 102);
      //                 //         print(
      //                 //             'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
      //                 //         await S7utils.s7Connect(socket);
      //                 //         //此处还有地址没传
      //                 //         await S7utils.s7WriteUp(socket, 0x00, 0x00);
      //                 //         // await S7utils.s7Read(socket);
      //                 //         // 关闭连接
      //                 //         await socket.close();
      //                 //       },
      //                 //       child: CustomButton(
      //                 //           text: '前进点动',
      //                 //           icon: Icons.arrow_upward,
      //                 //           height: 50,
      //                 //           width: 200,
      //                 //           onPressed: () async {
      //                 //
      //                 //           }),
      //                 //     ),
      //                 //   ],
      //                 // ),
      //                 // //后退点动
      //                 // Row(
      //                 //   mainAxisAlignment: MainAxisAlignment.center,
      //                 //   crossAxisAlignment: CrossAxisAlignment.center,
      //                 //   children: [
      //                 //     GestureDetector(
      //                 //       onTapDown: (value) async {
      //                 //         // CommonToast.showToastNew(context, "title", "onTapDown", [
      //                 //         //   Text('data')
      //                 //         // ]);
      //                 //         // CommonToast.showToast('onTapDown');
      //                 //         final socket =
      //                 //         await Socket.connect(ip, 102);
      //                 //         print(
      //                 //             'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
      //                 //         await S7utils.s7Connect(socket);
      //                 //         //此处还有地址没传
      //                 //         await S7utils.s7WriteUp(socket, 0x20, 0x00);
      //                 //         // await S7utils.s7Read(socket);
      //                 //         // 关闭连接
      //                 //         await socket.close();
      //                 //       },
      //                 //       onTapUp: (value) async {
      //                 //         // CommonToast.showToastNew(context, "title", "onTapUp", [
      //                 //         //   Text('data')
      //                 //         // ]);
      //                 //         // CommonToast.showToast('onTapUp');
      //                 //       },
      //                 //       onTapCancel: () async {
      //                 //         // CommonToast.showToast('onTapCancel');
      //                 //         final socket =
      //                 //         await Socket.connect(ip, 102);
      //                 //         print(
      //                 //             'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
      //                 //         await S7utils.s7Connect(socket);
      //                 //         //此处还有地址没传
      //                 //         await S7utils.s7WriteUp(socket, 0x00, 0x00);
      //                 //         // await S7utils.s7Read(socket);
      //                 //         // 关闭连接
      //                 //         await socket.close();
      //                 //       },
      //                 //       child: CustomButton(
      //                 //           text: '后退点动',
      //                 //           icon: Icons.arrow_downward,
      //                 //           height: 50,
      //                 //           width: 200,
      //                 //           onPressed: () async {
      //                 //
      //                 //           }),
      //                 //     ),
      //                 //   ],
      //                 // ),
      //                 //
      //                 // //左转弯 未实现
      //                 // Row(
      //                 //   mainAxisAlignment: MainAxisAlignment.center,
      //                 //   crossAxisAlignment: CrossAxisAlignment.center,
      //                 //   children: [
      //                 //     GestureDetector(
      //                 //       onTapDown: (value) async {
      //                 //         // CommonToast.showToastNew(context, "title", "onTapDown", [
      //                 //         //   Text('data')
      //                 //         // ]);
      //                 //         // CommonToast.showToast('onTapDown');
      //                 //         final socket =
      //                 //         await Socket.connect(ip, 102);
      //                 //         print(
      //                 //             'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
      //                 //         await S7utils.s7Connect(socket);
      //                 //         //此处还有地址没传
      //                 //         await S7utils.s7WriteUp(socket, 0x80, 0x00);
      //                 //         // await S7utils.s7Read(socket);
      //                 //         // 关闭连接
      //                 //         await socket.close();
      //                 //       },
      //                 //       onTapUp: (value) async {
      //                 //         // CommonToast.showToastNew(context, "title", "onTapUp", [
      //                 //         //   Text('data')
      //                 //         // ]);
      //                 //         // CommonToast.showToast('onTapUp');
      //                 //       },
      //                 //       onTapCancel: () async {
      //                 //         // CommonToast.showToast('onTapCancel');
      //                 //         final socket =
      //                 //         await Socket.connect(ip, 102);
      //                 //         print(
      //                 //             'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
      //                 //         await S7utils.s7Connect(socket);
      //                 //         //此处还有地址没传
      //                 //         await S7utils.s7WriteUp(socket, 0x00, 0x00);
      //                 //         // await S7utils.s7Read(socket);
      //                 //         // 关闭连接
      //                 //         await socket.close();
      //                 //       },
      //                 //       child: CustomButton(
      //                 //           text: '左转弯',
      //                 //           icon: Icons.arrow_back,
      //                 //           height: 50,
      //                 //           width: 200,
      //                 //           onPressed: () async {
      //                 //
      //                 //           }),
      //                 //     ),
      //                 //   ],
      //                 // ),
      //                 // //右转弯 未实现
      //                 // Row(
      //                 //   mainAxisAlignment: MainAxisAlignment.center,
      //                 //   crossAxisAlignment: CrossAxisAlignment.center,
      //                 //   children: [
      //                 //     GestureDetector(
      //                 //       onTapDown: (value) async {
      //                 //         // CommonToast.showToastNew(context, "title", "onTapDown", [
      //                 //         //   Text('data')
      //                 //         // ]);
      //                 //         // CommonToast.showToast('onTapDown');
      //                 //         final socket =
      //                 //         await Socket.connect(ip, 102);
      //                 //         print(
      //                 //             'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
      //                 //         await S7utils.s7Connect(socket);
      //                 //         //此处还有地址没传
      //                 //         await S7utils.s7WriteUp(socket, 0x40, 0x00);
      //                 //         // await S7utils.s7Read(socket);
      //                 //         // 关闭连接
      //                 //         await socket.close();
      //                 //       },
      //                 //       onTapUp: (value) async {
      //                 //         // CommonToast.showToastNew(context, "title", "onTapUp", [
      //                 //         //   Text('data')
      //                 //         // ]);
      //                 //         // CommonToast.showToast('onTapUp');
      //                 //       },
      //                 //       onTapCancel: () async {
      //                 //         // CommonToast.showToast('onTapCancel');
      //                 //         final socket =
      //                 //         await Socket.connect(ip, 102);
      //                 //         print(
      //                 //             'Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
      //                 //         await S7utils.s7Connect(socket);
      //                 //         //此处还有地址没传
      //                 //         await S7utils.s7WriteUp(socket, 0x00, 0x00);
      //                 //         // await S7utils.s7Read(socket);
      //                 //         // 关闭连接
      //                 //         await socket.close();
      //                 //       },
      //                 //       child: CustomButton(
      //                 //           text: '右转弯',
      //                 //           icon: Icons.arrow_forward,
      //                 //           height: 50,
      //                 //           width: 200,
      //                 //           onPressed: () async {
      //                 //
      //                 //           }),
      //                 //     ),
      //                 //   ],
      //                 // ),
      //               ],
      //             ),
      //           ),
      //         ],
      //       ),
      //     ],
      //   ),
      // ),


      // appBar: AppBar(title: Text('Voice Control Example')),
      // body: const Center(
      //   // child: VoiceControlWidget(),
      //   child: SpeechToTextWidget(),
      // ),



    );
  }

  String getDirection(double x, double y) {
    if (y < -0.5) {
      return '前';
    } else if (y > 0.5) {
      return '后';
    } else if (x < -0.5) {
      return '左';
    } else if (x > 0.5) {
      return '右';
    } else {
      return '中心';
    }
  }
}

