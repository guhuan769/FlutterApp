import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:scan_system/ImageViewer.dart';
import 'package:scan_system/new_custom_image_view.dart';


void deleteEmptyFiles(String dirPath) {
  final dir = Directory(dirPath);
  final files = dir.listSync();

  for (final file in files) {
    if (file is File && file.lengthSync() == 0) {
      file.deleteSync();
      print('Deleted: $file.path');
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
    // "/data/user/0/com.gh.scan_system/cache/c8d72542-36ef-47f3-81f7-3574be95fbf78792345749131903434.jpg"
    // "/data/user/0/com.gh.scan_system/cache/c958623f-1583-4925-b12a-8e2e6966afaf3741194146653516068.jpg"
    // "/data/user/0/com.gh.scan_system/cache/8fa45d10-74e0-4f0b-9be5-b4b7d2612a4e2055886479379055685.jpg"
    // Add more image URLs as needed
  ];

  void _addImageUrl(String url) {
    setState(() {
      myImageUrls.add(url);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.all(Radius.circular(30)), // 设置四周圆角为30
            ),
            height: 400,
            margin: const EdgeInsets.all(5.0), //容器外补白

            child: myImageUrls.isEmpty ? const Center(child: Text('无照片',style:TextStyle(color: Colors.white) ,)) : ImageViewer(imageUrls: myImageUrls), //const NewCustomImageView(),
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
            deleteEmptyFiles(parentFolder);
          }
          print('parentFolderStr =========== $parentFolderStr');
          if(parentFolderStr!= null){
            deleteEmptyFiles(parentFolderStr);
          }
        }, child: const Text("拍照"))
      ],
    );
  }
}
