import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:scan_system/ImageViewer.dart';
import 'package:scan_system/Utils/common_toast.dart';
// import 'package:scan_system/Utils/common_toast.dart';
import 'package:scan_system/new_custom_image_view.dart';
import 'package:scan_system/photo_page.dart';
import 'package:shared_preferences/shared_preferences.dart';


///清除0KB图片
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

///清除所有图片
void deleteFiles(String dirPath) {
  final dir = Directory(dirPath);
  final files = dir.listSync();

  for (final file in files) {
      file.deleteSync();
      print('Deleted: $file.path');
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
  void initState() {
    // TODO: implement initState
    super.initState();

    // setState(() {
    //   myImageUrls.add('/data/user/0/com.gh.scan_system/cache/cb60d413-b7b2-457e-8a3b-91e4670bb7596665434917045779569.jpg');
    //   myImageUrls.add('/data/data/com.gh.scan_system/cache/5a567018-4da1-4064-a97d-920f6b109d257341716346130330151.jpg');
    //   myImageUrls.add('/data/data/com.gh.scan_system/cache/60d0cbeb-c3f8-4e80-9247-86ce8fcf93462550480970746920720.jpg');
    // });

    // TODO: 删除所有图片
    //deleteFiles()
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children:<Widget>[ Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.all(Radius.circular(30)), // 设置四周圆角为30
            ),
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
            margin: const EdgeInsets.all(5.0), //容器外补白
            child: myImageUrls.isEmpty ? const Center(child: Text('无照片',style:TextStyle(color: Colors.white,fontSize: 40,fontFamily: '黑体') ,)) : ImageViewer(imageUrls: myImageUrls), //const NewCustomImageView(),
        ),
        Positioned(
          bottom: 10,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(onPressed: () async {
                  // TODO:导航到拍照界面
                  // 动态路由
                  Navigator.of(context).push(MaterialPageRoute(
                      settings: const RouteSettings(

                          arguments: {
                            "id":10,
                            "name":"_我爱你"
                          }
                      ),
                      builder: (context)=>  const PhotoPage())
                  ).then((result) async {
                    SharedPreferences pref = await SharedPreferences.getInstance();
                    if(pref != null){
                        debugPrint("${pref.getBool("isSelect")}");
                    }
                    // _addImageUrl('');
                    // CommonToast.showToast('回调函数');
                  });
                },
                  child: const Text('拍照'),
                ),
                ElevatedButton(onPressed: () async {
                  setState(() {
                    myImageUrls.clear();
                  });
                },
                  child: const Text('删除所有照片'),
                ),
                ElevatedButton(onPressed: () async {
                  CommonToast.showToast('未开发');
                },
                  child: const Text('传输至服务端'),
                ),

                //// 该组件用于测试
                // ElevatedButton(onPressed: () async {
                //   final ImagePicker _picker = ImagePicker();
                //   // 使用相机拍摄新照片
                //   final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
                //   if (photo != null) {
                //     File file = File(photo.path);
                //     final parentFolder = p.dirname(photo.path);
                //     photoPath = photo.path;
                //     parentFolderStr = parentFolder;
                //     _addImageUrl(photo.path);
                //     deleteEmptyFiles(parentFolder);
                //   }
                //   // print('parentFolderStr =========== $parentFolderStr');
                //   if(parentFolderStr!= null){
                //     deleteEmptyFiles(parentFolderStr);
                //   }
                // },
                //   child: const Text('Test按钮'),
                // ),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }
}
