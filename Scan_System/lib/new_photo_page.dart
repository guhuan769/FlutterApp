import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:scan_system/Utils/common_toast.dart';
import 'package:scan_system/model/img_model.dart';
import 'package:scan_system/scan_page.dart';
import 'package:scan_system/sqflite/DBHelper.dart';
import 'package:scan_system/sqflite/DBUtil.dart';
import 'package:scan_system/sqflite/img_table.dart';

import 'model/image_model.dart';


class NewPhotoPage extends StatefulWidget {
  const NewPhotoPage({super.key});

  @override
  State<NewPhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<NewPhotoPage> {
  MobileScannerController controller = MobileScannerController();
  bool isQRCodeDetected = false;

  // var dataList = "";
  // late Dbutil dbUtil;
  // ImgTable imgTable = new ImgTable();

  @override
  void initState() {
    super.initState();
    // 初始化状态
    isQRCodeDetected = false;
    // imgTable.initDB();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          MobileScanner(
            controller: controller,
            onScannerStarted: (arguments) {
              CommonToast.showToast('onScannerStarted');
            },
            onDetect: (barcode) {
              CommonToast.showToast('onDetect');
              // if (barcode.rawValue == null) {
              //判断是否存在二维码
              if (barcode.barcodes[0].rawValue == null) {
                debugPrint('Failed to scan Barcode');
              } else {
                // if(barcode != null){
                //   final String code = barcode.rawValue!;
                // }
                //
                // debugPrint('Barcode found! $code');
                // 在这里处理扫描结果
                setState(() {
                  isQRCodeDetected = true;
                });
              }
            },
          ),
          if (isQRCodeDetected)
            Center(
              child: Container(
                // 绘制二维码边框
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 8),
                ),
              ),
            ),
          if (!isQRCodeDetected)
            Center(
              child: Container(
                // 绘制二维码边框
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  // border: Border.all(color: Colors.green, width: 8),
                  border: Border.all(color: Colors.red, width: 8),
                ),
              ),
            ),
          // 其他UI元素...
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isQRCodeDetected ? Colors.green : Colors.white10,
        // onPressed: _captureImage, //
        onPressed: isQRCodeDetected ? _captureImage : _captureMessage, //
        child: const Icon(Icons.camera_alt_sharp),
      ),
    );
  }

  void _captureMessage() async {
    if (!isQRCodeDetected) {
      CommonToast.showToast('未检测到二维码');
    }
  }

  void _captureImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      // 进行拍照后的处理
      // ...
      // imgTable.insertData(photo.path);
      ImageModel img = ImageModel();
      img.imgName = 'img';
      img.isSelect = false;
      img.path = photo.path;
      bool flag = await DBHelper.insert('img',img.toMap());
    }
    // 重置二维码检测状态
    setState(() {
      isQRCodeDetected = false;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }


}
