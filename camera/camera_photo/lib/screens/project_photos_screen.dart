// lib/screens/project_photos_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';
import '../utils/photo_utils.dart';
import 'photo_view_screen.dart';

class ProjectPhotosScreen extends StatefulWidget {
  final String path;
  final String title;

  const ProjectPhotosScreen({
    Key? key,
    required this.path,
    required this.title,
  }) : super(key: key);

  @override
  State<ProjectPhotosScreen> createState() => _ProjectPhotosScreenState();
}

class _ProjectPhotosScreenState extends State<ProjectPhotosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<PhotoProvider>(context, listen: false)
            .loadPhotosForProjectOrTrack(widget.path));
  }

  String _getPhotoInfo(File photo) {
    final fileName = photo.path.split('/').last;
    final photoType = PhotoUtils.getPhotoType(photo.path);
    final sequence = PhotoUtils.getPhotoSequence(photo.path);
    return '$photoType\n序号: $sequence\n$fileName';
  }

  Widget _buildPhotoItem(BuildContext context, File photo, bool isSelected, int index, PhotoProvider provider) {
    final photoType = PhotoUtils.getPhotoType(photo.path);
    final sequence = PhotoUtils.getPhotoSequence(photo.path);

    return Card(
      elevation: 2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () {
              if (provider.isSelectMode) {
                provider.togglePhotoSelection(photo);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PhotoViewScreen(
                      photos: provider.photos,
                      initialIndex: index,
                    ),
                  ),
                );
              }
            },
            onLongPress: () {
              if (!provider.isSelectMode) {
                provider.toggleSelectMode();
                provider.togglePhotoSelection(photo);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Image.file(
                    photo,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  color: Colors.black.withOpacity(0.7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photoType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '序号: $sequence',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (provider.isSelectMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    isSelected ? Icons.check : Icons.circle_outlined,
                    size: 20,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PhotoProvider>(
      builder: (context, provider, _) => Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title),
              if (provider.photos.isNotEmpty)
                Text(
                  '${provider.photos.length} 张照片',
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
          leading: provider.isSelectMode
              ? IconButton(
            icon: const Icon(Icons.close),
            onPressed: provider.toggleSelectMode,
          )
              : IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (!provider.isSelectMode)
              IconButton(
                icon: const Icon(Icons.check_box_outlined),
                onPressed: provider.toggleSelectMode,
              ),
            if (provider.isSelectMode) ...[
              IconButton(
                icon: const Icon(Icons.select_all),
                onPressed: provider.photos.length == provider.selectedPhotos.length
                    ? provider.clearSelection
                    : provider.selectAll,
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: provider.selectedPhotos.isEmpty
                    ? null
                    : () => _showDeleteConfirmation(context, provider),
              ),
            ],
          ],
        ),
        body: provider.photos.isEmpty
            ? const Center(child: Text('暂无照片'))
            : GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.75,
          ),
          itemCount: provider.photos.length,
          itemBuilder: (context, index) {
            final photo = provider.photos[index];
            final isSelected = provider.selectedPhotos.contains(photo);
            return _buildPhotoItem(
              context,
              photo,
              isSelected,
              index,
              provider,
            );
          },
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context,
      PhotoProvider provider,
      ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
          '确定要删除选中的 ${provider.selectedPhotos.length} 张照片吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await provider.deleteSelectedPhotos();
      await provider.loadPhotosForProjectOrTrack(widget.path);
    }
  }
}