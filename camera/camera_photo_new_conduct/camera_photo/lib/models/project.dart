// lib/models/project.dart
import 'dart:io';

class Project {
  String id;
  String name;
  String path;
  DateTime createdAt;
  List<Vehicle> vehicles; // 修改为车辆列表
  List<File> photos;

  Project({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    List<Vehicle>? vehicles, // 使用可选参数
    List<File>? photos, // 使用可选参数
  }) :
  // 初始化为空的可修改列表，而不是const列表
        vehicles = vehicles ?? [],
        photos = photos ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'createdAt': createdAt.toIso8601String(),
    'vehicles': vehicles.map((vehicle) => vehicle.toJson()).toList(),
  };

  static Project fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      path: json['path'],
      createdAt: DateTime.parse(json['createdAt']),
      vehicles: (json['vehicles'] as List?)?.map((e) => Vehicle.fromJson(e)).toList() ?? [],
    );
  }
}

class Vehicle {
  String id;
  String name;
  String path;
  DateTime createdAt;
  List<Track> tracks;
  List<File> photos;
  String projectId;

  Vehicle({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    required this.projectId,
    List<Track>? tracks,
    List<File>? photos,
  }) : 
        tracks = tracks ?? [],
        photos = photos ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'createdAt': createdAt.toIso8601String(),
    'projectId': projectId,
    'tracks': tracks.map((track) => track.toJson()).toList(),
  };

  static Vehicle fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      name: json['name'],
      path: json['path'],
      createdAt: DateTime.parse(json['createdAt']),
      projectId: json['projectId'],
      tracks: (json['tracks'] as List?)?.map((e) => Track.fromJson(e)).toList() ?? [],
    );
  }
}

class Track {
  String id;
  String name;
  String path;
  DateTime createdAt;
  List<File> photos;
  String vehicleId; // 修改为车辆ID
  String projectId; // 保留项目ID以便向上引用

  Track({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    required this.vehicleId,
    required this.projectId,
    List<File>? photos, // 使用可选参数
  }) : photos = photos ?? []; // 初始化为空的可修改列表

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'createdAt': createdAt.toIso8601String(),
    'vehicleId': vehicleId,
    'projectId': projectId,
  };

  static Track fromJson(Map<String, dynamic> json) => Track(
    id: json['id'],
    name: json['name'],
    path: json['path'],
    createdAt: DateTime.parse(json['createdAt']),
    vehicleId: json['vehicleId'],
    projectId: json['projectId'],
  );
}