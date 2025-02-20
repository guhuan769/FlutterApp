// lib/providers/project_provider.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import 'package:http/http.dart' as http;

class UploadStatus {
  final String projectId;
  final String projectName;
  double progress;
  String status;
  bool isComplete;
  bool isSuccess;
  String? error;

  UploadStatus({
    required this.projectId,
    required this.projectName,
    this.progress = 0.0,
    this.status = '准备上传...',
    this.isComplete = false,
    this.isSuccess = false,
    this.error,
  });
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

  Future<void> initialize() async {
    await loadProjects();
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

  Future<List<File>> _loadPhotosInDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];

    final List<File> photos = [];
    await for (var entity in dir.list(recursive: false)) {
      if (entity is File &&
          entity.path.toLowerCase().endsWith('.jpg') &&
          !entity.path.endsWith('project.json') &&
          !entity.path.endsWith('track.json')) {
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

  Future<Track> createTrack(String name, String projectId) async {
    final project = _projects.firstWhere((p) => p.id == projectId);
    final trackId = DateTime.now().millisecondsSinceEpoch.toString();

    final tracksDir = Directory(path.join(project.path, 'tracks'));
    if (!await tracksDir.exists()) {
      await tracksDir.create();
    }

    final trackDir = Directory(path.join(tracksDir.path, trackId));
    await trackDir.create();

    final track = Track(
      id: trackId,
      name: name,
      path: trackDir.path,
      createdAt: DateTime.now(),
      projectId: projectId,
    );

    final configFile = File(path.join(trackDir.path, 'track.json'));
    await configFile.writeAsString(json.encode(track.toJson()));

    project.tracks.add(track);
    notifyListeners();
    return track;
  }

  void setCurrentProject(Project? project) {
    _currentProject = project;
    _currentTrack = null;
    notifyListeners();
  }

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

  // 项目上传方法
  Future<void> uploadProject(Project project) async {
    if (_uploadStatuses.containsKey(project.id)) {
      // 已在上传中
      return;
    }

    _uploadStatuses[project.id] = UploadStatus(
      projectId: project.id,
      projectName: project.name,
    );
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final apiUrl = '${prefs.getString('api_url') ?? 'http://your-server:5000'}/upload/project';

      // 创建multipart请求
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // 添加项目信息
      request.fields['project_info'] = json.encode(project.toJson());

      // 收集所有需要上传的文件
      List<File> allFiles = [];
      allFiles.addAll(project.photos);
      for (var track in project.tracks) {
        allFiles.addAll(track.photos);
      }

      int uploadedFiles = 0;
      for (var file in allFiles) {
        if (await file.exists()) {
          String relativePath = path.relative(file.path, from: project.path);
          request.files.add(
            await http.MultipartFile.fromPath(
              'files[]',
              file.path,
              filename: relativePath,
            ),
          );

          uploadedFiles++;
          _uploadStatuses[project.id]!.progress = uploadedFiles / allFiles.length;
          _uploadStatuses[project.id]!.status = '正在上传文件 $uploadedFiles/${allFiles.length}';
          notifyListeners();
        }
      }

      // 发送请求
      _uploadStatuses[project.id]!.status = '正在处理...';
      notifyListeners();

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        _uploadStatuses[project.id]!.isComplete = true;
        _uploadStatuses[project.id]!.isSuccess = true;
        _uploadStatuses[project.id]!.status = '上传成功';
      } else {
        throw Exception(jsonResponse['message'] ?? '上传失败');
      }
    } catch (e) {
      _uploadStatuses[project.id]!.isComplete = true;
      _uploadStatuses[project.id]!.isSuccess = false;
      _uploadStatuses[project.id]!.error = e.toString();
      _uploadStatuses[project.id]!.status = '上传失败: ${e.toString()}';
    } finally {
      notifyListeners();
      // 5秒后清除状态
      await Future.delayed(const Duration(seconds: 5));
      _uploadStatuses.remove(project.id);
      notifyListeners();
    }
  }

  // 清除所有已完成的上传状态
  void clearCompletedUploads() {
    _uploadStatuses.removeWhere((key, status) => status.isComplete);
    notifyListeners();
  }

  // 获取项目的上传状态
  UploadStatus? getProjectUploadStatus(String projectId) {
    return _uploadStatuses[projectId];
  }

  // 清除指定项目的上传状态
  void clearProjectUploadStatus(String projectId) {
    _uploadStatuses.remove(projectId);
    notifyListeners();
  }

  // 批量上传项目
  Future<void> uploadProjects(List<Project> projects) async {
    for (var project in projects) {
      await uploadProject(project);
    }
  }
}