// lib/providers/photo_provider.dart
import 'dart:convert';
import 'dart:io';
import 'package:camera_photo/config/upload_options.dart';
import 'package:camera_photo/utils/photo_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import '../models/project.dart';

class PhotoProvider with ChangeNotifier {
  List<File> _photos = [];
  Set<File> _selectedPhotos = {};
  bool _isUploading = false;
  double _uploadProgress = 0;
  String _uploadStatus = '';
  bool _isSelectMode = false;
  String _currentDirectoryPath = '';

  bool get isSelectMode => _isSelectMode;
  List<File> get photos => _photos;
  Set<File> get selectedPhotos => _selectedPhotos;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String get uploadStatus => _uploadStatus;

  PhotoProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    await loadPhotos();
  }

  Future<void> handlePhoto(XFile photo, String savePath, String photoType) async {
    final now = DateTime.now();
    final timestamp = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}"
        "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";

    switch (photoType) {
      case PhotoUtils.START_PHOTO:
        await _handleStartPhoto(photo, savePath, timestamp);
        break;
      case PhotoUtils.MIDDLE_PHOTO:
        await _handleMiddlePhoto(photo, savePath, timestamp);
        break;
      case PhotoUtils.END_PHOTO:
        await _handleEndPhoto(photo, savePath, timestamp);
        break;
      case PhotoUtils.MODEL_PHOTO:
        await _handleModelPhoto(photo, savePath, timestamp);
        break;
    }

    await loadPhotosForProjectOrTrack(savePath);
  }

  Future<void> _handleStartPhoto(XFile photo, String savePath, String timestamp) async {
    // Find existing start photos
    final startPhotos = _photos.where(
            (p) => PhotoUtils.getPhotoType(p.path) == PhotoUtils.START_PHOTO
    ).toList();

    if (startPhotos.isNotEmpty) {
      // Replace existing start photo
      for (var existingPhoto in startPhotos) {
        await existingPhoto.delete();
      }
    }

    // Save new start photo
    final filename = PhotoUtils.generateFileName(PhotoUtils.START_PHOTO, 1, timestamp);
    final newPath = path.join(savePath, filename);
    await File(photo.path).copy(newPath);
  }

  Future<void> _handleMiddlePhoto(XFile photo, String savePath, String timestamp) async {
    final sortedPhotos = PhotoUtils.sortPhotos(_photos);
    int newSequence;

    if (sortedPhotos.isEmpty) {
      newSequence = 2;  // First middle photo
    } else {
      // Find last sequence before end photos
      final nonEndPhotos = sortedPhotos.where(
              (p) => PhotoUtils.getPhotoType(p.path) != PhotoUtils.END_PHOTO
      ).toList();

      if (nonEndPhotos.isEmpty) {
        newSequence = 2;
      } else {
        final lastSeq = PhotoUtils.getPhotoSequence(nonEndPhotos.last.path);
        newSequence = lastSeq + 1;
      }
    }

    final filename = PhotoUtils.generateFileName(PhotoUtils.MIDDLE_PHOTO, newSequence, timestamp);
    final newPath = path.join(savePath, filename);
    await File(photo.path).copy(newPath);
  }

  Future<void> _handleEndPhoto(XFile photo, String savePath, String timestamp) async {
    // Find existing end photos
    final endPhotos = _photos.where(
            (p) => PhotoUtils.getPhotoType(p.path) == PhotoUtils.END_PHOTO
    ).toList();

    if (endPhotos.isNotEmpty) {
      // Replace existing end photo
      for (var existingPhoto in endPhotos) {
        await existingPhoto.delete();
      }
    }

    // Save new end photo
    final filename = PhotoUtils.generateFileName(PhotoUtils.END_PHOTO, 999, timestamp);
    final newPath = path.join(savePath, filename);
    await File(photo.path).copy(newPath);
  }

  Future<void> _handleModelPhoto(XFile photo, String savePath, String timestamp) async {
    final sequence = PhotoUtils.generateNewSequence(_photos, PhotoUtils.MODEL_PHOTO);
    final filename = PhotoUtils.generateFileName(PhotoUtils.MODEL_PHOTO, sequence, timestamp);
    final newPath = path.join(savePath, filename);
    await File(photo.path).copy(newPath);
  }

  Future<void> uploadPhotosWithConfig(UploadType type, String value) async {
    if (_selectedPhotos.isEmpty) return;

    _isUploading = true;
    _uploadProgress = 0;
    _uploadStatus = '准备上传...';
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final apiUrl = prefs.getString('api_url');
    
    if (apiUrl == null || apiUrl.isEmpty) {
      _uploadStatus = '错误：请先在设置中配置服务器地址';
      notifyListeners();
      await Future.delayed(const Duration(seconds: 2));
      _isUploading = false;
      notifyListeners();
      return;
    }

    int total = _selectedPhotos.length;
    int completed = 0;

    try {
      for (var photo in _selectedPhotos) {
        _uploadStatus = '正在上传 ${completed + 1}/$total';
        notifyListeners();

        try {
          var request = http.MultipartRequest('POST', Uri.parse('$apiUrl/upload'));

          final mimeType = lookupMimeType(photo.path) ?? 'image/jpeg';

          var multipartFile = await http.MultipartFile.fromPath(
            'file',
            photo.path,
            contentType: MediaType.parse(mimeType),
          );

          // 添加上传类型和值
          request.fields['type'] = type.name;
          request.fields['value'] = value;

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
    if (_selectedPhotos.isEmpty || _isUploading) return;

    try {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadStatus = '准备上传...';
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final apiUrl = prefs.getString('api_url');
      
      if (apiUrl == null || apiUrl.isEmpty) {
        throw Exception('请先在设置中配置服务器地址');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/upload/photos'),
      );

      int count = 0;
      for (var photo in _selectedPhotos) {
        if (await photo.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'photos[]',
              photo.path,
              filename: path.basename(photo.path),
            ),
          );
          count++;
          _uploadProgress = count / _selectedPhotos.length;
          _uploadStatus = '正在准备文件 $count/${_selectedPhotos.length}';
          notifyListeners();
        }
      }

      _uploadStatus = '正在上传...';
      notifyListeners();

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        _uploadStatus = '上传成功！';
        _selectedPhotos.clear();
      } else {
        _uploadStatus = '上传失败: ${response.statusCode}';
        print('Upload failed: $responseData');
      }
    } catch (e) {
      _uploadStatus = '上传错误: $e';
      print('Upload error: $e');
    } finally {
      _isUploading = false;
      _uploadProgress = 0;
      _uploadStatus = '';
      notifyListeners();
    }
  }

  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('api_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _uploadStatus = '服务器地址已加载';
    } else {
      _uploadStatus = '请在设置中配置服务器地址';
    }
    notifyListeners();
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
      if (_currentDirectoryPath.isEmpty) {
        print('没有设置当前目录路径，无法重新加载照片');
        return;
      }

      final dir = Directory(_currentDirectoryPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      _photos = await _loadPhotosInDirectory(_currentDirectoryPath);
      _selectedPhotos.clear();
      notifyListeners();
    } catch (e) {
      print('强制重新加载照片失败: $e');
    }
  }

  Future<void> loadPhotosForProjectOrTrack(String directoryPath) async {
    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      _currentDirectoryPath = directoryPath; // 保存当前目录路径
      _photos = await _loadPhotosInDirectory(directoryPath);
      _selectedPhotos.clear();
      notifyListeners();
    } catch (e) {
      print('Error loading photos: $e');
    }
  }

  Future<List<File>> _loadPhotosInDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];

    final List<File> photos = [];
    await for (var entity in dir.list(recursive: false)) {
      if (entity is File &&
          entity.path.toLowerCase().endsWith('.jpg')) {
        photos.add(entity);
      }
    }
    return PhotoUtils.sortPhotos(photos);
  }

  Future<void> uploadProjectData(Project project) async {
    if (_isUploading) return;

    try {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadStatus = '准备上传项目...';
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final apiUrl = prefs.getString('api_url');
      
      if (apiUrl == null || apiUrl.isEmpty) {
        throw Exception('请先在设置中配置服务器地址');
      }

      // 创建multipart请求
      var request = http.MultipartRequest('POST', Uri.parse('$apiUrl/upload/project'));

      // 添加项目信息
      request.fields['project_info'] = json.encode(project.toJson());

      // 收集所有需要上传的文件
      List<File> allFiles = [];
      // 项目照片
      allFiles.addAll(project.photos);
      // 遍历所有车辆的轨迹照片
      for (var vehicle in project.vehicles) {
        for (var track in vehicle.tracks) {
          allFiles.addAll(track.photos);
        }
      }

      // 添加所有文件
      int fileCount = 0;
      for (var file in allFiles) {
        if (await file.exists()) {
          // 计算文件的相对路径
          String relativePath = path.relative(file.path, from: project.path);

          // 添加文件
          request.files.add(
            await http.MultipartFile.fromPath(
              'files[]',
              file.path,
              filename: relativePath,
            ),
          );

          fileCount++;
          _uploadProgress = fileCount / allFiles.length;
          _uploadStatus = '正在准备文件 $fileCount/${allFiles.length}';
          notifyListeners();
        }
      }

      // 发送请求
      _uploadStatus = '正在上传...';
      notifyListeners();

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        _uploadStatus = '上传成功！';
      } else {
        _uploadStatus = '上传失败: ${response.statusCode}';
        print('Upload failed: $responseData');
      }
    } catch (e) {
      _uploadStatus = '上传错误: $e';
      print('Upload error: $e');
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      _isUploading = false;
      _uploadProgress = 0;
      _uploadStatus = '';
      notifyListeners();
    }
  }

  Future<bool> savePhoto(XFile photo, String savePath) async {
    try {
      final newPath = path.join(savePath, path.basename(photo.path));
      await File(photo.path).copy(newPath);
      await loadPhotosForProjectOrTrack(savePath);
      return true;
    } catch (e) {
      print('Error saving photo: $e');
      return false;
    }
  }

  Future<void> handleStartPointPhoto(XFile photo, String savePath, String timestamp, List<File> photos) async {
    try {
      // 查找现有的起始点照片
      List<File> startPhotos = photos.where(
              (p) => PhotoUtils.getPhotoType(p.path) == PhotoUtils.START_PHOTO
      ).toList();

      // 生成新文件名
      final String filename = PhotoUtils.generateFileName(PhotoUtils.START_PHOTO, 1, timestamp);
      final String newPath = path.join(savePath, filename);

      // 如果有现有的起始点照片，删除它们
      for (var existingPhoto in startPhotos) {
        await existingPhoto.delete();
      }

      // 保存新照片
      await File(photo.path).copy(newPath);
      await forceReloadPhotos();
    } catch (e) {
      print('处理起始点照片失败: $e');
      rethrow;
    }
  }

  Future<void> handleMiddlePointPhoto(XFile photo, String savePath, String timestamp, List<File> photos) async {
    try {
      // 获取所有照片并排序
      List<File> sortedPhotos = PhotoUtils.sortPhotos(photos);

      // 计算新的序号
      int sequence;
      if (sortedPhotos.isEmpty) {
        sequence = 2;  // 如果是第一张照片
      } else {
        // 找到最后一个非结束点照片的序号
        var nonEndPhotos = sortedPhotos.where(
                (p) => PhotoUtils.getPhotoType(p.path) != PhotoUtils.END_PHOTO
        ).toList();

        if (nonEndPhotos.isEmpty) {
          sequence = 2;
        } else {
          sequence = PhotoUtils.getPhotoSequence(nonEndPhotos.last.path) + 1;
        }
      }

      // 生成新文件名并保存
      final String filename = PhotoUtils.generateFileName(PhotoUtils.MIDDLE_PHOTO, sequence, timestamp);
      final String newPath = path.join(savePath, filename);
      await File(photo.path).copy(newPath);

      await forceReloadPhotos();
    } catch (e) {
      print('处理中间点照片失败: $e');
      rethrow;
    }
  }

  Future<void> handleEndPointPhoto(XFile photo, String savePath, String timestamp, List<File> photos) async {
    try {
      // 查找现有的结束点照片
      List<File> endPhotos = photos.where(
              (p) => PhotoUtils.getPhotoType(p.path) == PhotoUtils.END_PHOTO
      ).toList();

      // 生成新文件名
      final String filename = PhotoUtils.generateFileName(PhotoUtils.END_PHOTO, 999, timestamp);
      final String newPath = path.join(savePath, filename);

      // 如果有现有的结束点照片，删除它们
      for (var existingPhoto in endPhotos) {
        await existingPhoto.delete();
      }

      // 保存新照片
      await File(photo.path).copy(newPath);
      await forceReloadPhotos();
    } catch (e) {
      print('处理结束点照片失败: $e');
      rethrow;
    }
  }

  Future<void> handleModelPointPhoto(XFile photo, String savePath, String timestamp, List<File> photos) async {
    try {
      final sequence = PhotoUtils.generateNewSequence(photos, PhotoUtils.MODEL_PHOTO);
      final String filename = PhotoUtils.generateFileName(PhotoUtils.MODEL_PHOTO, sequence, timestamp);
      final String newPath = path.join(savePath, filename);
      await File(photo.path).copy(newPath);
      await forceReloadPhotos();
    } catch (e) {
      print('处理模型点照片失败: $e');
      rethrow;
    }
  }

  Future<String?> getUploadUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final apiUrl = prefs.getString('api_url');
    if (apiUrl == null || apiUrl.isEmpty) {
      return null;
    }
    return '$apiUrl/upload';
  }

  Future<bool> testConnection() async {
    try {
      final url = await getUploadUrl();
      if (url == null) {
        return false;
      }

      final response = await http.get(Uri.parse('$url/status'));
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test error: $e');
      return false;
    }
  }
}