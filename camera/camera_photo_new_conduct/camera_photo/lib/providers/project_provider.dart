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
  int uploadCount;
  List<UploadLog> logs;

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
    this.uploadCount = 0,
    List<UploadLog>? logs,
  }) : uploadTime = uploadTime ?? DateTime.now(),
       logs = logs ?? [];

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
      uploadCount: json['uploadCount'] as int? ?? 0,
      logs: (json['logs'] as List<dynamic>?)?.map((e) => UploadLog.fromJson(e as Map<String, dynamic>)).toList() ?? [],
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
    'uploadCount': uploadCount,
    'logs': logs.map((log) => log.toJson()).toList(),
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
    int? uploadCount,
    List<UploadLog>? logs,
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
      uploadCount: uploadCount ?? this.uploadCount,
      logs: logs ?? this.logs,
    );
  }

  void addLog(String message, {bool isError = false}) {
    logs.add(UploadLog(
      message: message,
      timestamp: DateTime.now(),
      isError: isError,
    ));
  }
}

class UploadLog {
  final String message;
  final DateTime timestamp;
  final bool isError;

  UploadLog({
    required this.message,
    required this.timestamp,
    this.isError = false,
  });

  factory UploadLog.fromJson(Map<String, dynamic> json) {
    return UploadLog(
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isError: json['isError'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isError': isError,
  };
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
  Vehicle? _currentVehicle;
  Track? _currentTrack;
  final Map<String, UploadStatus> _uploadStatuses = {};

  List<Project> get projects => _projects;
  Project? get currentProject => _currentProject;
  Vehicle? get currentVehicle => _currentVehicle;
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

          // 加载项目车辆
          final vehiclesDir = Directory(path.join(dir.path, 'vehicles'));
          if (await vehiclesDir.exists()) {
            final vehicleDirs = await vehiclesDir
                .list()
                .where((entity) => entity is Directory)
                .toList();

            // 遍历加载每个车辆
            for (var vehicleDir in vehicleDirs) {
              final vehicleConfigFile = File(
                  path.join(vehicleDir.path, 'vehicle.json'));
              if (await vehicleConfigFile.exists()) {
                final vehicleJson = json.decode(
                    await vehicleConfigFile.readAsString());
                final vehicle = Vehicle.fromJson(vehicleJson);

                // 加载车辆照片
                vehicle.photos = await _loadPhotosInDirectory(vehicleDir.path);

                // 加载车辆轨迹
                final tracksDir = Directory(path.join(vehicleDir.path, 'tracks'));
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
                      vehicle.tracks.add(track);
                    }
                  }
                }

                project.vehicles.add(vehicle);
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

          // Load vehicles
          final vehiclesDir = Directory(path.join(dir.path, 'vehicles'));
          if (await vehiclesDir.exists()) {
            final vehicleDirs = await vehiclesDir.list().where((entity) =>
            entity is Directory).toList();

            for (var vehicleDir in vehicleDirs) {
              final vehicleConfigFile = File(
                  path.join(vehicleDir.path, 'vehicle.json'));
              if (await vehicleConfigFile.exists()) {
                final vehicleJson = json.decode(
                    await vehicleConfigFile.readAsString());
                final vehicle = Vehicle.fromJson(vehicleJson);
                vehicle.photos = await _loadPhotosInDirectory(vehicleDir.path);
                
                // Load tracks for this vehicle
                final tracksDir = Directory(path.join(vehicleDir.path, 'tracks'));
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
                      vehicle.tracks.add(track);
                    }
                  }
                }
                
                project.vehicles.add(vehicle);
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

    // 创建vehicles目录
    final vehiclesDir = Directory(path.join(projectDir.path, 'vehicles'));
    await vehiclesDir.create();

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

  // 创建车辆
  Future<Vehicle> createVehicle(String name, String projectId) async {
    try {
      // 查找项目
      final project = _projects.firstWhere((p) => p.id == projectId);
      final vehicleId = DateTime.now().millisecondsSinceEpoch.toString();

      // 创建车辆目录
      final vehiclesDir = Directory(path.join(project.path, 'vehicles'));
      if (!await vehiclesDir.exists()) {
        await vehiclesDir.create();
      }

      // 创建车辆文件夹
      final vehicleDir = Directory(path.join(vehiclesDir.path, vehicleId));
      await vehicleDir.create();

      // 创建车辆对象
      final vehicle = Vehicle(
        id: vehicleId,
        name: name,
        path: vehicleDir.path,
        createdAt: DateTime.now(),
        projectId: projectId,
      );

      // 保存车辆配置文件
      final configFile = File(path.join(vehicleDir.path, 'vehicle.json'));
      await configFile.writeAsString(json.encode(vehicle.toJson()));

      // 更新项目中的车辆列表
      project.vehicles.add(vehicle);

      // 重新加载项目数据以确保所有数据都是最新的
      await _reloadProject(project);

      // 通知监听器
      notifyListeners();

      return vehicle;
    } catch (e) {
      print('Error creating vehicle: $e');
      rethrow;
    }
  }

// 创建轨迹
  Future<Track> createTrack(String name, String vehicleId) async {
    try {
      // 查找车辆
      Vehicle? vehicle;
      Project? project;
      
      for (var p in _projects) {
        for (var v in p.vehicles) {
          if (v.id == vehicleId) {
            vehicle = v;
            project = p;
            break;
          }
        }
        if (vehicle != null) break;
      }
      
      if (vehicle == null || project == null) {
        throw Exception('Vehicle not found');
      }
      
      final trackId = DateTime.now().millisecondsSinceEpoch.toString();

      // 创建轨迹目录
      final tracksDir = Directory(path.join(vehicle.path, 'tracks'));
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
        vehicleId: vehicleId,
        projectId: project.id,
      );

      // 保存轨迹配置文件
      final configFile = File(path.join(trackDir.path, 'track.json'));
      await configFile.writeAsString(json.encode(track.toJson()));

      // 更新车辆中的轨迹列表
      vehicle.tracks.add(track);

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

      // 重新加载每个车辆和轨迹的照片
      for (var vehicle in project.vehicles) {
        vehicle.photos = await _loadPhotosInDirectory(vehicle.path);
        
        // 重新加载每个轨迹的照片
        for (var track in vehicle.tracks) {
          track.photos = await _loadPhotosInDirectory(track.path);
        }
        
        // 确保轨迹按照创建时间排序
        vehicle.tracks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      
      // 确保车辆按照创建时间排序
      project.vehicles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error reloading project: $e');
    }
  }

  // 设置当前项目
  void setCurrentProject(Project? project) {
    _currentProject = project;
    _currentVehicle = null;
    _currentTrack = null;
    notifyListeners();
  }

  // 设置当前车辆
  void setCurrentVehicle(Vehicle? vehicle) {
    _currentVehicle = vehicle;
    _currentTrack = null;
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
        _currentVehicle = null;
        _currentTrack = null;
      }
      notifyListeners();
    } catch (e) {
      print('Error deleting project: $e');
      rethrow;
    }
  }

  // 删除车辆
  Future<void> deleteVehicle(String projectId, String vehicleId) async {
    try {
      final project = _projects.firstWhere((p) => p.id == projectId);
      final vehicle = project.vehicles.firstWhere((v) => v.id == vehicleId);

      final vehicleDir = Directory(vehicle.path);
      if (await vehicleDir.exists()) {
        await vehicleDir.delete(recursive: true);
      }

      project.vehicles.removeWhere((v) => v.id == vehicleId);
      if (_currentVehicle?.id == vehicleId) {
        _currentVehicle = null;
        _currentTrack = null;
      }
      notifyListeners();
    } catch (e) {
      print('Error deleting vehicle: $e');
      rethrow;
    }
  }

  // 删除轨迹
  Future<void> deleteTrack(String vehicleId, String trackId) async {
    try {
      Vehicle? vehicle;
      
      for (var project in _projects) {
        for (var v in project.vehicles) {
          if (v.id == vehicleId) {
            vehicle = v;
            break;
          }
        }
        if (vehicle != null) break;
      }
      
      if (vehicle == null) {
        throw Exception('Vehicle not found');
      }
      
      final track = vehicle.tracks.firstWhere((t) => t.id == trackId);

      final trackDir = Directory(track.path);
      if (await trackDir.exists()) {
        await trackDir.delete(recursive: true);
      }

      vehicle.tracks.removeWhere((t) => t.id == trackId);
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

  // 重命名车辆
  Future<void> renameVehicle(String projectId, String vehicleId, String newName) async {
    try {
      final project = _projects.firstWhere((p) => p.id == projectId);
      final vehicle = project.vehicles.firstWhere((v) => v.id == vehicleId);
      vehicle.name = newName;

      final configFile = File(path.join(vehicle.path, 'vehicle.json'));
      await configFile.writeAsString(json.encode(vehicle.toJson()));

      notifyListeners();
    } catch (e) {
      print('Error renaming vehicle: $e');
      rethrow;
    }
  }

  // 重命名轨迹
  Future<void> renameTrack(String vehicleId, String trackId, String newName) async {
    try {
      Vehicle? vehicle;
      
      for (var project in _projects) {
        for (var v in project.vehicles) {
          if (v.id == vehicleId) {
            vehicle = v;
            break;
          }
        }
        if (vehicle != null) break;
      }
      
      if (vehicle == null) {
        throw Exception('Vehicle not found');
      }
      
      final track = vehicle.tracks.firstWhere((t) => t.id == trackId);
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
    // 获取或创建上传状态
    UploadStatus status = _uploadStatuses[project.id] ?? UploadStatus(
      projectId: project.id,
      projectName: project.name,
    );

    if (!status.isComplete) {
      return;
    }

    // 更新上传次数和状态
    status = UploadStatus(
      projectId: project.id,
      projectName: project.name,
      uploadCount: status.uploadCount + 1,
      isComplete: false,
      isSuccess: false,
      progress: 0.0,
      logs: List.from(status.logs), // 创建日志列表的副本
    );
    
    // 添加开始上传日志
    status.addLog('开始上传项目 ${project.name}');
    _uploadStatuses[project.id] = status;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final apiUrl = '${prefs.getString('api_url') ?? 'http://localhost:5000'}/upload';

      // 收集文件
      final allFiles = await _prepareFilesForUpload(project);
      if (allFiles.isEmpty) {
        throw Exception('没有可上传的文件');
      }

      status.addLog('找到 ${allFiles.length} 个文件待上传');
      status = UploadStatus(
        projectId: project.id,
        projectName: project.name,
        uploadCount: status.uploadCount,
        status: '准备上传 ${allFiles.length} 张照片',
        logs: List.from(status.logs),
      );
      _uploadStatuses[project.id] = status;
      notifyListeners();

      // 创建批次
      final batches = _createUploadBatches(allFiles);
      final totalFiles = allFiles.length;
      int totalSuccess = 0;

      // 上传批次
      final batchResults = await _uploadBatchesConcurrently(
        batches: batches,
        apiUrl: apiUrl,
        project: project,
        type: type,
        value: value,
        onProgress: (completed, total) {
          status = UploadStatus(
            projectId: project.id,
            projectName: project.name,
            uploadCount: status.uploadCount,
            progress: completed / total,
            status: '正在上传: $completed/$total',
            logs: List.from(status.logs),
          );
          status.addLog('已完成批次 $completed/$total');
          _uploadStatuses[project.id] = status;
          notifyListeners();
        }
      );

      // 处理结果
      for (var result in batchResults) {
        if (result.success) {
          totalSuccess += result.filesCount;
        }
      }

      // 更新最终状态
      final isSuccess = totalSuccess == totalFiles;
      status = UploadStatus(
        projectId: project.id,
        projectName: project.name,
        uploadCount: status.uploadCount,
        isComplete: true,
        isSuccess: isSuccess,
        status: '上传完成\n成功: $totalSuccess/$totalFiles张照片',
        logs: List.from(status.logs),
      );
      status.addLog(
        isSuccess ? '上传成功完成' : '部分文件上传失败',
        isError: !isSuccess,
      );

    } catch (e) {
      print('上传过程错误: $e');
      status = UploadStatus(
        projectId: project.id,
        projectName: project.name,
        uploadCount: status.uploadCount,
        isComplete: true,
        isSuccess: false,
        status: '上传失败',
        error: e.toString(),
        logs: List.from(status.logs),
      );
      status.addLog('上传失败: ${e.toString()}', isError: true);
    } finally {
      _uploadStatuses[project.id] = status;
      notifyListeners();
      await _saveUploadStatuses();
    }
  }

  // 预处理文件方法 - 确保收集所有项目和轨迹的照片
  Future<List<Map<String, dynamic>>> _prepareFilesForUpload(Project project) async {
    List<Map<String, dynamic>> allFiles = [];

    // 处理项目照片
    for (var photo in project.photos) {
      if (await photo.exists()) {
        try {
          final bytes = await photo.readAsBytes();
          if (bytes.isNotEmpty) {
            allFiles.add({
              'file': photo,
              'bytes': bytes,
              'type': 'project',
              'path': photo.path,
              'relativePath': path.basename(photo.path)
            });
          }
        } catch (e) {
          print('读取项目照片错误: $e');
        }
      }
    }

    // 处理车辆照片
    for (var vehicle in project.vehicles) {
      // 处理车辆照片
      for (var photo in vehicle.photos) {
        if (await photo.exists()) {
          try {
            final bytes = await photo.readAsBytes();
            if (bytes.isNotEmpty) {
              allFiles.add({
                'file': photo,
                'bytes': bytes,
                'type': 'vehicle',
                'vehicleId': vehicle.id,
                'vehicleName': vehicle.name,
                'path': photo.path,
                'relativePath': 'vehicles/${vehicle.id}/${path.basename(photo.path)}'
              });
            }
          } catch (e) {
            print('读取车辆照片错误: $e');
          }
        }
      }

      // 处理轨迹照片
      for (var track in vehicle.tracks) {
        for (var photo in track.photos) {
          if (await photo.exists()) {
            try {
              final bytes = await photo.readAsBytes();
              if (bytes.isNotEmpty) {
                allFiles.add({
                  'file': photo,
                  'bytes': bytes,
                  'type': 'track',
                  'trackId': track.id,
                  'trackName': track.name,
                  'vehicleId': vehicle.id,
                  'vehicleName': vehicle.name,
                  'path': photo.path,
                  'relativePath': 'vehicles/${vehicle.id}/tracks/${track.id}/${path.basename(photo.path)}'
                });
              }
            } catch (e) {
              print('读取轨迹照片错误: $e');
            }
          }
        }
      }
    }

    return allFiles;
  }

  // 创建上传批次
  List<List<Map<String, dynamic>>> _createUploadBatches(List<Map<String, dynamic>> files) {
    const int batchSize = 5; // 每批5张照片
    final List<List<Map<String, dynamic>>> batches = [];

    for (var i = 0; i < files.length; i += batchSize) {
      final end = (i + batchSize < files.length) ? i + batchSize : files.length;
      batches.add(files.sublist(i, end));
    }

    return batches;
  }

  // 并发上传方法
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
            batchNumber: batchIndex + 1,
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
      print('并发上传错误: $e');
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
    final status = _uploadStatuses[project.id];
    if (status != null) {
      status.addLog('开始上传批次 $batchNumber/$totalBatches');
      _uploadStatuses[project.id] = status;
      notifyListeners();
    }

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    // 添加项目信息和上传类型
    request.fields.addAll({
      'type': type?.name ?? 'unknown',
      'value': value ?? 'unknown',
      'project_info': json.encode(project.toJson()),
      'batch_number': batchNumber.toString(),
      'total_batches': totalBatches.toString(),
    });

    print('正在上传批次 ${batchNumber}/${totalBatches}');

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

      request.fields['file_info_$i'] = json.encode({
        'type': fileInfo['type'],
        'trackId': fileInfo['trackId'] ?? '',
        'trackName': fileInfo['trackName'] ?? '',
        'vehicleId': fileInfo['vehicleId'] ?? '',
        'vehicleName': fileInfo['vehicleName'] ?? '',
        'relativePath': fileInfo['relativePath']
      });
    }

    try {
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        if (status != null) {
          status.addLog('批次 $batchNumber 上传成功');
          _uploadStatuses[project.id] = status;
          notifyListeners();
        }
        return BatchUploadResult(success: true, filesCount: batch.length);
      } else {
        if (status != null) {
          status.addLog('批次 $batchNumber 上传失败: ${response.statusCode}', isError: true);
          _uploadStatuses[project.id] = status;
          notifyListeners();
        }
        return BatchUploadResult(success: false, filesCount: batch.length);
      }
    } catch (e) {
      if (status != null) {
        status.addLog('批次 $batchNumber 上传错误: $e', isError: true);
        _uploadStatuses[project.id] = status;
        notifyListeners();
      }
      return BatchUploadResult(success: false, filesCount: batch.length);
    }
  }

  // 获取指定项目的所有上传日志
  List<UploadLog> getProjectUploadLogs(String projectId) {
    return _uploadStatuses[projectId]?.logs ?? [];
  }

  // 获取项目的上传次数
  int getProjectUploadCount(String projectId) {
    return _uploadStatuses[projectId]?.uploadCount ?? 0;
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