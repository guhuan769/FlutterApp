// lib/providers/photo_provider.dart
import 'dart:io';
import 'package:camera_photo/config/upload_options.dart';
import 'package:camera_photo/utils/photo_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class PhotoProvider with ChangeNotifier {
  List<File> _photos = [];
  Set<File> _selectedPhotos = {};
  String _apiUrl = 'http://your-server:5000';
  bool _isUploading = false;
  double _uploadProgress = 0;
  String _uploadStatus = '';
  bool _isSelectMode = false;

  bool get isSelectMode => _isSelectMode;
  List<File> get photos => _photos;
  Set<File> get selectedPhotos => _selectedPhotos;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String get uploadStatus => _uploadStatus;
  String get apiUrl => _apiUrl;

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
    } catch (e) {
      print('Error setting API URL: $e');
      throw Exception('Failed to save API URL');
    }
  }

  // 在 PhotoProvider 类中更新这个方法
  Future<void> loadPhotos() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> files = appDir.listSync();

      // 筛选出所有jpg文件
      _photos = files
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.jpg'))
          .toList();

      // 确保所有照片的序号正确
      await PhotoUtils.reorderPhotos(_photos);

      // 重新加载排序后的照片
      _photos = PhotoUtils.sortPhotos(_photos);

      notifyListeners();
    } catch (e) {
      print('Error loading photos: $e');
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
      print('删除照片失败: $e');
      return false;
    }
  }

  void toggleSelectMode() {
    _isSelectMode = !_isSelectMode;
    if (!_isSelectMode) {
      _selectedPhotos.clear();
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedPhotos = Set.from(_photos);
    notifyListeners();
  }

  void clearSelection() {
    _selectedPhotos.clear();
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

  Future<void> uploadSelectedPhotos() async {
    if (_selectedPhotos.isEmpty) return;

    _isUploading = true;
    _uploadProgress = 0;
    _uploadStatus = '准备上传...';
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final savedUrl = '${prefs.getString('api_url')}/upload' ?? _apiUrl;

    int total = _selectedPhotos.length;
    int completed = 0;

    try {
      for (var photo in _selectedPhotos) {
        _uploadStatus = '正在上传 ${completed + 1}/$total';
        notifyListeners();

        try {
          // 创建multipart请求
          var request = http.MultipartRequest('POST', Uri.parse(savedUrl));

          // 获取文件MIME类型
          final mimeType = lookupMimeType(photo.path) ?? 'image/jpeg';

          // 添加文件，保持原始分辨率
          var multipartFile = await http.MultipartFile.fromPath(
            'file',
            photo.path,
            contentType: MediaType.parse(mimeType),
          );

          // 添加其他必要的头部信息
          request.files.add(multipartFile);
          request.headers.addAll({
            'Accept': 'application/json',
            'Content-Type': 'multipart/form-data',
          });

          // 发送请求
          var streamedResponse = await request.send();
          var response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode == 200) {
            completed++;
            _uploadProgress = completed / total;
            notifyListeners();
          } else {
            print('Upload failed with status: ${response.statusCode}');
            print('Response body: ${response.body}');
            _uploadStatus = '上传失败: ${photo.path} (${response.statusCode})';
            notifyListeners();
            await Future.delayed(const Duration(seconds: 2));
          }
        } catch (e) {
          print('Upload error: $e');
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

  // 在 PhotoProvider 类中添加以下方法:
// 在 PhotoProvider 类中修改上传方法：

  Future<void> uploadPhotosWithConfig(UploadType type, String value) async {
    if (_selectedPhotos.isEmpty) return;

    _isUploading = true;
    _uploadProgress = 0;
    _uploadStatus = '准备上传...';
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final savedUrl = '${prefs.getString('api_url')}/upload' ?? _apiUrl;

    int total = _selectedPhotos.length;
    int completed = 0;

    try {
      for (var photo in _selectedPhotos) {
        _uploadStatus = '正在上传 ${completed + 1}/$total';
        notifyListeners();

        try {
          var request = http.MultipartRequest('POST', Uri.parse(savedUrl));

          final mimeType = lookupMimeType(photo.path) ?? 'image/jpeg';

          var multipartFile = await http.MultipartFile.fromPath(
            'file',
            photo.path,
            contentType: MediaType.parse(mimeType),
          );

          // 添加上传类型和值
          request.fields['type'] = type.name;  // 'model' 或 'craft'
          request.fields['value'] = value;     // 具体的值

          request.files.add(multipartFile);
          request.headers.addAll({
            'Accept': 'application/json',
            'Content-Type': 'multipart/form-data',
          });

          var streamedResponse = await request.send();
          var response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode == 200) {
            completed++;
            _uploadProgress = completed / total;
            notifyListeners();
          } else {
            print('Upload failed with status: ${response.statusCode}');
            print('Response body: ${response.body}');
            _uploadStatus = '上传失败: ${photo.path} (${response.statusCode})';
            notifyListeners();
            await Future.delayed(const Duration(seconds: 2));
          }
        } catch (e) {
          print('Upload error: $e');
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

  // 删除特定类型的照片
  Future<void> deletePhotosByType(String photoType) async {
    try {
      List<File> photosToDelete = _photos.where(
              (photo) => PhotoUtils.getPhotoType(photo.path) == photoType
      ).toList();

      for (var photo in photosToDelete) {
        if (await photo.exists()) {
          await photo.delete();
          _photos.remove(photo);
        }
      }
      notifyListeners();
    } catch (e) {
      print('删除照片失败: $e');
      rethrow;
    }
  }

  // 强制重新加载照片列表
  Future<void> forceReloadPhotos() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> files = appDir.listSync();

      _photos = files
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.jpg'))
          .toList();

      // 确保照片按正确顺序排序
      _photos = PhotoUtils.sortPhotos(_photos);

      // 清除选择状态
      _selectedPhotos.clear();

      notifyListeners();
    } catch (e) {
      print('强制重新加载照片失败: $e');
      rethrow;
    }
  }

}