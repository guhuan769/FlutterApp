import 'package:flutter/material.dart';

void main() {
   runApp(const MyApp());
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
                  child: CustomPaint(painter: FaceOutlinePainter(X_Position,Y_Position)),
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
  void paint(Canvas canvas, Size size) {
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
