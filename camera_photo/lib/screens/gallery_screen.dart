// lib/screens/gallery_screen.dart
import 'package:camera_photo/screens/photo_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';

// lib/screens/gallery_screen.dart
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<PhotoProvider>(context, listen: false).loadPhotos());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PhotoProvider>(
      builder: (context, provider, _) => Scaffold(
        appBar: AppBar(
          leading: provider.isSelectMode
              ? IconButton(
            icon: const Icon(Icons.close),
            onPressed: provider.toggleSelectMode,
            tooltip: '退出选择',
          )
              : IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            tooltip: '返回相机',
          ),
          title: Text(provider.isSelectMode
              ? '已选择 ${provider.selectedPhotos.length} 项'
              : '相册'),
          actions: [
            // 非选择模式下显示选择按钮
            if (!provider.isSelectMode)
              IconButton(
                icon: const Icon(Icons.check_box_outlined),
                onPressed: provider.toggleSelectMode,
                tooltip: '进入选择模式',
              ),

            if (provider.isSelectMode) ...[
              // 全选按钮
              IconButton(
                icon: const Icon(Icons.select_all),
                onPressed: provider.photos.length == provider.selectedPhotos.length
                    ? provider.clearSelection
                    : provider.selectAll,
                tooltip: provider.photos.length == provider.selectedPhotos.length
                    ? '取消全选'
                    : '全选',
              ),
              // 上传按钮
              IconButton(
                icon: const Icon(Icons.upload),
                onPressed: provider.selectedPhotos.isEmpty ? null : provider.uploadSelectedPhotos,
                tooltip: '上传选中照片',
              ),
              // 删除按钮
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: provider.selectedPhotos.isEmpty ? null : () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('确认删除'),
                      content: Text('确定要删除选中的 ${provider.selectedPhotos.length} 张照片吗？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('删除'),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ],
                    ),
                  );
                  if (result == true) {
                    provider.deleteSelectedPhotos();
                  }
                },
                tooltip: '删除选中照片',
              ),
            ],
          ],
        ),
        body: Stack(
          children: [
            if (provider.photos.isEmpty)
              const Center(child: Text('暂无照片'))
            else
              GridView.builder(
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
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          photo,
                          fit: BoxFit.cover,
                        ),
                        if (provider.isSelectMode)
                          Positioned(
                            top: 4,
                            right: 4,
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
                },
              ),
            // 上传进度指示器
            if (provider.isUploading)
              Container(
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
              ),
          ],
        ),
      ),
    );
  }
}