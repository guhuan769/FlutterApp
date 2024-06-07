import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:scan_system/model/img_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoPage extends StatefulWidget {

  const PhotoPage({super.key});

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  Barcode? result;
  bool isQRCodeDetected = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    setState(() {
      isQRCodeDetected = false;
    });

  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    // 假设您有一个动态路由，并且在路由参数中传递了一个Map
    var routeSettings = ModalRoute.of(context)?.settings;
    Map<dynamic, dynamic> arguments;
    if (routeSettings?.arguments != null) {
      // 使用as关键字将Object?转换为Map<dynamic, dynamic>
      arguments = routeSettings?.arguments as Map<dynamic, dynamic>;
      // 现在您可以安全地使用这个Map
      debugPrint('debugPrint ---  ${arguments['id']}');
    }

    return Scaffold(
      body: Stack(
        children: <Widget>[
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.red,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 300,
            ),
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

          Positioned(
            bottom: 10,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed:isQRCodeDetected ? _captureImage : isQRCodeDetected==false? null:null,
                    child: const Text('进入相机拍照',style:TextStyle(color: Colors.green)),
                  ),
                  ElevatedButton(onPressed: (){
                    Navigator.of(context).pop('OK');
                  }, child: const Text('返回主页'))
                  // InkWell(
                  //     onTap: (){
                  //       Navigator.of(context).pop();
                  //     },
                  //     child:
                  // ),
                ],
              ),
            ),
          )
        ],
      ),
    );

    //   Scaffold(body:
    //   Center(
    //       child: InkWell(
    //          onTap: (){
    //             Navigator.of(context).pop();
    //          },
    //           child: const Text('返回主页')
    //       ),
    //   )
    // );
  }


  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        isQRCodeDetected = result != null;
      });
    });
  }

  void _captureImage() async {

    // setState(() {
    //   isQRCodeDetected = false;
    //   return;
    // });

    final ImagePicker _picker = ImagePicker();
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      // TODO: 进行拍照后的处理，比如显示确认保存取消界面

      testSqflite();

      // SharedPreferences pref = await SharedPreferences.getInstance();
      // pref.setBool("isSelect", false);
      // pref.setString("imgPath", photo.path);
    }

    setState(() {
      isQRCodeDetected = false;
    });
  }

  void _initQRCFlase() async {
    setState(() {
      isQRCodeDetected = false;
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

}


