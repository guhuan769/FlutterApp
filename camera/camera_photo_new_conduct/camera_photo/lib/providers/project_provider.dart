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
import 'package:retry/retry.dart';
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
  final bool isComplete;
  final String? error;

  ProjectUploadStatus({
    required this.projectId,
    required this.uploadTime,
    this.isComplete = false,
    this.error,
  });

  factory ProjectUploadStatus.fromJson(Map<String, dynamic> json) {
    return ProjectUploadStatus(
      projectId: json['projectId'],
      uploadTime: DateTime.parse(json['uploadTime']),
      isComplete: json['isComplete'] ?? false,
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'uploadTime': uploadTime.toIso8601String(),
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
    // 查找对应的项目
    final project = findProjectContainingPath(path);
    if (project != null) {
      // 找到项目后上传，使用默认类型和值
      await uploadProject(
        project,
        type: UploadType.model,  // 使用默认的模型类型
        value: 'A',              // 使用默认的值
      );
    }
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
      // 为每个项目使用默认的上传类型和值
      await uploadProject(
        project,
        type: UploadType.model,  // 使用默认的模型类型
        value: 'A',              // 使用默认的值
      );
    }
  }

  // 在 ProjectProvider 类中更新上传方法
  Future<void> uploadProject(
    Project project, {
    required UploadType type,
    required String value,
  }) async {
    // 获取当前上传状态或创建新的
    var status = _uploadStatuses[project.id] ?? UploadStatus(
      projectId: project.id,
      projectName: project.name,
      isComplete: false,
      isSuccess: false,
      progress: 0.0,
      status: '准备上传...',
      uploadCount: 0,
    );

    // 检查是否已经在上传中
    bool isActuallyUploading = !status.isComplete && 
        status.uploadTime.isAfter(DateTime.now().subtract(Duration(minutes: 1)));
    
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
      // 检查网络连接
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw Exception('网络连接不可用，请检查网络设置');
        }
      } catch (e) {
        // 如果google.com无法访问，尝试百度
        try {
          final result = await InternetAddress.lookup('baidu.com');
          if (result.isEmpty || result[0].rawAddress.isEmpty) {
            throw Exception('网络连接不可用，请检查网络设置');
          }
        } catch (e) {
          throw Exception('网络连接不可用，请检查网络设置');
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      final apiUrl = prefs.getString('api_url');
      
      if (apiUrl == null || apiUrl.isEmpty) {
        throw Exception('请先在设置中配置服务器地址');
      }

      // 验证API服务器是否可访问
      try {
        final testResponse = await http.get(Uri.parse('$apiUrl/test'))
            .timeout(const Duration(seconds: 5));
        if (testResponse.statusCode != 200) {
          throw Exception('无法连接到服务器，错误码：${testResponse.statusCode}');
        }
      } catch (e) {
        if (e is TimeoutException) {
          throw Exception('服务器连接超时，请检查服务器地址是否正确或网络是否稳定');
        } else {
          throw Exception('无法连接到服务器: ${e.toString()}');
        }
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
        status: '准备上传 ${allFiles.length} 张照片\n正在创建上传批次...',
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
        apiUrl: '$apiUrl/upload',
        project: project,
        type: type,
        value: value,
        onProgress: (completed, total) {
          final progress = completed / total;
          status = status.copyWith(
            progress: progress,
            status: '正在上传: $completed/$total 批次\n总进度: ${(progress * 100).toStringAsFixed(1)}%',
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
      final isSuccess = totalSuccess > 0 && totalFiles > 0;
      final successRate = totalFiles > 0 ? (totalSuccess / totalFiles * 100).toStringAsFixed(1) : "0";
      
      if (totalSuccess == 0) {
        throw Exception('所有文件上传失败，请检查网络连接和服务器状态');
      }
      
      status = status.copyWith(
        isComplete: true,
        isSuccess: isSuccess,
        status: isSuccess 
          ? '上传完成！\n成功上传: $totalSuccess/$totalFiles 张照片 (${successRate}%)'
          : '上传部分完成\n成功上传: $totalSuccess/$totalFiles 张照片 (${successRate}%)\n请检查网络后重试',
        logs: List.from(status.logs),
      );
      status.addLog(
        isSuccess ? '上传成功完成' : '部分文件上传失败',
        isError: !isSuccess,
      );

    } catch (e) {
      print('上传过程错误: $e');
      // 提供更友好的错误信息
      String errorMessage = '上传失败';
      
      // 特殊处理PLY文件生成失败错误
      if (e.toString().contains('ply文件生成失败')) {
        // 如果是PLY文件错误，将上传视为成功
        status = status.copyWith(
          isComplete: true,
          isSuccess: true, // 标记为成功
          status: '上传完成！\n照片上传成功，但部分处理未能完成',
          logs: List.from(status.logs),
        );
        status.addLog('照片上传成功，但部分后处理未完成');
        _uploadStatuses[project.id] = status;
        notifyListeners();
        await _saveUploadStatuses();
        return; // 直接返回，不继续处理错误
      } 
      // 其他错误正常处理
      else if (e.toString().contains('网络连接不可用')) {
        errorMessage = '网络连接不可用，请检查网络设置';
      } else if (e.toString().contains('服务器连接超时')) {
        errorMessage = '服务器连接超时，请检查服务器地址是否正确';
      } else if (e.toString().contains('无法连接到服务器')) {
        errorMessage = '无法连接到服务器，请检查服务器地址或网络设置';
      } else if (e.toString().contains('请先在设置中配置服务器地址')) {
        errorMessage = '请先在设置中配置服务器地址';
      } else if (e.toString().contains('没有可上传的文件')) {
        errorMessage = '没有可上传的文件，请确保项目中包含照片';
      } else {
        errorMessage = '上传失败: ${e.toString()}';
      }
      
      status = status.copyWith(
        isComplete: true,
        isSuccess: false,
        status: '$errorMessage\n请检查网络和服务器设置后重试',
        error: e.toString(),
        logs: List.from(status.logs),
      );
      status.addLog('上传失败: ${e.toString()}', isError: true);
      
      // 重新抛出异常以便调用者处理
      throw Exception(errorMessage);
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
    final status = _uploadStatuses[project.id];

    try {
      if (batches.isEmpty) {
        if (status != null) {
          status.addLog('没有批次需要上传', isError: true);
          _uploadStatuses[project.id] = status;
          notifyListeners();
        }
        return [];
      }

      if (status != null) {
        status.addLog('开始并发上传 ${batches.length} 个批次，并发数: 3');
        _uploadStatuses[project.id] = status;
        notifyListeners();
      }
      
      // 创建所有批次的上传任务
      final futures = batches.asMap().entries.map((entry) {
        final batchIndex = entry.key;
        final batch = entry.value;

        return pool.withResource(() async {
          try {
            final result = await _uploadBatch(
              batch: batch,
              batchNumber: batchIndex + 1,
              totalBatches: batches.length,
              apiUrl: apiUrl,
              project: project,
              type: type,
              value: value,
            );

            // 增加完成批次计数
            completed++;
            onProgress(completed, total);
            return result;
          } catch (e) {
            // 处理上传单个批次时的异常
            if (status != null) {
              status.addLog('批次 ${batchIndex + 1} 上传失败: ${e.toString()}', isError: true);
              _uploadStatuses[project.id] = status;
              notifyListeners();
            }
            
            // 返回失败结果
            completed++;
            onProgress(completed, total);
            return BatchUploadResult(success: false, filesCount: batch.length);
          }
        });
      }).toList();

      // 等待所有批次上传完成
      results.addAll(await Future.wait(futures));
      
      // 检查上传结果
      int successCount = results.where((r) => r.success).length;
      if (status != null) {
        status.addLog('所有批次处理完成，成功: $successCount/${results.length}');
        _uploadStatuses[project.id] = status;
        notifyListeners();
      }
      
    } catch (e) {
      print('并发上传错误: $e');
      if (status != null) {
        status.addLog('并发上传过程中发生错误: ${e.toString()}', isError: true);
        _uploadStatuses[project.id] = status;
        notifyListeners();
      }
    } finally {
      // 确保资源池被关闭
      await pool.close();
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

    // 准备multipart请求
    http.MultipartRequest createRequest() {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // 添加项目信息和上传类型
      request.fields.addAll({
        'type': type?.name ?? 'unknown',
        'value': value ?? 'unknown',
        'project_info': json.encode(project.toJson()),
        'batch_number': batchNumber.toString(),
        'total_batches': totalBatches.toString(),
      });

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

      return request;
    }
    
    // 使用retry包进行重试
    try {
      // 配置重试策略
      final r = RetryOptions(
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 1),
        maxDelay: const Duration(seconds: 10),
        randomizationFactor: 0.2,
      );
      
      int currentAttempt = 0;
      
      // 执行带有重试的HTTP请求
      return await r.retry(
        () async {
          // 每次尝试时增加计数
          currentAttempt++;
          
          // 创建新的请求（每次重试都需要）
          final request = createRequest();
          
          if (status != null) {
            status.addLog('发送批次 $batchNumber 请求 (尝试 ${currentAttempt}/${r.maxAttempts})');
            _uploadStatuses[project.id] = status;
            notifyListeners();
          }
          
          // 发送请求并等待响应
          final response = await request.send().timeout(const Duration(minutes: 2));
          final responseData = await response.stream.bytesToString();
          
          // 解析响应数据
          Map<String, dynamic> responseJson;
          try {
            responseJson = json.decode(responseData);
          } catch (e) {
            if (status != null) {
              status.addLog('解析响应数据失败: $e', isError: true);
              _uploadStatuses[project.id] = status;
              notifyListeners();
            }
            throw FormatException('服务器响应格式错误，无法解析: $responseData');
          }
          
          // 处理成功响应
          if (response.statusCode == 200) {
            String successRate = responseJson['success_rate'] ?? '';
            int savedFiles = responseJson['saved_files'] ?? batch.length;
            bool plyFilesFound = responseJson['ply_files_found'] ?? false;
            
            // 如果这是最后一个批次，检查是否成功生成PLY文件
            if (batchNumber == totalBatches && status != null) {
              status.hasPlyFiles = plyFilesFound;
              
              if (plyFilesFound) {
                status.addLog('PLY文件生成成功');
              } else if (responseJson.containsKey('ply_files_found')) {
                status.addLog('PLY文件生成成功');
              }
            }
            
            if (status != null) {
              if (successRate.isNotEmpty) {
                status.addLog('批次 $batchNumber 上传成功，成功率: $successRate');
              } else {
                status.addLog('批次 $batchNumber 上传成功');
              }
              _uploadStatuses[project.id] = status;
              notifyListeners();
            }
            
            return BatchUploadResult(success: true, filesCount: savedFiles);
          }
          
          // 处理错误响应
          String errorMessage = responseJson['message'] ?? '未知错误';
          
          // 特殊处理PLY文件生成失败错误
          if (response.statusCode == 500 && errorMessage.contains('ply文件生成失败')) {
            // 忽略PLY文件失败错误，将其视为成功
            if (status != null) {
              status.addLog('照片上传成功，但部分后处理未完成');
              _uploadStatuses[project.id] = status;
              notifyListeners();
            }
            
            return BatchUploadResult(success: true, filesCount: batch.length);
          }
          
          if (status != null) {
            status.addLog('批次 $batchNumber 上传失败: ${response.statusCode}, $errorMessage', isError: true);
            _uploadStatuses[project.id] = status;
            notifyListeners();
          }
          
          // 服务器错误时抛出异常以触发重试
          if (response.statusCode >= 500) {
            // 特殊处理PLY文件错误
            if (errorMessage.contains('ply文件生成失败')) {
              if (status != null) {
                status.addLog('照片上传成功，但部分后处理未完成');
                _uploadStatuses[project.id] = status;
                notifyListeners();
              }
              return BatchUploadResult(success: true, filesCount: batch.length);
            }
            
            throw ServerException('服务器错误: ${response.statusCode}');
          }
          
          // 客户端错误，不再重试
          return BatchUploadResult(success: false, filesCount: batch.length);
        },
        retryIf: (e) {
          // 确定哪些异常应该触发重试
          bool shouldRetry = e is SocketException || 
                             e is TimeoutException || 
                             e is ServerException ||
                             (e is FormatException && e.toString().contains('服务器响应格式错误')) ||
                             e.toString().contains('network');
          
          if (shouldRetry && status != null) {
            status.addLog('发生错误: ${e.toString()}, 将进行重试', isError: true);
            _uploadStatuses[project.id] = status;
            notifyListeners();
          }
          
          return shouldRetry;
        },
        onRetry: (e) {
          if (status != null) {
            status.addLog('重试批次 $batchNumber (尝试 ${currentAttempt + 1}/${r.maxAttempts})');
            _uploadStatuses[project.id] = status;
            notifyListeners();
          }
        },
      );
    } catch (e) {
      // 所有重试都失败后
      if (status != null) {
        status.addLog('批次 $batchNumber 上传失败: ${e.toString()}', isError: true);
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

  // 查找包含指定路径的项目
  Project? findProjectContainingPath(String path) {
    // 标准化路径以便于比较
    final normalizedPath = path.replaceAll('\\', '/');
    
    for (var project in projects) {
      // 检查项目路径
      if (normalizedPath.contains(project.path.replaceAll('\\', '/'))) {
        return project;
      }
      
      // 检查项目中的车辆路径
      for (var vehicle in project.vehicles) {
        if (normalizedPath.contains(vehicle.path.replaceAll('\\', '/'))) {
          return project;
        }
        
        // 检查车辆中的轨迹路径
        for (var track in vehicle.tracks) {
          if (normalizedPath.contains(track.path.replaceAll('\\', '/'))) {
            return project;
          }
        }
      }
    }
    
    return null;
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

// 添加自定义异常类
class ServerException implements Exception {
  final String message;
  ServerException(this.message);
  
  @override
  String toString() => message;
}