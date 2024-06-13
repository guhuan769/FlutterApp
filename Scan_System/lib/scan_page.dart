import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:scan_system/ImageViewer.dart';
import 'package:scan_system/Utils/common_toast.dart';
import 'package:scan_system/model/image_model.dart';

// import 'package:scan_system/Utils/common_toast.dart';
import 'package:scan_system/new_custom_image_view.dart';
import 'package:scan_system/photo_page.dart';
import 'package:scan_system/sqflite/DBHelper.dart';
import 'package:scan_system/sqflite/img_table.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/Person.dart';
import 'new_photo_page.dart';

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
  ImgTable imgTable = new ImgTable();

  static String parentFolderStr = ""; // 用户配置信息
  static String photoPath = "";
  List<ImageModel> myImageUrls = [
    // "/data/user/0/com.gh.scan_system/cache/c8d72542-36ef-47f3-81f7-3574be95fbf78792345749131903434.jpg"
    // "/data/user/0/com.gh.scan_system/cache/c958623f-1583-4925-b12a-8e2e6966afaf3741194146653516068.jpg"
    // "/data/user/0/com.gh.scan_system/cache/8fa45d10-74e0-4f0b-9be5-b4b7d2612a4e2055886479379055685.jpg"
    // Add more image URLs as needed
  ];

  // void _addImageUrl(String url) {
  //   setState(() {
  //     myImageUrls.add(url);
  //   });
  // }

  @override
  void initState() {
    super.initState();
    DBHelper.initDB();
// 将JSON数组转换为List<Person>

    // imgTable.initDB();
    // imgTable.queryData().then((data) async {
    //   String aa = json.encode(data);
    //   setState(() {
    //     List<ImageModel> imageModel =
    //         data.map((json) => ImageModel.fromJson(json)).toList();
    //     myImageUrls = imageModel;
    //   });
    // });
    Refresh();

    // imgTable.dataList;
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
    return PopScope(
      canPop: false, // 当false时，阻止当前路由被弹出。
      onPopInvoked: (didPop) async {
        Future<bool?> flag = CommonToast.showHint(context);
      },
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius:
                    BorderRadius.all(Radius.circular(30)), // 设置四周圆角为30
              ),
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.all(5.0),
              //容器外补白
              child: (myImageUrls.isEmpty)
                  ? const Center(
                      child: Text(
                      '无照片',
                      style: TextStyle(
                          color: Colors.white, fontSize: 40, fontFamily: '黑体'),
                    ))
                  : ImageViewer(
                      imageUrls: myImageUrls,
                      parentMethod: parentMethod), //const NewCustomImageView(),
            ),
            Positioned(
              bottom: 10,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    IconButton(
                      onPressed: () async {
                        // TODO:导航到拍照界面
                        // 动态路由
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                                    settings: const RouteSettings(
                                        arguments: {"id": 10, "name": "_我爱你"}),
                                    builder: (context) =>
                                        const NewPhotoPage()) //const PhotoPage()
                                )
                            .then((result) async {
                          // SharedPreferences pref =
                          //     await SharedPreferences.getInstance();
                          // if (pref != null) {
                          //   debugPrint("${pref.getBool("isSelect")}");
                          // }
                          // _addImageUrl('');
                          // CommonToast.showToast('回调函数');
                          Refresh();

                          // 重新查询
                        });
                      },
                      icon: const Icon(Icons.camera_alt_sharp),
                      color: Colors.green,
                    ),
                    IconButton(
                      onPressed: () async {
                        CommonToast.deleteImgMsgAll(context)
                            .then((bool? flag) async {
                          if (flag == true) {

                            await DBHelper.deleteAll("img");

                            for (ImageModel item in myImageUrls) {
                              CommonToast.deleteFolder(item.path!);
                            }

                            setState(() {
                              myImageUrls!.clear();
                            });

                          }
                        });
                      },
                      icon: const Icon(Icons.delete_forever_outlined),
                      color: Colors.green,
                    ),
                    IconButton(
                      onPressed: () async {
                        CommonToast.showToast('未开发');
                      },
                      icon: const Icon(Icons.send),
                      color: Colors.green,
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
      ),
    );
  }

  void parentMethod(int currentIndex) async {
    // 父组件的方法
    // CommonToast.showToast('${currentIndex}');
    CommonToast.deleteImgMsg(context).then((bool? flag) async {
      if (flag == true) {
        ImageModel img = myImageUrls![currentIndex];

        await DBHelper.delete('img', img.id!);
        Future<bool> flag = CommonToast.deleteFile(img.path!);
        Refresh();

        // imgTable.initDB();
        // //imgTable.OpenDB();
        // // List<int> ids = [];
        // // ids.add(img.id!);
        // imgTable.delete(img.id!);
        // // imgTable.closeDB();
      }
    });
  }

  Future<void> Refresh() async {
    await DBHelper.queryAll("img").then((data) {
      setState(() {
        List<ImageModel>? imageModel;
        if (data != null) {
          imageModel = data.map((json) => ImageModel.fromJson(json)).toList();
          myImageUrls = imageModel;
        }
      });
    });

    // imgTable.initDB();
    // imgTable.queryData().then((data) async {
    //   String aa = json.encode(data);
    //   setState(() {
    //     List<ImageModel>? imageModel;
    //     if (data != null) {
    //       imageModel = data.map((json) => ImageModel.fromJson(json)).toList();
    //       myImageUrls = imageModel;
    //     }
    //   });
    // });
  }
}
