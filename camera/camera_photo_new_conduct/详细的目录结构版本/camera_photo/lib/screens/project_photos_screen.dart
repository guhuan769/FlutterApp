// lib/screens/project_photos_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../utils/photo_utils.dart';

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
  Set<File> _selectedPhotos = {};
  bool _isLoading = true;
  bool _isSelectMode = false;

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

      // 使用 PhotoUtils 进行排序
      final sortedPhotos = PhotoUtils.sortPhotos(photos);

      setState(() {
        _photos = sortedPhotos;
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
        _selectedPhotos.remove(photo);
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

  Future<void> _deleteSelectedPhotos() async {
    try {
      for (var photo in _selectedPhotos.toList()) {
        await photo.delete();
        _photos.remove(photo);
      }
      setState(() {
        _selectedPhotos.clear();
        _isSelectMode = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除 ${_selectedPhotos.length} 张照片')),
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

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      if (!_isSelectMode) {
        _selectedPhotos.clear();
      }
    });
  }

  void _togglePhotoSelection(File photo) {
    setState(() {
      if (_selectedPhotos.contains(photo)) {
        _selectedPhotos.remove(photo);
      } else {
        _selectedPhotos.add(photo);
      }
    });
  }

  void _selectAllPhotos() {
    setState(() {
      if (_selectedPhotos.length == _photos.length) {
        _selectedPhotos.clear();
      } else {
        _selectedPhotos = Set.from(_photos);
      }
    });
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    _formatPhotoName(photo.path).replaceAll('\n', ' '),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '拍摄时间: ${_getPhotoDateTime(photo)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
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

  void _showDeleteSelectedConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedPhotos.length} 张照片吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelectedPhotos();
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
        actions: [
          if (_photos.isNotEmpty) ...[
            IconButton(
              icon: Icon(_isSelectMode ? Icons.close : Icons.select_all),
              onPressed: _toggleSelectMode,
              tooltip: _isSelectMode ? '退出选择' : '进入选择模式',
            ),
            if (_isSelectMode) ...[
              IconButton(
                icon: const Icon(Icons.select_all),
                onPressed: _selectAllPhotos,
                tooltip: _selectedPhotos.length == _photos.length ? '取消全选' : '全选',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _selectedPhotos.isEmpty ? null : _showDeleteSelectedConfirmationDialog,
                tooltip: '删除选中',
              ),
            ],
          ],
        ],
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
                    final isSelected = _selectedPhotos.contains(photo);
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        InkWell(
                          onTap: _isSelectMode
                              ? () => _togglePhotoSelection(photo)
                              : () => _showPhotoDialog(photo),
                          child: Hero(
                            tag: photo.path,
                            child: Image.file(
                              photo,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (_isSelectMode)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.blue : Colors.grey,
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
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            color: Colors.black54,
                            child: Text(
                              _formatPhotoName(photo.path),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }

  // 格式化照片名称，显示类型和序号
  String _formatPhotoName(String photoPath) {
    final fileName = path.basename(photoPath);
    final RegExp pattern = RegExp(r'(.*?)_(\d+)');
    final match = pattern.firstMatch(fileName);
    
    if (match != null) {
      final prefix = match.group(1);
      final number = match.group(2);
      return '$prefix\n#$number';
    }
    return fileName;
  }

  // 获取照片的拍摄时间
  String _getPhotoDateTime(File photo) {
    try {
      final DateTime dateTime = photo.lastModifiedSync();
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return '未知';
    }
  }
}