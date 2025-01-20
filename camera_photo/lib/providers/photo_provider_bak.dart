// lib/providers/photo_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoProvider with ChangeNotifier {
  List<File> _photos = [];
  Set<File> _selectedPhotos = {};
  String _apiUrl = 'http://your-server:5000/upload';
  bool _isUploading = false;
  double _uploadProgress = 0;
  String _uploadStatus = '';

  bool _isSelectMode = false; // 添加选择模式状态
  bool get isSelectMode => _isSelectMode;

  void toggleSelectMode() {
    _isSelectMode = !_isSelectMode;
    if (!_isSelectMode) {
      _selectedPhotos.clear(); // 退出选择模式时清空选择
    }
    notifyListeners();
  }

  PhotoProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    await loadPhotos();
    await _loadSavedUrl();
  }

  Future<void> setApiUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_url', url);
      _apiUrl = url;
      notifyListeners();
      print('API URL updated successfully: $url');
    } catch (e) {
      print('Error setting API URL: $e');
      throw Exception('Failed to save API URL');
    }
  }

  Future<void> loadPhotos() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> files = appDir.listSync();

      // 只获取jpg文件
      _photos = files
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.jpg'))
          .toList();

      // 按照修改时间排序，最新的在前面
      _photos.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      notifyListeners();
    } catch (e) {
      print('Error loading photos: $e');
    }
  }

  void selectAll() {
    _selectedPhotos = Set.from(_photos);
    notifyListeners();
  }

  void clearSelection() {
    _selectedPhotos.clear();
    notifyListeners();
  }

  Future<void> deleteSelectedPhotos() async {
    try {
      for (var photo in _selectedPhotos) {
        try {
          await photo.delete();
          _photos.remove(photo);
        } catch (e) {
          print('Error deleting photo: ${photo.path}, error: $e');
        }
      }
      _selectedPhotos.clear();
      notifyListeners();
    } catch (e) {
      print('Error in deleteSelectedPhotos: $e');
    }
  }

  Future<bool> deletePhoto(File photo) async {
    try {
      await photo.delete();
      _photos.remove(photo);
      _selectedPhotos.remove(photo);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting single photo: $e');
      return false;
    }
  }

  void togglePhotoSelection(File photo) {
    if (_selectedPhotos.contains(photo)) {
      _selectedPhotos.remove(photo);
    } else {
      _selectedPhotos.add(photo);
    }
    notifyListeners();
  }

  Future<void> uploadSelectedPhotos() async {
    if (_selectedPhotos.isEmpty) return;

    _isUploading = true;
    _uploadProgress = 0;
    _uploadStatus = '准备上传...';
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('api_url') ?? _apiUrl;

    int total = _selectedPhotos.length;
    int completed = 0;

    try {
      for (var photo in _selectedPhotos) {
        _uploadStatus = '正在上传 ${completed + 1}/$total';
        notifyListeners();

        try {
          var request = http.MultipartRequest('POST', Uri.parse(savedUrl));
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

  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _apiUrl = prefs.getString('api_url') ?? _apiUrl;
  }

  // Getters
  List<File> get photos => _photos;
  Set<File> get selectedPhotos => _selectedPhotos;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String get uploadStatus => _uploadStatus;
  String get apiUrl => _apiUrl;
}