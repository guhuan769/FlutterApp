import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:scan_system/Utils/common_toast.dart';
import 'package:scan_system/model/image_model.dart';
import 'package:scan_system/sqflite/img_table.dart';

class ImageViewer extends StatefulWidget {
  final List<ImageModel>? imageUrls;
  final void  Function(int currentIndex) parentMethod;
  // final VoidCallback parentMethod;
  const ImageViewer({Key? key, required this.imageUrls,required this.parentMethod}):super(key:key);

  @override
  // ignore: library_private_types_in_public_api
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  int currentIndex = 0;
  ImgTable imgTable = new ImgTable();

  void _onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // int currentIndex = 0;
    return Scaffold(
      appBar: AppBar(
        title: Text('图片 ${currentIndex + 1} / ${widget.imageUrls!.length}'),
      ),
      body: Stack(children: <Widget>[
        PhotoViewGallery.builder(
          itemCount: widget.imageUrls!.length,
          builder: (context, index) {
            // setState(() {
            //   currentIndex = index+1;
            // });
            return PhotoViewGalleryPageOptions(
              imageProvider: FileImage(File(widget.imageUrls![index].path!)),
              //NetworkImage(imageUrls[index]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            );
          },
          scrollPhysics: const BouncingScrollPhysics(),
          backgroundDecoration: const BoxDecoration(
            color: Colors.black,
          ),
          pageController: PageController(initialPage: currentIndex),
          onPageChanged: _onPageChanged,
        ),
        IconButton(
          onPressed:(){
            widget.parentMethod(currentIndex);
          },

          // () {
          //   CommonToast.deleteImgMsg(context).then((bool? flag) {
          //     if (flag == true) {
          //       ImageModel img = widget.imageUrls[currentIndex];
          //       Future<bool> flag = CommonToast.deleteFile(img.path!);
          //
          //       imgTable.initDB();
          //       List<int> ids = [];
          //       ids.add(img.id!);
          //       imgTable.delete(ids);
          //     }
          //   });
          // }
          icon: const Icon(Icons.delete),
          color: Colors.green,
        )
      ]),
    );
  }
}
