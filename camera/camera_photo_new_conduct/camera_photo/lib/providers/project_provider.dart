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
      return;
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

    try {
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
      int totalSuccess = 0;
      int currentFileIndex = 0;
      
      // 上传批次前记录开始时间
      final uploadStartTime = DateTime.now();

      // 上传批次
      final batchResults = await _uploadBatchesConcurrently(
        batches: batches,
        apiUrl: '$apiUrl/upload',
        project: project,
        type: type,
        value: value,
        onProgress: (completed, total) {
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
          status = status.copyWith(
            progress: progress,
            status: '已上传: $completed/$total 张图片 (${(progress * 100).toStringAsFixed(1)}%)\n当前处理: $currentFileName',
            logs: List.from(status.logs),
          );
          _uploadStatuses[project.id] = status;
          notifyListeners();
        }
      );

      // 处理结果
      int failedCount = 0;
      int transferErrorCount = 0;
      int processingErrorCount = 0;
      
      for (var result in batchResults) {
        if (result.success) {
          totalSuccess++;
        } else {
          failedCount++;
          
          // 统计不同类型的错误
          if (result.statusCode != null) {
            // 服务器响应错误（例如4xx或5xx状态码）
            processingErrorCount++;
          } else {
            // 网络传输或其他错误
            transferErrorCount++;
          }
        }
      }

      // 更新最终状态
      // 当所有文件都成功上传时才显示为完全成功，否则显示为部分成功
      final isAllSuccess = totalSuccess == totalFiles;
      final isPartialSuccess = totalSuccess > 0 && totalSuccess < totalFiles;
      final successRate = totalFiles > 0 ? (totalSuccess / totalFiles * 100).toStringAsFixed(1) : "0.0";
      final completionTime = DateTime.now().difference(uploadStartTime);
      final timeStr = _formatUploadTime(completionTime);
      
      // 准备详细状态信息
      List<String> statusLines = [];
      
      if (isAllSuccess) {
        statusLines.add('上传完成！');
      } else if (isPartialSuccess) {
        statusLines.add('部分上传完成');
      } else {
        statusLines.add('上传失败');
      }
      
      // 添加成功率信息
      statusLines.add('成功上传: $totalSuccess/$totalFiles 张照片 (${successRate}%)');
      
      // 添加失败原因统计（如果有失败）
      if (failedCount > 0) {
        String failureDetails = '';
        if (transferErrorCount > 0) {
          failureDetails += '网络传输错误: $transferErrorCount 张, ';
        }
        if (processingErrorCount > 0) {
          failureDetails += '服务器处理错误: $processingErrorCount 张';
        }
        
        if (failureDetails.isNotEmpty) {
          status.addLog('失败详情: $failureDetails', isError: true);
        }
      }
      
      // 添加总耗时
      statusLines.add('总耗时: $timeStr');
      
      // 如果全部失败，添加重试建议
      if (!isAllSuccess && !isPartialSuccess) {
        statusLines.add('请检查网络和服务器设置后重试');
      }
      
      // 更新状态对象
      status = status.copyWith(
        isComplete: true,
        isSuccess: totalSuccess > 0, // 只要有文件成功就设置为基本成功
        status: statusLines.join('\n'),
        logs: List.from(status.logs),
      );
      
      // 添加总结日志
      if (isAllSuccess) {
        status.addLog('上传成功完成，所有 $totalFiles 个文件已上传，总耗时: $timeStr');
      } else if (isPartialSuccess) {
        status.addLog('部分文件上传成功，总耗时: $timeStr', isError: true);
        status.addLog('成功: $totalSuccess, 失败: ${totalFiles - totalSuccess}, 成功率: ${successRate}%', isError: true);
        
        // 建议尝试仅上传失败的文件
        status.addLog('建议: 可以尝试仅上传失败的文件', isError: false);
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

  // 并发上传方法 - 修改为顺序执行并增加失败重试处理
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

    // 记录上传开始时间
    final uploadStartTime = DateTime.now();
    
    // 添加整体进度信息
    final status = _uploadStatuses[project.id];
    if (status != null) {
      status.addLog('开始上传所有文件 (共 $total 个文件)');
      _uploadStatuses[project.id] = status;
      notifyListeners();
    }

    // 处理连续失败计数，用于中断上传
    int consecutiveFailures = 0;
    const int maxConsecutiveFailures = 3; // 连续失败3次后暂停一段时间

    // 顺序上传每个批次（每个批次只有一个文件）
    for (int i = 0; i < batches.length; i++) {
      final batch = batches[i];
      final batchNumber = i + 1;
      
      // 如果连续失败次数达到阈值，暂停一段时间
      if (consecutiveFailures >= maxConsecutiveFailures) {
        if (status != null) {
          status.addLog('检测到连续 $consecutiveFailures 次失败，暂停上传 30 秒后继续...', isError: true);
          _uploadStatuses[project.id] = status;
          notifyListeners();
        }
        await Future.delayed(const Duration(seconds: 30)); // 较长暂停
        consecutiveFailures = 0; // 重置计数器
      }
      
      try {
        final result = await _uploadBatch(
          batch: batch,
          batchNumber: batchNumber,
          totalBatches: batches.length,
          apiUrl: apiUrl,
          project: project,
          type: type,
          value: value,
        );
        
        completed++;
        results.add(result);
        
        // 更新连续失败计数器
        if (!result.success) {
          consecutiveFailures++;
        } else {
          consecutiveFailures = 0; // 成功则重置计数器
        }
        
        // 通知进度更新
        onProgress(completed, total);
        
        // 计算剩余时间估计
        if (status != null && completed > 0 && completed < total) {
          final elapsedSeconds = DateTime.now().difference(uploadStartTime).inSeconds;
          final estimatedTotalSeconds = (elapsedSeconds / completed) * total;
          final remainingSeconds = estimatedTotalSeconds - elapsedSeconds;
          
          if (remainingSeconds > 0) {
            String remainingTimeStr = '';
            if (remainingSeconds > 60) {
              remainingTimeStr = '约 ${(remainingSeconds / 60).ceil()} 分钟';
            } else {
              remainingTimeStr = '约 ${remainingSeconds.ceil()} 秒';
            }
            
            status.addLog('已完成: $completed/$total, 预计剩余时间: $remainingTimeStr');
            _uploadStatuses[project.id] = status;
            notifyListeners();
          }
        }
      } catch (e) {
        print('上传批次 $batchNumber 错误: $e');
        
        if (status != null) {
          status.addLog('上传批次 $batchNumber 发生异常: $e', isError: true);
          _uploadStatuses[project.id] = status;
          notifyListeners();
        }
        
        completed++;
        results.add(BatchUploadResult(success: false, filesCount: 0));
        consecutiveFailures++; // 增加连续失败计数
        
        onProgress(completed, total);
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
  }) async {
    final status = _uploadStatuses[project.id];
    if (status != null) {
      status.addLog('正在上传第 $batchNumber/$totalBatches 张图片');
      _uploadStatuses[project.id] = status;
      notifyListeners();
    }

    // 使用配置项
    const int maxRetries = UploadOptions.maxRetries;
    const Duration retryDelay = UploadOptions.retryDelay;
    int retryCount = 0;
    
    // 在上传前验证文件是否仍然存在且可读取
    if (batch.isEmpty) {
      if (status != null) {
        status.addLog('批次 $batchNumber 没有文件数据', isError: true);
        _uploadStatuses[project.id] = status;
        notifyListeners();
      }
      return BatchUploadResult(success: false, filesCount: 0);
    }
    
    final fileInfo = batch[0]; // 只处理每批次的第一个文件
    final filePath = fileInfo['path'] as String;
    final file = File(filePath);
    final fileName = path.basename(filePath);
    
    // 更严格地验证文件是否存在且可访问
    if (!await file.exists()) {
      if (status != null) {
        status.addLog('文件不存在: $fileName, 将跳过此文件', isError: true);
        _uploadStatuses[project.id] = status;
        notifyListeners();
      }
      return BatchUploadResult(success: false, filesCount: 0);
    }
    
    Uint8List? fileBytes;
    try {
      // 尝试读取文件以确保文件可访问
      fileBytes = await file.readAsBytes();
      if (fileBytes.isEmpty) {
        throw Exception('文件内容为空');
      }
      
      // 记录文件大小，帮助诊断
      final fileSizeKB = (fileBytes.length / 1024).toStringAsFixed(2);
      if (status != null) {
        status.addLog('文件验证成功: $fileName (${fileSizeKB}KB)');
        _uploadStatuses[project.id] = status;
        notifyListeners();
      }
    } catch (e) {
      print('文件验证失败: $filePath, 错误: $e');
      if (status != null) {
        status.addLog('文件验证失败: $fileName, 将跳过此文件', isError: true);
        _uploadStatuses[project.id] = status;
        notifyListeners();
      }
      return BatchUploadResult(success: false, filesCount: 0);
    }

    // 重试循环
    while (retryCount <= maxRetries) {
      if (status != null) {
        if (retryCount > 0) {
          status.addLog('重试上传: $fileName (第 $retryCount 次重试)');
        } else {
          status.addLog('开始上传: $fileName');
        }
        _uploadStatuses[project.id] = status;
        notifyListeners();
      }
      
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // 添加项目信息和上传类型
      Map<String, String> requestFields = {
        'type': type?.name ?? 'unknown',
        'value': value ?? 'unknown',
        'project_info': json.encode(project.toJson()),
        'batch_number': batchNumber.toString(),
        'total_batches': totalBatches.toString(),
      };
      
      request.fields.addAll(requestFields);

      // 添加单个文件
      request.files.add(
        http.MultipartFile.fromBytes(
          'files[]',
          fileBytes!,
          filename: fileName,
          contentType: MediaType('image', 'jpeg')
        )
      );

      request.fields['file_info_0'] = json.encode({
        'type': fileInfo['type'],
        'trackId': fileInfo['trackId'] ?? '',
        'trackName': fileInfo['trackName'] ?? '',
        'vehicleId': fileInfo['vehicleId'] ?? '',
        'vehicleName': fileInfo['vehicleName'] ?? '',
        'relativePath': fileInfo['relativePath']
      });

      try {
        // 设置超时时间防止长时间阻塞
        final startTime = DateTime.now();
        final responseStream = await request.send().timeout(
          const Duration(seconds: 90), // 增加超时时间
          onTimeout: () {
            throw TimeoutException('上传超时，请检查网络连接');
          },
        );
        
        final response = responseStream;
        final responseData = await response.stream.bytesToString();
        final endTime = DateTime.now();
        final uploadDuration = endTime.difference(startTime);
        
        if (response.statusCode == 200) {
          // 解析响应数据，确认服务器确实保存了文件
          Map<String, dynamic> responseJson;
          try {
            responseJson = json.decode(responseData);
            int savedFiles = responseJson['saved_files'] ?? 0;
            String successRate = responseJson['success_rate'] ?? '';
            
            // 验证上传成功
            if (savedFiles > 0) {
              if (status != null) {
                String successMessage = '上传成功: $fileName (耗时: ${uploadDuration.inSeconds}秒)';
                if (successRate.isNotEmpty) {
                  successMessage += ' ($successRate)';
                }
                status.addLog(successMessage);
                _uploadStatuses[project.id] = status;
                notifyListeners();
              }
              return BatchUploadResult(success: true, filesCount: 1);
            } else {
              // 如果服务器报告没有保存文件，且还有重试机会
              if (retryCount < maxRetries) {
                retryCount++;
                if (status != null) {
                  status.addLog('服务器未确认接收文件，准备重试: $fileName', isError: false);
                  _uploadStatuses[project.id] = status;
                  notifyListeners();
                }
                await Future.delayed(retryDelay); // 延迟后重试
                continue;
              } else {
                // 已达到最大重试次数，报告失败
                if (status != null) {
                  status.addLog('上传失败: $fileName - 服务器未保存文件', isError: true);
                  _uploadStatuses[project.id] = status;
                  notifyListeners();
                }
                return BatchUploadResult(success: false, filesCount: 0);
              }
            }
          } catch (e) {
            // 无法解析JSON响应但状态码为200
            if (status != null) {
              status.addLog('上传返回数据异常: $fileName (响应格式异常: $e)', isError: true);
              // 保存响应数据用于调试
              status.addLog('服务器响应: ${responseData.substring(0, responseData.length < 100 ? responseData.length : 100)}...', isError: true);
              _uploadStatuses[project.id] = status;
              notifyListeners();
            }
            
            // 如果仍有重试机会
            if (retryCount < maxRetries) {
              retryCount++;
              await Future.delayed(retryDelay);
              continue;
            } else {
              // 解析JSON失败但状态码为200，检查是否包含"success"关键词保守判断
              if (responseData.toLowerCase().contains('success') || 
                  responseData.toLowerCase().contains('保存成功')) {
                if (status != null) {
                  status.addLog('服务器返回成功标识，视为上传成功: $fileName', isError: false);
                  _uploadStatuses[project.id] = status;
                  notifyListeners();
                }
                return BatchUploadResult(success: true, filesCount: 1);
              } else {
                // 无法确认是否成功，保守地视为失败
                if (status != null) {
                  status.addLog('无法确认服务器处理结果，视为上传失败: $fileName', isError: true);
                  _uploadStatuses[project.id] = status;
                  notifyListeners();
                }
                return BatchUploadResult(success: false, filesCount: 0);
              }
            }
          }
        } else {
          // 服务器返回非200状态码
          String errorMessage = '服务器返回状态码: ${response.statusCode}';
          try {
            // 尝试解析服务器返回的错误信息
            final errorData = json.decode(responseData);
            if (errorData.containsKey('message')) {
              errorMessage += ' - ${errorData['message']}';
            }
          } catch (e) {
            // 忽略解析错误
          }
          
          if (status != null) {
            status.addLog('$errorMessage, 文件: $fileName', isError: true);
            _uploadStatuses[project.id] = status;
            notifyListeners();
          }
          
          if (retryCount < maxRetries) {
            retryCount++;
            await Future.delayed(retryDelay); // 延迟后重试
            continue;
          }
              
          return BatchUploadResult(
            success: false, 
            filesCount: 0,
            statusCode: response.statusCode
          );
        }
      } catch (e) {
        // 网络或其他错误，如果还有重试机会则重试
        if (retryCount < maxRetries) {
          retryCount++;
          if (status != null) {
            status.addLog('上传出错: $fileName - $e，准备重试...', isError: false);
            _uploadStatuses[project.id] = status;
            notifyListeners();
          }
          await Future.delayed(retryDelay); // 延迟后重试
          continue;
        }
        
        if (status != null) {
          status.addLog('上传失败: $fileName - $e (已重试 $retryCount 次)', isError: true);
          _uploadStatuses[project.id] = status;
          notifyListeners();
        }
        return BatchUploadResult(success: false, filesCount: 0);
      }
    }
    
    // 不应该到达这里，但为了安全返回失败
    return BatchUploadResult(success: false, filesCount: 0);
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
  final int? statusCode;

  BatchUploadResult({
    required this.success,
    required this.filesCount,
    this.statusCode,
  });
}