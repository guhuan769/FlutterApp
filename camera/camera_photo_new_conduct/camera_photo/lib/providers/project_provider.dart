// lib/providers/project_provider.dart
import 'dart:convert';
import 'dart:io';
import 'dart:async';
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
  final Map<String, String> _uploadSessions = {};

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
      await uploadProject(project, type: UploadType.model, value: "A");
    }
  }

  // 在 ProjectProvider 类中更新上传方法
  Future<bool> uploadProject(Project project, {UploadType? type, String? value, bool forceNewSession = false}) async {
    if (forceNewSession) {
      _uploadSessions.remove(project.id);
    }
    // 获取或创建上传状态
    UploadStatus status = _uploadStatuses[project.id] ?? UploadStatus(
      projectId: project.id,
      projectName: project.name,
    );

    // 检查是否真的在上传中
    final bool isActuallyUploading = !status.isComplete && 
        status.uploadTime.isAfter(DateTime.now().subtract(Duration(minutes: 1))) &&
        status.progress > 0;

    // 如果确实在上传中且进度大于0，则不要重复上传
    if (isActuallyUploading) {
      // 更新状态以显示给用户
      status = status.copyWith(
        status: '项目正在上传中，请等待当前上传完成\n当前进度: ${(status.progress * 100).toStringAsFixed(1)}%',
      );
      _uploadStatuses[project.id] = status;
      notifyListeners();
      return false;
    }

    // 如果上一次上传失败或超时，重置状态
    if (!status.isComplete || status.uploadTime.isBefore(DateTime.now().subtract(Duration(minutes: 1)))) {
      status = UploadStatus(
        projectId: project.id,
        projectName: project.name,
        uploadCount: status.uploadCount + 1,
        isComplete: false,
        isSuccess: false,
        progress: 0.0,
        status: '准备开始新的上传...',
        logs: [], // 清空之前的日志
      );
      _uploadStatuses[project.id] = status;
      notifyListeners();
    }
    
    // 添加开始上传日志
    status.addLog('开始上传项目 ${project.name}');
    status = status.copyWith(
      status: '正在初始化上传...',
    );
    _uploadStatuses[project.id] = status;
    notifyListeners();

    // 用于跟踪最终上传成功数量
    int finalSuccessCount = 0;

    try {
      // 验证服务器目录结构
      final bool directoriesValid = await ensureServerDirectories(project, type, value);
      if (!directoriesValid) {
        // 如果目录验证失败，尝试重置会话并继续
        _uploadSessions.remove(project.id);
        status.addLog('服务器目录结构验证失败，将尝试重新创建目录', isError: true);
        _uploadStatuses[project.id] = status;
        notifyListeners();
      }

      final prefs = await SharedPreferences.getInstance();
      final apiUrl = prefs.getString('api_url');
      
      if (apiUrl == null || apiUrl.isEmpty) {
        throw Exception('请先在设置中配置服务器地址');
      }

      // 收集文件
      status = status.copyWith(
        status: '正在收集文件...',
      );
      _uploadStatuses[project.id] = status;
      notifyListeners();

      final allFiles = await _prepareFilesForUpload(project);
      if (allFiles.isEmpty) {
        throw Exception('没有可上传的文件');
      }

      status.addLog('找到 ${allFiles.length} 个文件待上传');
      status = status.copyWith(
        status: '准备上传 ${allFiles.length} 张照片\n正在创建上传队列...',
      );
      _uploadStatuses[project.id] = status;
      notifyListeners();

      // 创建批次
      final batches = _createUploadBatches(allFiles);
      final totalFiles = allFiles.length;
      int currentFileIndex = 0;

      // 上传批次
      final batchResults = await _uploadBatchesConcurrently(
        batches: batches,
        apiUrl: '$apiUrl/upload',
        project: project,
        type: type,
        value: value,
        onProgress: (completed, total, serverConfirmed) {
          final progress = completed / total;
          
          // 获取当前正在上传的文件名（如果还有未上传的文件）
          String currentFileName = "未知文件";
          if (completed < total && completed < batches.length) {
            try {
              var nextBatch = batches[completed];
              var nextFile = nextBatch[0];
              currentFileName = path.basename(nextFile['path'] as String);
            } catch (e) {
              // 忽略异常，保持默认文件名
            }
          }
          
          currentFileIndex = completed;
          
          // 构建进度状态文本，包含服务器确认信息
          String progressStatus = '已上传: $completed/$total 个文件, 服务器已确认: $serverConfirmed 个文件';
          
          progressStatus += '\n当前处理: $currentFileName';
          
          status = status.copyWith(
            progress: progress,
            status: progressStatus,
            logs: List.from(status.logs),
          );
          _uploadStatuses[project.id] = status;
          notifyListeners();
        }
      );

      // 处理结果
      int totalSuccess = 0;
      int serverConfirmedSuccess = 0;
      
      for (var result in batchResults) {
        if (result.success) {
          totalSuccess += result.filesCount;
          // 使用服务器确认的文件数
          if (result.serverConfirmedCount != null) {
            serverConfirmedSuccess += result.serverConfirmedCount!;
          }
        }
      }
      
      // 对比本地计数和服务器确认计数
      bool serverCountMismatch = totalSuccess != serverConfirmedSuccess && serverConfirmedSuccess > 0;
      if (serverCountMismatch) {
        status.addLog('警告：本地记录成功上传 $totalSuccess 个文件，但服务器只确认了 $serverConfirmedSuccess 个文件', isError: true);
      }
      
      // 使用服务器确认的数量作为最终成功数
      // 如果服务器确认数大于0，则使用服务器数据，否则使用本地计数
      finalSuccessCount = serverConfirmedSuccess > 0 ? serverConfirmedSuccess : totalSuccess;

      // 更新最终状态
      final isAllSuccess = finalSuccessCount == totalFiles;
      final isPartialSuccess = finalSuccessCount > 0 && finalSuccessCount < totalFiles;
      final successRate = (finalSuccessCount / totalFiles * 100).toStringAsFixed(1);
      final completionTime = DateTime.now().difference(status.uploadTime);
      final timeStr = _formatUploadTime(completionTime);
      
      status = status.copyWith(
        isComplete: true,
        isSuccess: finalSuccessCount > 0, // 只要有文件成功就设置为基本成功
        status: isAllSuccess 
          ? '上传完成！\n成功上传: $finalSuccessCount/$totalFiles 张照片 (${successRate}%)\n总耗时: $timeStr'
          : isPartialSuccess
            ? '部分上传完成\n成功上传: $finalSuccessCount/$totalFiles 张照片 (${successRate}%)\n总耗时: $timeStr'
            : '上传失败\n成功上传: $finalSuccessCount/$totalFiles 张照片 (${successRate}%)\n请检查网络后重试',
        logs: List.from(status.logs),
      );
      
      if (isAllSuccess) {
        status.addLog('上传成功完成，所有文件已上传，总耗时: $timeStr');
        status.addLog('服务器确认保存了 $finalSuccessCount 个文件');
      } else if (isPartialSuccess) {
        status.addLog('部分文件上传成功，总耗时: $timeStr', isError: true);
        status.addLog('成功: $finalSuccessCount, 失败: ${totalFiles - finalSuccessCount}', isError: true);
        if (serverCountMismatch) {
          status.addLog('本地成功上传计数: $totalSuccess, 服务器确认计数: $serverConfirmedSuccess', isError: true);
        }
      } else {
        status.addLog('上传失败，没有文件成功上传，总耗时: $timeStr', isError: true);
      }

    } catch (e) {
      print('上传过程错误: $e');
      status = status.copyWith(
        isComplete: true,
        isSuccess: false,
        status: '上传失败\n错误原因: ${e.toString()}\n请检查网络和服务器设置后重试',
        error: e.toString(),
        logs: List.from(status.logs),
      );
      status.addLog('上传失败: ${e.toString()}', isError: true);
    } finally {
      _uploadStatuses[project.id] = status;
      notifyListeners();
      await _saveUploadStatuses();
      return finalSuccessCount > 0;
    }
  }
  
  // 格式化上传时间的辅助方法
  String _formatUploadTime(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}小时${(duration.inMinutes % 60)}分钟';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分${(duration.inSeconds % 60)}秒';
    } else {
      return '${duration.inSeconds}秒';
    }
  }

  // 预处理文件方法 - 确保收集所有项目和轨迹的照片
  Future<List<Map<String, dynamic>>> _prepareFilesForUpload(Project project) async {
    List<Map<String, dynamic>> allFiles = [];
    // 添加用于跟踪已处理文件的集合，避免重复添加相同文件
    Set<String> processedPaths = {};

    // 预先打印调试信息
    print('开始收集项目 ${project.id} (${project.name}) 的文件');
    print('项目照片数: ${project.photos.length}');
    int vehicleCount = 0;
    int trackCount = 0;
    int vehiclePhotoCount = 0;
    int trackPhotoCount = 0;
    
    for (var vehicle in project.vehicles) {
      vehicleCount++;
      vehiclePhotoCount += vehicle.photos.length;
      for (var track in vehicle.tracks) {
        trackCount++;
        trackPhotoCount += track.photos.length;
      }
    }
    
    print('车辆数: $vehicleCount, 车辆照片: $vehiclePhotoCount');
    print('轨迹数: $trackCount, 轨迹照片: $trackPhotoCount');

    // 处理项目照片
    int validProjectPhotos = 0;
    for (var photo in project.photos) {
      String photoPath = photo.path;
      // 避免重复处理相同路径的文件
      if (processedPaths.contains(photoPath)) {
        print('跳过重复的项目照片: $photoPath');
        continue;
      }
      
      if (await photo.exists()) {
        try {
          final bytes = await photo.readAsBytes();
          if (bytes.isNotEmpty) {
            allFiles.add({
              'file': photo,
              'bytes': bytes,
              'type': 'project',
              'path': photoPath,
              'relativePath': path.basename(photoPath)
            });
            processedPaths.add(photoPath);
            validProjectPhotos++;
          } else {
            print('项目照片数据为空: $photoPath');
          }
        } catch (e) {
          print('读取项目照片错误: $photoPath, 错误: $e');
        }
      } else {
        print('项目照片文件不存在: $photoPath');
      }
    }
    print('有效项目照片数: $validProjectPhotos');

    // 处理车辆照片
    int validVehiclePhotos = 0;
    for (var vehicle in project.vehicles) {
      // 处理车辆照片
      for (var photo in vehicle.photos) {
        String photoPath = photo.path;
        // 避免重复处理相同路径的文件
        if (processedPaths.contains(photoPath)) {
          print('跳过重复的车辆照片: $photoPath');
          continue;
        }
        
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
                'path': photoPath,
                'relativePath': 'vehicles/${vehicle.id}/${path.basename(photoPath)}'
              });
              processedPaths.add(photoPath);
              validVehiclePhotos++;
            } else {
              print('车辆照片数据为空: $photoPath');
            }
          } catch (e) {
            print('读取车辆照片错误: $photoPath, 错误: $e');
          }
        } else {
          print('车辆照片文件不存在: $photoPath');
        }
      }

      // 处理轨迹照片
      int validTrackPhotos = 0;
      for (var track in vehicle.tracks) {
        for (var photo in track.photos) {
          String photoPath = photo.path;
          // 避免重复处理相同路径的文件
          if (processedPaths.contains(photoPath)) {
            print('跳过重复的轨迹照片: $photoPath');
            continue;
          }
          
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
                  'path': photoPath,
                  'relativePath': 'vehicles/${vehicle.id}/tracks/${track.id}/${path.basename(photoPath)}'
                });
                processedPaths.add(photoPath);
                validTrackPhotos++;
              } else {
                print('轨迹照片数据为空: $photoPath');
              }
            } catch (e) {
              print('读取轨迹照片错误: $photoPath, 错误: $e');
            }
          } else {
            print('轨迹照片文件不存在: $photoPath');
          }
        }
      }
      print('车辆 ${vehicle.name} 有效轨迹照片数: $validTrackPhotos');
    }
    print('有效车辆照片数: $validVehiclePhotos');
    print('总计有效文件数: ${allFiles.length}');

    return allFiles;
  }

  // 创建上传批次 - 改为每个文件一个批次
  List<List<Map<String, dynamic>>> _createUploadBatches(List<Map<String, dynamic>> files) {
    // 每个文件作为一个独立批次，避免批量上传导致的重复问题
    final List<List<Map<String, dynamic>>> batches = [];

    for (var file in files) {
      batches.add([file]);  // 每个文件单独一个批次
    }

    return batches;
  }

  // 并发上传方法 - 修改为顺序执行
  Future<List<BatchUploadResult>> _uploadBatchesConcurrently({
    required List<List<Map<String, dynamic>>> batches,
    required String apiUrl,
    required Project project,
    required UploadType? type,
    required String? value,
    required void Function(int completed, int total, int serverConfirmed) onProgress,
  }) async {
    final results = <BatchUploadResult>[];
    final total = batches.length;
    var completed = 0;
    var serverConfirmedFiles = 0;
    var sessionResetAttempts = 0;
    const maxSessionResets = 3;
    var retryDelay = const Duration(seconds: 2);

    // 顺序上传每个批次
    for (int i = 0; i < batches.length; i++) {
      final batch = batches[i];
      final batchNumber = i + 1;
      
      try {
        var result = await _uploadBatch(
          batch: batch,
          batchNumber: batchNumber,
          totalBatches: batches.length,
          apiUrl: apiUrl,
          project: project,
          type: type,
          value: value,
        );
        
        // 检查是否需要重置会话
        if (result.errorType == 'session_reset_required' && sessionResetAttempts < maxSessionResets) {
          sessionResetAttempts++;
          
          // 重置会话状态
          _uploadSessions.remove(project.id);
          
          final status = _uploadStatuses[project.id];
          if (status != null) {
            status.addLog('服务器目录不存在，重置会话并重试 (第 $sessionResetAttempts 次)', isError: true);
            _uploadStatuses[project.id] = status;
            notifyListeners();
          }
          
          // 检查并确保目录存在
          await ensureServerDirectories(project, type, value);
          
          // 等待后重试当前批次
          await Future.delayed(retryDelay * sessionResetAttempts);
          
          // 再次尝试上传
          result = await _uploadBatch(
            batch: batch,
            batchNumber: batchNumber,
            totalBatches: batches.length,
            apiUrl: apiUrl,
            project: project,
            type: type,
            value: value,
            retryCount: sessionResetAttempts,
          );
          
          // 如果仍然失败，跳过这个文件
          if (!result.success) {
            final status = _uploadStatuses[project.id];
            if (status != null) {
              status.addLog('重试后仍然失败，跳过该文件', isError: true);
              _uploadStatuses[project.id] = status;
              notifyListeners();
            }
            
            completed++;
            results.add(result);
            onProgress(completed, total, serverConfirmedFiles);
            continue;
          }
        }
        
        completed++;
        results.add(result);
        
        if (result.success && result.serverConfirmedCount != null && result.serverConfirmedCount! > 0) {
          serverConfirmedFiles += result.serverConfirmedCount!;
        }
        
        final status = _uploadStatuses[project.id];
        if (status != null) {
          status.addLog('${path.basename(batch[0]['path'] as String)} - 上传${result.success ? '成功' : '失败'}${result.success ? " (服务器已确认)" : ""}');
          
          if (completed % 5 == 0 || completed == total) {
            status.addLog('当前进度: $completed/$total 个文件, 服务器已确认: $serverConfirmedFiles 个文件');
          }
          
          _uploadStatuses[project.id] = status;
          notifyListeners();
        }
        
        onProgress(completed, total, serverConfirmedFiles);
      } catch (e) {
        print('上传批次 $batchNumber 错误: $e');
        completed++;
        results.add(BatchUploadResult(success: false, filesCount: 0));
        onProgress(completed, total, serverConfirmedFiles);
      }
    }

    return results;
  }
  
  // 上传批次方法 - 改进错误处理和响应验证
  Future<BatchUploadResult> _uploadBatch({
    required List<Map<String, dynamic>> batch,
    required int batchNumber,
    required int totalBatches,
    required String apiUrl,
    required Project project,
    required UploadType? type,
    required String? value,
    int retryCount = 0,
  }) async {
    final status = _uploadStatuses[project.id];
    if (status != null) {
      status.addLog('正在上传第 $batchNumber/$totalBatches 张图片${retryCount > 0 ? "（重试第 $retryCount 次）" : ""}');
      _uploadStatuses[project.id] = status;
      notifyListeners();
    }

    // 增加最大重试次数和延迟
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 3);
    int currentRetry = retryCount;
    
    // 验证文件是否存在且可读
    if (batch.isEmpty) {
      if (status != null) {
        status.addLog('批次 $batchNumber 没有文件数据', isError: true);
        _uploadStatuses[project.id] = status;
        notifyListeners();
      }
      return BatchUploadResult(success: false, filesCount: 0, errorType: 'empty_batch');
    }
    
    final fileInfo = batch[0];
    final filePath = fileInfo['path'] as String;
    final file = File(filePath);
    final fileName = path.basename(filePath);
    
    if (!await file.exists()) {
      if (status != null) {
        status.addLog('文件不存在: $fileName, 将跳过此文件', isError: true);
        _uploadStatuses[project.id] = status;
        notifyListeners();
      }
      return BatchUploadResult(success: false, filesCount: 0, errorType: 'file_not_exist');
    }
    
    Uint8List? fileBytes;
    try {
      fileBytes = await file.readAsBytes();
      if (fileBytes.isEmpty) {
        throw Exception('文件内容为空');
      }
      
      final fileSizeKB = (fileBytes.length / 1024).toStringAsFixed(2);
      if (status != null) {
        status.addLog('文件验证成功: $fileName (${fileSizeKB}KB)');
        _uploadStatuses[project.id] = status;
        notifyListeners();
      }
    } catch (e) {
      print('文件验证失败: $filePath, 错误: $e');
      if (status != null) {
        status.addLog('文件验证失败: $fileName, 错误原因: $e', isError: true);
        _uploadStatuses[project.id] = status;
        notifyListeners();
      }
      return BatchUploadResult(success: false, filesCount: 0, errorType: 'file_read_error');
    }

    // 重试循环
    List<String> errorMessages = [];
    String lastResponseData = '';
    
    while (currentRetry <= maxRetries) {
      if (status != null) {
        if (currentRetry > 0) {
          status.addLog('重试上传: $fileName (第 $currentRetry/${maxRetries} 次重试)');
        } else {
          status.addLog('开始上传: $fileName');
        }
        _uploadStatuses[project.id] = status;
        notifyListeners();
      }
      
      try {
        var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
        
        // 添加项目信息和上传类型
        Map<String, String> requestFields = {
          'type': type?.name ?? 'unknown',
          'value': value ?? 'unknown',
          'project_info': json.encode(project.toJson()),
          'batch_number': batchNumber.toString(),
          'total_batches': totalBatches.toString(),
          'retry_count': currentRetry.toString(),
        };
        
        request.fields.addAll(requestFields);
        
        // 添加文件
        request.files.add(
          http.MultipartFile.fromBytes(
            'files[]',
            fileBytes!,
            filename: fileName,
            contentType: MediaType('image', 'jpeg')
          )
        );
        
        // 添加文件信息
        request.fields['file_info_0'] = json.encode({
          'type': fileInfo['type'],
          'trackId': fileInfo['trackId'] ?? '',
          'trackName': fileInfo['trackName'] ?? '',
          'vehicleId': fileInfo['vehicleId'] ?? '',
          'vehicleName': fileInfo['vehicleName'] ?? '',
          'relativePath': fileInfo['relativePath']
        });
        
        // 添加文件唯一标识
        for (int i = 0; i < batch.length; i++) {
          final fileInfo = batch[i];
          final filePath = fileInfo['path'] as String;
          final uniqueId = '$filePath-${DateTime.now().millisecondsSinceEpoch}-$i';
          request.fields['file_unique_id_$i'] = uniqueId;
        }
        
        // 添加会话ID
        if (_uploadSessions.containsKey(project.id)) {
          request.fields['session_id'] = _uploadSessions[project.id]!;
        }
        
        // 发送请求
        var response = await request.send().timeout(Duration(seconds: 60));
        var responseData = await response.stream.bytesToString();
        
        if (response.statusCode == 200) {
          try {
            var responseJson = json.decode(responseData);
            
            // 成功响应处理
            if (responseJson['code'] == 200) {
              // 保存会话ID
              if (responseJson.containsKey('session_id') && responseJson['session_id'] != null) {
                _uploadSessions[project.id] = responseJson['session_id'];
              }
              
              if (status != null) {
                status.addLog('上传成功: $fileName');
                _uploadStatuses[project.id] = status;
                notifyListeners();
              }
              
              // 获取服务器确认数量
              int serverConfirmedCount = 0;
              if (responseJson.containsKey('server_confirmed_count') && 
                  responseJson['server_confirmed_count'] != null) {
                serverConfirmedCount = int.tryParse(responseJson['server_confirmed_count'].toString()) ?? 0;
              }
              
              return BatchUploadResult(
                success: true,
                filesCount: 1,
                serverConfirmedCount: serverConfirmedCount
              );
            } else {
              // 服务器返回错误码
              var errorMessage = '服务器错误: ${responseJson['message'] ?? "未知错误"}';
              errorMessages.add(errorMessage);
              
              if (status != null) {
                status.addLog('上传失败: $fileName - $errorMessage', isError: true);
                _uploadStatuses[project.id] = status;
                notifyListeners();
              }
              
              currentRetry++;
              if (currentRetry <= maxRetries) {
                await Future.delayed(retryDelay);
                continue;
              }
              
              return BatchUploadResult(
                success: false,
                filesCount: 0,
                errorMessage: errorMessage
              );
            }
          } catch (e) {
            // JSON解析错误
            String parseError = '无法解析服务器响应: $e';
            errorMessages.add(parseError);
            
            if (status != null) {
              status.addLog('上传返回数据异常: $fileName ($parseError)', isError: true);
              var responseSummary = responseData.length > 100 ? '${responseData.substring(0, 100)}...' : responseData;
              status.addLog('服务器响应: $responseSummary', isError: true);
              _uploadStatuses[project.id] = status;
              notifyListeners();
            }
            
            currentRetry++;
            if (currentRetry <= maxRetries) {
              await Future.delayed(retryDelay);
              continue;
            }
            
            return BatchUploadResult(
              success: false,
              filesCount: 0,
              errorType: 'parse_error',
              errorMessage: parseError
            );
          }
        } else {
          // 非200状态码
          String errorMessage = '服务器返回状态码: ${response.statusCode}';
          
          try {
            var errorData = json.decode(responseData);
            if (errorData.containsKey('message')) {
              errorMessage += ' - ${errorData['message']}';
            }
            
            // 检查特殊的会话目录不存在错误
            if (response.statusCode == 410 && errorData.containsKey('error') && 
                errorData['error'] == 'SESSION_DIRECTORY_NOT_FOUND') {
              
              // 重置会话ID
              _uploadSessions.remove(project.id);
              
              if (status != null) {
                status.addLog('服务器目录已被删除，需要重置会话', isError: true);
                if (errorData.containsKey('message')) {
                  status.addLog('服务器消息: ${errorData['message']}', isError: true);
                }
                _uploadStatuses[project.id] = status;
                notifyListeners();
              }
              
              // 返回特殊错误类型，触发会话重置流程
              return BatchUploadResult(
                success: false,
                filesCount: 0,
                statusCode: 410,
                errorType: 'session_reset_required',
                errorMessage: errorData['message'] ?? '服务器目录不存在，需要重新上传'
              );
            }
          } catch (e) {
            // 解析错误，记录原始响应
            if (status != null) {
              status.addLog('解析错误响应失败: $e', isError: true);
              status.addLog('原始响应: $responseData', isError: true);
              _uploadStatuses[project.id] = status;
              notifyListeners();
            }
          }
          
          errorMessages.add(errorMessage);
          
          if (status != null) {
            status.addLog('$errorMessage, 文件: $fileName', isError: true);
            _uploadStatuses[project.id] = status;
            notifyListeners();
          }
          
          currentRetry++;
          if (currentRetry <= maxRetries) {
            await Future.delayed(retryDelay);
            continue;
          }
          
          return BatchUploadResult(
            success: false,
            filesCount: 0,
            statusCode: response.statusCode,
            errorMessage: errorMessages.join('; ')
          );
        }
      } catch (e) {
        // 网络错误等
        String errorMessage = '上传请求错误: $e';
        errorMessages.add(errorMessage);
        
        if (status != null) {
          status.addLog('$errorMessage, 文件: $fileName', isError: true);
          _uploadStatuses[project.id] = status;
          notifyListeners();
        }
        
        currentRetry++;
        if (currentRetry <= maxRetries) {
          await Future.delayed(retryDelay);
          continue;
        }
        
        return BatchUploadResult(
          success: false,
          filesCount: 0,
          errorType: 'network_error',
          errorMessage: errorMessage
        );
      }
    }
    
    // 不应该到达这里，但以防万一
    return BatchUploadResult(
      success: false,
      filesCount: 0,
      errorType: 'unknown_error',
      errorMessage: '未知错误: 超过重试次数'
    );
  }

  // 获取指定项目的所有上传日志
  List<UploadLog> getProjectUploadLogs(String projectId) {
    return _uploadStatuses[projectId]?.logs ?? [];
  }

  // 获取项目的上传次数
  int getProjectUploadCount(String projectId) {
    return _uploadStatuses[projectId]?.uploadCount ?? 0;
  }

  // 在发现服务器目录不存在时，清除会话ID
  void resetUploadSession(String projectId) {
    _uploadSessions.remove(projectId);
    notifyListeners();
  }

  Future<bool> ensureServerDirectories(Project project, UploadType? type, String? value) async {
    final status = _uploadStatuses[project.id];
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiUrl = prefs.getString('api_url');
      
      if (apiUrl == null || apiUrl.isEmpty) {
        throw Exception('请先在设置中配置服务器地址');
      }
      
      final uploadType = type?.name ?? 'unknown';
      final uploadValue = value ?? 'unknown';
      
      if (status != null) {
        status.addLog('检查服务器目录结构...');
        _uploadStatuses[project.id] = status;
        notifyListeners();
      }
      
      final response = await http.get(
        Uri.parse('$apiUrl/check-directory?type=$uploadType&value=$uploadValue&project=${Uri.encodeComponent(project.name)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        // 记录详细日志
        if (status != null) {
          if (result['directory_exists'] == true) {
            status.addLog('服务器目录结构已存在');
            
            // 检查写入权限
            if (result['has_write_permission'] == true) {
              status.addLog('服务器目录具有写入权限');
            } else {
              status.addLog('警告: 服务器目录可能没有写入权限', isError: true);
            }
          } else if (result['directory_created'] == true) {
            status.addLog('服务器目录结构已自动创建');
          } else {
            status.addLog('服务器目录结构检查失败: ${result['message'] ?? "未知原因"}', isError: true);
          }
          
          _uploadStatuses[project.id] = status;
          notifyListeners();
        }
        
        // 无论是已存在还是新创建，只要目录结构成功创建就返回true
        return result['directory_exists'] == true || result['directory_created'] == true;
      } else {
        if (status != null) {
          status.addLog('服务器目录检查请求失败: HTTP ${response.statusCode}', isError: true);
          try {
            final errorData = json.decode(response.body);
            status.addLog('错误信息: ${errorData['message'] ?? "未知错误"}', isError: true);
          } catch (e) {
            // 解析失败，忽略
          }
          _uploadStatuses[project.id] = status;
          notifyListeners();
        }
        return false;
      }
    } catch (e) {
      if (status != null) {
        status.addLog('服务器目录检查异常: $e', isError: true);
        _uploadStatuses[project.id] = status;
        notifyListeners();
      }
      print('检查服务器目录异常: $e');
      return false;
    }
  }
}

// 批次上传结果类
class BatchUploadResult {
  final bool success;
  final int filesCount;
  final int? statusCode;
  final String? errorType;
  final String? errorMessage;
  final int? serverConfirmedCount; // 新增：服务器确认的文件数

  BatchUploadResult({
    required this.success,
    required this.filesCount,
    this.statusCode,
    this.errorType,
    this.errorMessage,
    this.serverConfirmedCount,
  });
}