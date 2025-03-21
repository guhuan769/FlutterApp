// lib/config/upload_options.dart

enum UploadType {
  project,
  vehicle,
  track,
  model,
  craft,
}

class UploadOptions {
  static const String defaultApiUrl = 'http://localhost:5000';
  static const int maxConcurrentUploads = 3;
  static const int batchSize = 5;
  static const Duration uploadTimeout = Duration(minutes: 5);
  
  static const List<String> models = [
    '模型A',
    '模型B',
    '模型C',
  ];
  
  static const List<String> crafts = [
    '工艺1',
    '工艺2',
    '工艺3',
  ];
}