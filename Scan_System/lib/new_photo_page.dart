import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:scan_system/Utils/common_toast.dart';
import 'package:scan_system/model/img_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewPhotoPage extends StatefulWidget {
  const NewPhotoPage({super.key});

  @override
  State<NewPhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<NewPhotoPage> {
  MobileScannerController controller = MobileScannerController();
  bool isQRCodeDetected = false;

  @override
  void initState() {
    super.initState();
    // 初始化状态
    isQRCodeDetected = false;
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
                  border: Border.all(color: Colors.red, width: 8),
                ),
              ),
            ),
          // 其他UI元素...
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isQRCodeDetected ? Colors.green : Colors.white10,
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

// Future<bool?> _showHint() {
//   return showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('提示'),
//           content: const Text('您确定要退出当前页面吗?'),
//           actions: [
//             ElevatedButton(
//               onPressed: () async {
//                 Navigator.of(context).pop(true);
//               },
//               child: const Text('确定'),
//             ),
//             ElevatedButton(
//                 onPressed: () async {
//                   Navigator.of(context).pop(false);
//                 },
//                 child: const Text('取消'))
//           ],
//         );
//       });
// }
}
