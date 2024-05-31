import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:scan_system/new_custom_image_view.dart';


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

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {

  static String parentFolderStr = ""; // 用户配置信息
  static String photoPath = "";
  List<String> myImageUrls = [
    // "https://example.com/image1.jpg",
    // "https://example.com/image2.jpg",
    "/data/data/com.gh.scan_system/cache/d6e50850-9374-4e46-804a-fdeb20234c86280595669258453339.jpg"
    // Add more image URLs as needed
  ];

  void _addImageUrl(String url) {
    setState(() {
      myImageUrls.add(url);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
              width: 300,
              height: 300,
              margin: const EdgeInsets.all(5.0), //容器外补白
              color: Colors.orange,
              child:NewCustomImageView(),
          ),
          ElevatedButton(onPressed: () async {
            final ImagePicker _picker = ImagePicker();
            // 使用相机拍摄新照片
            final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
            if (photo != null) {
              File file = File(photo.path);
              final parentFolder = p.dirname(photo.path);
              photoPath = photo.path;
              parentFolderStr = parentFolder;
              _addImageUrl(photo.path);
              // Image.file(File(_image!.path))
              // print('Deleted: ${file.path}');
              deleteEmptyFiles(parentFolder);
            }
            print('parentFolderStr =========== '+parentFolderStr);
            if(parentFolderStr!= null){
              deleteEmptyFiles(parentFolderStr);
            }
          }, child: const Text("拍照"))
        ],
      ),
    );
  }
}
