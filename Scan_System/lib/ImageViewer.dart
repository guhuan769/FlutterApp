import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImageViewer extends StatefulWidget {
  final List<String> imageUrls;

  // ImageViewer({required this.imageUrls});
  const ImageViewer({super.key, required this.imageUrls});
  @override
  // ignore: library_private_types_in_public_api
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  int currentIndex = 0;

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
        title: Text('图片 ${currentIndex + 1} / ${widget.imageUrls.length}'),
      ),
      body: Stack(
        children:<Widget>[
          // ElevatedButton(onPressed: () async {
          //
          // },
          //   child: const Text('删除当前照片'),
          // ),
          PhotoViewGallery.builder(
          itemCount: widget.imageUrls.length,
          builder: (context, index) {
            // setState(() {
            //   currentIndex = index+1;
            // });
            return PhotoViewGalleryPageOptions(
              imageProvider: FileImage(File(widget.imageUrls[index])),//NetworkImage(imageUrls[index]),
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
        ]
      ),
    );
  }
}


