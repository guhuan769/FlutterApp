// lib/models/project.dart
import 'dart:io';

class Project {
  String id;
  String name;
  String path;
  DateTime createdAt;
  List<Track> tracks;
  List<File> photos;

  Project({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    this.tracks = const [],
    this.photos = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'createdAt': createdAt.toIso8601String(),
    'tracks': tracks.map((track) => track.toJson()).toList(),
  };

  static Project fromJson(Map<String, dynamic> json) => Project(
    id: json['id'],
    name: json['name'],
    path: json['path'],
    createdAt: DateTime.parse(json['createdAt']),
    tracks: (json['tracks'] as List).map((e) => Track.fromJson(e)).toList(),
  );
}

class Track {
  String id;
  String name;
  String path;
  DateTime createdAt;
  List<File> photos;
  String projectId;

  Track({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    required this.projectId,
    this.photos = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'createdAt': createdAt.toIso8601String(),
    'projectId': projectId,
  };

  static Track fromJson(Map<String, dynamic> json) => Track(
    id: json['id'],
    name: json['name'],
    path: json['path'],
    createdAt: DateTime.parse(json['createdAt']),
    projectId: json['projectId'],
  );
}