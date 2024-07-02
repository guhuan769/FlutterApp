import 'dart:typed_data';
import 'package:crclib/catalog.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crclib/crclib.dart';
import 'package:crclib/catalog.dart';
import 'package:navigation_map/application.dart';

void main() {
  // 使用Crc16Xz算法计算字符串"123456789"的CRC值
  // Int16 decNumber = 1;
  int aa =11111;
  BigInt decNumber = BigInt.from(0x01);
  Uint8List hexNumber = Uint8List(1);
  hexNumber[0] = 3;

  // BigInt unsignedResult = bigIntNumber.toUnsigned(64);
  final crcValue = Crc16X25().convert(hexNumber);
  // final crcValue = Crc16X25().convert(utf8.encode('10'));
  String hexString = crcValue.toRadixString(16);

  print('CRC Value: $hexString'); // 输出应为0xCBF43926

  // const data = Uint8List.fromList([1, 2, 3, 4, 5]);
  // final crc16 = xmodem.calculate(data);

  //runApp(const MyApp());
  runApp(const Application());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double x = 100;
  double y = 200;
  double X_Position = 0.00;
  double Y_Position = 0.00;

  // Crc32Xz().convert(utf8.encode('123456789')) == 0xCBF43926

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(X_Position.toString()),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onPanStart: (details) {
              Offset position = details.localPosition;
              setState(() {
                X_Position = position.dx;
                Y_Position = position.dy;
              });
            },
            onPanUpdate: (details) {
              Offset position = details.localPosition;
              setState(() {
                X_Position = position.dx;
                Y_Position = position.dy;
              });
            },
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                color: Colors.yellow,
                border: Border.all(
                  color: Colors.black,
                  width: 2,
                ),
              ),
              child: LayoutBuilder(
                builder: (_, constraints) => Container(
                  width: constraints.widthConstraints().maxWidth,
                  height: constraints.heightConstraints().maxHeight,
                  color: Colors.yellow,
                  child: CustomPaint(
                      painter: FaceOutlinePainter(X_Position, Y_Position)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FaceOutlinePainter extends CustomPainter {
  double x_position;
  double y_position;

  FaceOutlinePainter(this.x_position, this.y_position);

  @override
  void paint(Canvas canvas, size) {
    final paint = Paint();
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 4.0;
    paint.color = Colors.indigo;

    canvas.drawLine(
      Offset(x_position, size.height / 2),
      Offset(y_position, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(FaceOutlinePainter oldDelegate) => false;
}
