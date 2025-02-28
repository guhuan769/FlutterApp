// lib/providers/project_provider.dart
import 'dart:convert';
import 'dart:io';
import 'package:camera_photo/config/upload_options.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pool/pool.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import 'package:http/http.dart' as http;

// lib/models/upload_status.dart

class UploadStatus {
  final String projectId;
  final String projectName;
  double progress;
  String status;
  bool isComplete;
  bool isSuccess;
  bool hasPlyFiles;
  String? error;
  DateTime uploadTime;

  UploadStatus({
    required this.projectId,
    required this.projectName,
    this.progress = 0.0,
    this.status = '准备上传...',
    this.isComplete = false,
    this.isSuccess = false,
    this.hasPlyFiles = false,
    this.error,
    DateTime? uploadTime,
  }) : uploadTime = uploadTime ?? DateTime.now();

  factory UploadStatus.fromJson(Map<String, dynamic> json) {
    return UploadStatus(
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String,
      progress: (json['progress'] as num).toDouble(),
      status: json['status'] as String,
      isComplete: json['isComplete'] as bool,
      isSuccess: json['isSuccess'] as bool,
      hasPlyFiles: json['hasPlyFiles'] as bool? ?? false,
      error: json['error'] as String?,
      uploadTime: DateTime.parse(json['uploadTime'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'projectName': projectName,
    'progress': progress,
    'status': status,
    'isComplete': isComplete,
    'isSuccess': isSuccess,
    'hasPlyFiles': hasPlyFiles,
    'error': error,
    'uploadTime': uploadTime.toIso8601String(),
  };

  UploadStatus copyWith({
    String? projectId,
    String? projectName,
    double? progress,
    String? status,
    bool? isComplete,
    bool? isSuccess,
    bool? hasPlyFiles,
    String? error,
    DateTime? uploadTime,
  }) {
    return UploadStatus(
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      isComplete: isComplete ?? this.isComplete,
      isSuccess: isSuccess ?? this.isSuccess,
      hasPlyFiles: hasPlyFiles ?? this.hasPlyFiles,
      error: error ?? this.error,
      uploadTime: uploadTime ?? this.uploadTime,
    );
  }
}


class ProjectUploadStatus {
  final String projectId;
  final DateTime uploadTime;
  final bool hasPlyFiles;
  final bool isComplete;
  final String? error;

  ProjectUploadStatus({
    required this.projectId,
    required this.uploadTime,
    this.hasPlyFiles = false,
    this.isComplete = false,
    this.error,
  });

  factory ProjectUploadStatus.fromJson(Map<String, dynamic> json) {
    return ProjectUploadStatus(
      projectId: json['projectId'],
      uploadTime: DateTime.parse(json['uploadTime']),
      hasPlyFiles: json['hasPlyFiles'] ?? false,
      isComplete: json['isComplete'] ?? false,
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'uploadTime': uploadTime.toIso8601String(),
    'hasPlyFiles': hasPlyFiles,
    'isComplete': isComplete,
    'error': error,
  };
}

class ProjectProvider with ChangeNotifier {
  List<Project> _projects = [];
  Project? _currentProject;
  Track? _currentTrack;
  final Map<String, UploadStatus> _uploadStatuses = {};

  List<Project> get projects => _projects;
  Project? get currentProject => _currentProject;
  Track? get currentTrack => _currentTrack;
  Map<String, UploadStatus> get uploadStatuses => _uploadStatuses;

// 初始化方法 - 加载所有数据
  Future<void> initialize() async {
    try {
      // 1. 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      final projectsDir = Directory(path.join(appDir.path, 'projects'));

      // 2. 确保项目目录存在
      if (!await projectsDir.exists()) {
        await projectsDir.create();
      }

      // 3. 获取所有项目目录
      final projectDirs = await projectsDir
          .list()
          .where((entity) => entity is Directory)
          .toList();

      // 4. 清空当前项目列表
      _projects = [];

      // 5. 遍历加载每个项目
      for (var dir in projectDirs) {
        final configFile = File(path.join(dir.path, 'project.json'));
        if (await configFile.exists()) {
          // 读取项目配置
          final jsonData = json.decode(await configFile.readAsString());
          final project = Project.fromJson(jsonData);

          // 加载项目照片
          project.photos = await _loadPhotosInDirectory(dir.path);

          // 加载项目轨迹
          final tracksDir = Directory(path.join(dir.path, 'tracks'));
          if (await tracksDir.exists()) {
            final trackDirs = await tracksDir
                .list()
                .where((entity) => entity is Directory)
                .toList();

            // 遍历加载每个轨迹
            for (var trackDir in trackDirs) {
              final trackConfigFile = File(
                  path.join(trackDir.path, 'track.json'));
              if (await trackConfigFile.exists()) {
                final trackJson = json.decode(
                    await trackConfigFile.readAsString());
                final track = Track.fromJson(trackJson);

                // 加载轨迹照片
                track.photos = await _loadPhotosInDirectory(trackDir.path);
                project.tracks.add(track);
              }
            }
          }

          _projects.add(project);
        }
      }

      // 6. 加载上传状态
      await loadUploadStatuses();

      // 7. 通知监听器更新
      notifyListeners();
    } catch (e) {
      print('Error initializing provider: $e');
    }
  }

  Future<void> loadProjects() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final projectsDir = Directory(path.join(appDir.path, 'projects'));
      if (!await projectsDir.exists()) {
        await projectsDir.create();
      }

      final projectDirs = await projectsDir.list().where((entity) =>
      entity is Directory).toList();

      _projects = [];
      for (var dir in projectDirs) {
        final configFile = File(path.join(dir.path, 'project.json'));
        if (await configFile.exists()) {
          final jsonData = json.decode(await configFile.readAsString());
          final project = Project.fromJson(jsonData);

          // Load photos
          project.photos = await _loadPhotosInDirectory(dir.path);

          // Load tracks
          final tracksDir = Directory(path.join(dir.path, 'tracks'));
          if (await tracksDir.exists()) {
            final trackDirs = await tracksDir.list().where((entity) =>
            entity is Directory).toList();

            for (var trackDir in trackDirs) {
              final trackConfigFile = File(
                  path.join(trackDir.path, 'track.json'));
              if (await trackConfigFile.exists()) {
                final trackJson = json.decode(
                    await trackConfigFile.readAsString());
                final track = Track.fromJson(trackJson);
                track.photos = await _loadPhotosInDirectory(trackDir.path);
                project.tracks.add(track);
              }
            }
          }

          _projects.add(project);
        }
      }
      notifyListeners();
    } catch (e) {
      print('Error loading projects: $e');
    }
  }

  // 加载指定目录中的照片
  Future<List<File>> _loadPhotosInDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];

    final List<File> photos = [];
    await for (var entity in dir.list(recursive: false)) {
      if (entity is File &&
          entity.path.toLowerCase().endsWith('.jpg') &&
          !path.basename(entity.path).startsWith('.')) {  // 排除隐藏文件
        photos.add(entity);
      }
    }
    return photos;
  }

  Future<Project> createProject(String name) async {
    final appDir = await getApplicationDocumentsDirectory();
    final projectsDir = Directory(path.join(appDir.path, 'projects'));
    if (!await projectsDir.exists()) {
      await projectsDir.create();
    }

    final projectId = DateTime.now().millisecondsSinceEpoch.toString();
    final projectDir = Directory(path.join(projectsDir.path, projectId));
    await projectDir.create();

    final project = Project(
      id: projectId,
      name: name,
      path: projectDir.path,
      createdAt: DateTime.now(),
    );

    final configFile = File(path.join(projectDir.path, 'project.json'));
    await configFile.writeAsString(json.encode(project.toJson()));

    _projects.add(project);
    notifyListeners();
    return project;
  }

// 在 ProjectProvider 类中更新 createTrack 方法
  Future<Track> createTrack(String name, String projectId) async {
    try {
      // 查找项目
      final project = _projects.firstWhere((p) => p.id == projectId);
      final trackId = DateTime.now().millisecondsSinceEpoch.toString();

      // 创建轨迹目录
      final tracksDir = Directory(path.join(project.path, 'tracks'));
      if (!await tracksDir.exists()) {
        await tracksDir.create();
      }

      // 创建轨迹文件夹
      final trackDir = Directory(path.join(tracksDir.path, trackId));
      await trackDir.create();

      // 创建轨迹对象
      final track = Track(
        id: trackId,
        name: name,
        path: trackDir.path,
        createdAt: DateTime.now(),
        projectId: projectId,
        photos: [], // 初始化为空列表
      );

      // 保存轨迹配置文件
      final configFile = File(path.join(trackDir.path, 'track.json'));
      await configFile.writeAsString(json.encode(track.toJson()));

      // 更新项目中的轨迹列表
      project.tracks.add(track);

      // 重新加载项目数据以确保所有数据都是最新的
      await _reloadProject(project);

      // 通知监听器
      notifyListeners();

      return track;
    } catch (e) {
      print('Error creating track: $e');
      rethrow;
    }
  }


// 添加新的辅助方法来重新加载项目数据
  Future<void> _reloadProject(Project project) async {
    try {
      // 重新加载项目照片
      project.photos = await _loadPhotosInDirectory(project.path);

      // 重新加载每个轨迹的照片
      for (var track in project.tracks) {
        track.photos = await _loadPhotosInDirectory(track.path);
      }

      // 确保轨迹按照创建时间排序
      project.tracks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error reloading project: $e');
    }
  }


  // 设置当前项目
  void setCurrentProject(Project? project) {
    _currentProject = project;
    notifyListeners();
  }

  // 设置当前轨迹
  void setCurrentTrack(Track? track) {
    _currentTrack = track;
    notifyListeners();
  }

  Future<void> deleteProject(String projectId) async {
    try {
      final project = _projects.firstWhere((p) => p.id == projectId);
      final projectDir = Directory(project.path);
      if (await projectDir.exists()) {
        await projectDir.delete(recursive: true);
      }
      _projects.removeWhere((p) => p.id == projectId);
      if (_currentProject?.id == projectId) {
        _currentProject = null;
        _currentTrack = null;
      }
      notifyListeners();
    } catch (e) {
      print('Error deleting project: $e');
      rethrow;
    }
  }

  Future<void> deleteTrack(String projectId, String trackId) async {
    try {
      final project = _projects.firstWhere((p) => p.id == projectId);
      final track = project.tracks.firstWhere((t) => t.id == trackId);

      final trackDir = Directory(track.path);
      if (await trackDir.exists()) {
        await trackDir.delete(recursive: true);
      }

      project.tracks.removeWhere((t) => t.id == trackId);
      if (_currentTrack?.id == trackId) {
        _currentTrack = null;
      }
      notifyListeners();
    } catch (e) {
      print('Error deleting track: $e');
      rethrow;
    }
  }

  Future<void> renameProject(String projectId, String newName) async {
    try {
      final project = _projects.firstWhere((p) => p.id == projectId);
      project.name = newName;

      final configFile = File(path.join(project.path, 'project.json'));
      await configFile.writeAsString(json.encode(project.toJson()));

      notifyListeners();
    } catch (e) {
      print('Error renaming project: $e');
      rethrow;
    }
  }

  Future<void> renameTrack(String projectId, String trackId, String newName) async {
    try {
      final project = _projects.firstWhere((p) => p.id == projectId);
      final track = project.tracks.firstWhere((t) => t.id == trackId);
      track.name = newName;

      final configFile = File(path.join(track.path, 'track.json'));
      await configFile.writeAsString(json.encode(track.toJson()));

      notifyListeners();
    } catch (e) {
      print('Error renaming track: $e');
      rethrow;
    }
  }

  Future<void> uploadProjectOrTrack(String path) async {
    // TODO: Implement upload logic
  }

  // 清除所有已完成的上传状态
  void clearCompletedUploads() {
    _uploadStatuses.removeWhere((key, status) => status.isComplete);
    notifyListeners();
    _saveUploadStatuses();
  }

  // 获取项目的上传状态
  UploadStatus? getProjectUploadStatus(String projectId) {
    return _uploadStatuses[projectId];
  }

  // 清除指定项目的上传状态
  void clearProjectUploadStatus(String projectId) {
    _uploadStatuses.remove(projectId);
    notifyListeners();
    _saveUploadStatuses();
  }

  Future<void> loadUploadStatuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusesJson = prefs.getString('project_upload_statuses');

      if (statusesJson != null) {
        final Map<String, dynamic> statusesMap = json.decode(statusesJson);
        _uploadStatuses.clear();

        statusesMap.forEach((key, value) {
          _uploadStatuses[key] = UploadStatus.fromJson(value);
        });

        notifyListeners();
      }
    } catch (e) {
      print('Error loading upload statuses: $e');
    }
  }

  Future<void> _saveUploadStatuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusesMap = _uploadStatuses.map(
              (key, value) => MapEntry(key, value.toJson())
      );

      await prefs.setString(
          'project_upload_statuses',
          json.encode(statusesMap)
      );
    } catch (e) {
      print('Error saving upload statuses: $e');
    }
  }

  // Update project upload status
  void updateUploadStatus(String projectId, UploadStatus status) {
    _uploadStatuses[projectId] = status;
    notifyListeners();
    _saveUploadStatuses(); // 保存状态
  }

  // 批量上传项目
  Future<void> uploadProjects(List<Project> projects) async {
    for (var project in projects) {
      await uploadProject(project);
    }
  }

  // 在 ProjectProvider 类中更新上传方法
  Future<void> uploadProject(Project project, {UploadType? type, String? value}) async {
    if (_uploadStatuses.containsKey(project.id) &&
        !_uploadStatuses[project.id]!.isComplete) {
      return;
    }

    var status = UploadStatus(
      projectId: project.id,
      projectName: project.name,
    );
    _uploadStatuses[project.id] = status;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final apiUrl = '${prefs.getString('api_url') ?? 'http://localhost:5000'}/upload';

      // 收集并预处理所有文件
      final allFiles = await _prepareFilesForUpload(project);
      if (allFiles.isEmpty) {
        throw Exception('No valid files to upload');
      }

      // 使用多个并发上传来提高速度
      final batches = _createUploadBatches(allFiles);
      final totalFiles = allFiles.length;
      int totalSuccess = 0;

      // 并发上传所有批次，但限制并发数
      final batchResults = await _uploadBatchesConcurrently(
          batches: batches,
          apiUrl: apiUrl,
          project: project,
          type: type,
          value: value,
          onProgress: (completed, total) {
            status = status.copyWith(
              progress: completed / total,
              status: '正在上传: $completed/$total',
            );
            _uploadStatuses[project.id] = status;
            notifyListeners();
          }
      );

      // 处理上传结果
      for (var result in batchResults) {
        if (result.success) {
          totalSuccess += result.filesCount;
        }
      }

      // 更新最终状态
      status = status.copyWith(
        isComplete: true,
        isSuccess: totalSuccess == totalFiles,
        status: '上传完成\n成功: $totalSuccess/$totalFiles张照片',
      );

    } catch (e) {
      print('上传过程错误: $e');
      status = status.copyWith(
        isComplete: true,
        isSuccess: false,
        status: '上传失败',
        error: e.toString(),
      );
    } finally {
      _uploadStatuses[project.id] = status;
      notifyListeners();
      await _saveUploadStatuses();
    }
  }

// 预处理文件方法
  Future<List<Map<String, dynamic>>> _prepareFilesForUpload(Project project) async {
    List<Map<String, dynamic>> allFiles = [];

    // 使用并发处理来加速文件预处理
    await Future.wait([
      // 处理项目照片
      Future(() async {
        for (var photo in project.photos) {
          if (await photo.exists()) {
            final bytes = await photo.readAsBytes();
            if (bytes.isNotEmpty) {
              allFiles.add({
                'file': photo,
                'bytes': bytes,
                'type': 'project',
                'path': photo.path,
                'relativePath': path.relative(photo.path, from: project.path)
              });
            }
          }
        }
      }),

      // 处理轨迹照片
      Future(() async {
        for (var track in project.tracks) {
          await Future.forEach(track.photos, (photo) async {
            if (await photo.exists()) {
              final bytes = await photo.readAsBytes();
              if (bytes.isNotEmpty) {
                allFiles.add({
                  'file': photo,
                  'bytes': bytes,
                  'type': 'track',
                  'trackId': track.id,
                  'trackName': track.name,
                  'path': photo.path,
                  'relativePath': 'tracks/${track.name}/${path.basename(photo.path)}'
                });
              }
            }
          });
        }
      })
    ]);

    return allFiles;
  }

// 创建上传批次
  List<List<Map<String, dynamic>>> _createUploadBatches(List<Map<String, dynamic>> files) {
    const int batchSize = 5;
    final List<List<Map<String, dynamic>>> batches = [];

    for (var i = 0; i < files.length; i += batchSize) {
      final end = (i + batchSize < files.length) ? i + batchSize : files.length;
      batches.add(files.sublist(i, end));
    }

    return batches;
  }

// 修改并发上传方法以确保批次序号正确
  Future<List<BatchUploadResult>> _uploadBatchesConcurrently({
    required List<List<Map<String, dynamic>>> batches,
    required String apiUrl,
    required Project project,
    required UploadType? type,
    required String? value,
    required void Function(int completed, int total) onProgress,
  }) async {
    final results = <BatchUploadResult>[];
    final total = batches.length;
    var completed = 0;

    // 限制并发数为3
    final pool = Pool(3);

    try {
      final futures = batches.asMap().entries.map((entry) {
        final batchIndex = entry.key;
        final batch = entry.value;

        return pool.withResource(() async {
          final result = await _uploadBatch(
            batch: batch,
            batchNumber: batchIndex + 1,  // 批次号从1开始
            totalBatches: batches.length,
            apiUrl: apiUrl,
            project: project,
            type: type,
            value: value,
          );

          completed++;
          onProgress(completed, total);
          return result;
        });
      });

      results.addAll(await Future.wait(futures));
    } catch (e) {
      print('Concurrent upload error: $e');
    }

    return results;
  }




  Future<BatchUploadResult> _uploadBatch({
    required List<Map<String, dynamic>> batch,
    required int batchNumber,
    required int totalBatches,
    required String apiUrl,
    required Project project,
    required UploadType? type,
    required String? value,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    // 确保批次信息作为字符串发送
    request.fields.addAll({
      'type': type?.name ?? 'unknown',
      'value': value ?? 'unknown',
      'project_info': json.encode(project.toJson()),
      'batch_number': batchNumber.toString(),  // 确保转换为字符串
      'total_batches': totalBatches.toString(),  // 确保转换为字符串
    });

    print('Uploading batch ${batchNumber}/${totalBatches}');  // 调试信息

    // 添加文件
    for (int i = 0; i < batch.length; i++) {
      final fileInfo = batch[i];
      final bytes = fileInfo['bytes'] as Uint8List;
      final fileName = path.basename(fileInfo['path'] as String);

      request.files.add(
          http.MultipartFile.fromBytes(
              'files[]',
              bytes,
              filename: fileName,
              contentType: MediaType('image', 'jpeg')
          )
      );

      // 添加文件信息
      request.fields['file_info_$i'] = json.encode({
        'type': fileInfo['type'],
        'trackId': fileInfo['trackId'] ?? '',
        'trackName': fileInfo['trackName'] ?? '',
        'relativePath': fileInfo['relativePath']
      });
    }

    try {
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      print('Batch upload response: $responseData');  // 调试信息

      if (response.statusCode == 200) {
        return BatchUploadResult(success: true, filesCount: batch.length);
      } else {
        print('Batch upload failed: ${response.statusCode}, $responseData');
        return BatchUploadResult(success: false, filesCount: batch.length);
      }
    } catch (e) {
      print('Batch upload error: $e');
      return BatchUploadResult(success: false, filesCount: batch.length);
    }
  }





}



// 批次上传结果类
class BatchUploadResult {
  final bool success;
  final int filesCount;

  BatchUploadResult({
    required this.success,
    required this.filesCount,
  });
}