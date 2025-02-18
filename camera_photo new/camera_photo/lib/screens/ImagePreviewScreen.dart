// 新增 ImagePreviewScreen
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ImagePreviewScreen extends StatelessWidget {
  final File imageFile;
  final List<File> photos;
  final int currentIndex;

  const ImagePreviewScreen({
    Key? key,
    required this.imageFile,
    required this.photos,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${currentIndex + 1}/${photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        itemCount: photos.length,
        controller: PageController(initialPage: currentIndex),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.0,
            child: Center(
              child: Image.file(
                photos[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}