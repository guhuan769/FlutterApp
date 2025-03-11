// lib/screens/project_photos_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class ProjectPhotosScreen extends StatefulWidget {
  final String directoryPath;
  final String title;

  const ProjectPhotosScreen({
    Key? key,
    required this.directoryPath,
    required this.title,
  }) : super(key: key);

  @override
  State<ProjectPhotosScreen> createState() => _ProjectPhotosScreenState();
}

class _ProjectPhotosScreenState extends State<ProjectPhotosScreen> {
  List<File> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dir = Directory(widget.directoryPath);
      if (!await dir.exists()) {
        setState(() {
          _photos = [];
          _isLoading = false;
        });
        return;
      }

      final List<File> photos = [];
      await for (var entity in dir.list(recursive: false)) {
        if (entity is File &&
            entity.path.toLowerCase().endsWith('.jpg') &&
            !path.basename(entity.path).startsWith('.')) {
          photos.add(entity);
        }
      }

      photos.sort((a, b) => b.path.compareTo(a.path));

      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载照片失败: $e')),
        );
      }
      setState(() {
        _photos = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePhoto(File photo) async {
    try {
      await photo.delete();
      setState(() {
        _photos.remove(photo);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('照片已删除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除照片失败: $e')),
        );
      }
    }
  }

  void _showPhotoDialog(File photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Image.file(photo),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            ButtonBar(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showDeleteConfirmationDialog(photo);
                  },
                  child: const Text('删除'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(File photo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这张照片吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePhoto(photo);
            },
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? const Center(child: Text('暂无照片'))
              : GridView.builder(
                  padding: const EdgeInsets.all(4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    return InkWell(
                      onTap: () => _showPhotoDialog(photo),
                      child: Hero(
                        tag: photo.path,
                        child: Image.file(
                          photo,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}