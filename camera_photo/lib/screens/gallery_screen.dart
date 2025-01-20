// lib/screens/gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';
import 'ImagePreviewScreen.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        actions: [
          Consumer<PhotoProvider>(
            builder: (context, provider, _) => provider.selectedPhotos.isNotEmpty
                ? Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.upload),
                  onPressed: provider.isUploading
                      ? null
                      : () => provider.uploadSelectedPhotos(),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: provider.isUploading
                      ? null
                      : () => provider.deleteSelectedPhotos(),
                ),
              ],
            )
                : const SizedBox(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Consumer<PhotoProvider>(
            builder: (context, provider, _) => GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: provider.photos.length,
              itemBuilder: (context, index) {
                final photo = provider.photos[index];
                final isSelected = provider.selectedPhotos.contains(photo);
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImagePreviewScreen(
                          imageFile: photo,
                          photos: provider.photos,
                          currentIndex: index,
                        ),
                      ),
                    );
                  },
                  onLongPress: () => provider.togglePhotoSelection(photo),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        photo,
                        fit: BoxFit.cover,
                      ),
                      if (isSelected)
                        Container(
                          color: Colors.blue.withOpacity(0.3),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          // 上传进度指示器
          Consumer<PhotoProvider>(
            builder: (context, provider, _) {
              if (!provider.isUploading) return const SizedBox();

              return Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            value: provider.uploadProgress,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.uploadStatus,
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            '${(provider.uploadProgress * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}