
// lib/screens/gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';

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
                  onPressed: () => provider.uploadSelectedPhotos(),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => provider.deleteSelectedPhotos(),
                ),
              ],
            )
                : const SizedBox(),
          ),
        ],
      ),
      body: Consumer<PhotoProvider>(
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
              onTap: () => provider.togglePhotoSelection(photo),
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
    );
  }
}
