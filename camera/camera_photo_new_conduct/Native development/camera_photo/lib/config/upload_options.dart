// lib/config/upload_options.dart

enum UploadType {
  project,
  vehicle,
  track,
  model,
  craft,
}

class UploadOptions {
  static const String defaultApiUrl = 'http://192.168.1.100:5000';
  static const int maxConcurrentUploads = 1;
  static const int batchSize = 1;
  static const Duration uploadTimeout = Duration(minutes: 5);
  static const Duration retryDelay = Duration(seconds: 2);
  static const int maxRetries = 2;
  
  static const bool sequentialUpload = true;
  
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