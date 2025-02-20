// lib/screens/preview_screen.dart
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:io';

class PreviewScreen extends StatelessWidget {
  final String imagePath;

  const PreviewScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('预览'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              final result = await ImageGallerySaver.saveFile(imagePath);
              if (result['isSuccess']) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已保存到相册')),
                  );
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Image.file(File(imagePath)),
      ),
    );
  }
}