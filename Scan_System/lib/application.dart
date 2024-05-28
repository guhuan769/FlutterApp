import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

void deleteEmptyFiles(String dirPath) {
  final dir = Directory(dirPath);
  final files = dir.listSync();

  for (final file in files) {
    if (file is File && file.lengthSync() == 0) {
      file.deleteSync();
      print('Deleted: ${file.path}');
    }
  }
}

class Application extends StatelessWidget {

  static String parentFolderStr = ""; // 用户配置信息

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Flutter App',
      home: Scaffold(
        appBar: AppBar(
          title: Text('扫描APP'),
        ),
        body:  Column(
            children: [
              Container(
                margin: EdgeInsets.all(20.0), //容器外补白
                color: Colors.orange,
                child: Text("1234561111!"),
              ),
              ElevatedButton(onPressed: () async {
                final ImagePicker _picker = ImagePicker();
                  // 使用相机拍摄新照片
                  final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
                  if (photo != null) {
                    File file = File(photo.path);
                    final parentFolder = p.dirname(photo.path);
                    parentFolderStr = parentFolder;
                    // print('Deleted: ${file.path}');
                    deleteEmptyFiles(parentFolder);
                  }
                  print('parentFolderStr =========== '+parentFolderStr);
                  if(parentFolderStr!= null){
                    deleteEmptyFiles(parentFolderStr);
                  }

              }, child: Text("拍照"))
            ],
        ),
      ),
    );
  }




}

