import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '二维码检测与图片管理',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: QRScannerPage(),
    );
  }
}

// 二维码扫描页面的状态组件
class QRScannerPage extends StatefulWidget {
  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

// 二维码扫描页面的状态
class _QRScannerPageState extends State<QRScannerPage> {
  final ImagePicker _picker = ImagePicker(); // 图片选择器
  MobileScannerController cameraController = MobileScannerController(); // 摄像头控制器
  bool isQRCodeDetected = false; // 是否检测到二维码的标志

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('拍照并检测二维码'),
      ),
      body: Stack(
        children: [
          // 显示摄像头预览
          MobileScanner(
            controller: cameraController,
            onDetect: (barcode) {
              if (barcode != null) {
                // 如果检测到二维码，设置标志为true
                setState(() {
                  isQRCodeDetected = true;
                });
              } else {
                // 如果没有检测到二维码，设置标志为false
                setState(() {
                  isQRCodeDetected = false;
                });
              }
            },
          ),
          // 如果检测到二维码，显示一个框
          if (isQRCodeDetected)
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.green,
                    width: 3,
                  ),
                ),
              ),
            ),
        ],
      ),
      // 悬浮的拍照按钮
      floatingActionButton: FloatingActionButton(
        onPressed: isQRCodeDetected ? () async {
          // 如果检测到二维码，允许拍照
          final XFile? photo = await _picker.pickImage(
              source: ImageSource.camera);
          if (photo != null) {
            // 如果拍照成功，显示保存或取消对话框
            // _showSaveOrCancelDialog(context, photo);
          }
        } : null,
        // 根据是否检测到二维码来设置按钮颜色
        backgroundColor: isQRCodeDetected ? Colors.blue : Colors.grey,
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}