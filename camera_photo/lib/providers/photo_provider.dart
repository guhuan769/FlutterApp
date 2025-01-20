
// lib/providers/photo_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PhotoProvider with ChangeNotifier {
  List<File> _photos = [];
  Set<File> _selectedPhotos = {};
  String apiUrl = 'http://192.168.5.21:5000/upload'; // Change this to your server URL

  List<File> get photos => _photos;
  Set<File> get selectedPhotos => _selectedPhotos;

  // 添加上传状态跟踪
  bool _isUploading = false;
  double _uploadProgress = 0;
  String _uploadStatus = '';

  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String get uploadStatus => _uploadStatus;

  Future<void> uploadSelectedPhotos() async {
    if (_selectedPhotos.isEmpty) return;

    _isUploading = true;
    _uploadProgress = 0;
    _uploadStatus = '准备上传...';
    notifyListeners();

    int total = _selectedPhotos.length;
    int completed = 0;

    try {
      for (var photo in _selectedPhotos) {
        _uploadStatus = '正在上传 ${completed + 1}/$total';
        notifyListeners();

        try {
          var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
          request.files.add(
            await http.MultipartFile.fromPath('file', photo.path),
          );

          var response = await request.send();
          if (response.statusCode == 200) {
            completed++;
            _uploadProgress = completed / total;
            notifyListeners();
          } else {
            _uploadStatus = '上传失败: ${photo.path}';
            notifyListeners();
            await Future.delayed(const Duration(seconds: 2));
          }
        } catch (e) {
          _uploadStatus = '上传错误: $e';
          notifyListeners();
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      if (completed == total) {
        _uploadStatus = '上传完成！';
      } else {
        _uploadStatus = '部分上传失败，完成: $completed/$total';
      }
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      _isUploading = false;
      _uploadProgress = 0;
      _uploadStatus = '';
      _selectedPhotos.clear();
      notifyListeners();
    }
  }

  Future<void> loadPhotos() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = appDir.listSync();
    _photos = files
        .whereType<File>()
        .where((file) => file.path.endsWith('.jpg'))
        .toList();
    notifyListeners();
  }

  void togglePhotoSelection(File photo) {
    if (_selectedPhotos.contains(photo)) {
      _selectedPhotos.remove(photo);
    } else {
      _selectedPhotos.add(photo);
    }
    notifyListeners();
  }

  Future<void> deleteSelectedPhotos() async {
    for (var photo in _selectedPhotos) {
      await photo.delete();
      _photos.remove(photo);
    }
    _selectedPhotos.clear();
    notifyListeners();
  }

  void setApiUrl(String url) {
    apiUrl = url;
  }
}