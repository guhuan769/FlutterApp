// lib/utils/photo_utils.dart
import 'dart:io';
import 'package:path/path.dart' as path;

class PhotoUtils {
  static const String START_PHOTO = '起始点拍照';
  static const String MIDDLE_PHOTO = '中间点拍照';
  static const String MODEL_PHOTO = '模型点拍照';
  static const String END_PHOTO = '2';

  // 获取照片类型
  static String getPhotoType(String filePath) {
    final fileName = path.basename(filePath);
    final parts = fileName.split('_');
    if (parts.isNotEmpty) {
      if (parts[0] == START_PHOTO) return START_PHOTO;
      if (parts[0] == MIDDLE_PHOTO) return MIDDLE_PHOTO;
      if (parts[0] == MODEL_PHOTO) return MODEL_PHOTO;
      if (parts[0] == END_PHOTO) return END_PHOTO;
    }
    return '';
  }

  // 从文件名解析序号
  static int getPhotoSequence(String filePath) {
    try {
      final fileName = path.basename(filePath);
      final parts = fileName.split('_');
      if (parts.length >= 2) {
        return int.tryParse(parts[1]) ?? 999;
      }
    } catch (e) {
      print('解析序号失败: $e');
    }
    return 999;
  }

  // 生成新的序号
  static int generateNewSequence(List<File> photos, String photoType) {
    if (photoType == START_PHOTO) return 1;
    if (photoType == END_PHOTO) return 999;

    // 获取现有序号
    var sequences = photos.map((p) => getPhotoSequence(p.path))
        .where((seq) => seq != 999) // 排除结束点照片
        .toList()
      ..sort();

    if (sequences.isEmpty) return 2; // 如果只有起始点，从2开始

    // 找到最大序号并加1
    int maxSeq = sequences.last;
    return maxSeq + 1;
  }

  // 生成文件名
  static String generateFileName(String photoType, int sequence, String timestamp) {
    return '${photoType}_${sequence.toString().padLeft(3, '0')}_$timestamp.jpg';
  }

  // 按照类型和序号排序照片
  static List<File> sortPhotos(List<File> photos) {
    var sortedPhotos = List<File>.from(photos);
    sortedPhotos.sort((a, b) {
      final typeA = getPhotoType(a.path);
      final typeB = getPhotoType(b.path);

      if (typeA == START_PHOTO) return -1;
      if (typeB == START_PHOTO) return 1;
      if (typeA == END_PHOTO) return 1;
      if (typeB == END_PHOTO) return -1;

      final seqA = getPhotoSequence(a.path);
      final seqB = getPhotoSequence(b.path);
      return seqA.compareTo(seqB);
    });
    return sortedPhotos;
  }

  // 重新排序所有照片并更新序号
  static Future<void> reorderPhotos(List<File> photos) async {
    try {
      // 先按类型和序号排序
      var sortedPhotos = sortPhotos(photos);

      // 重新分配序号
      int currentSequence = 1;
      for (var photo in sortedPhotos) {
        final type = getPhotoType(photo.path);
        if (type == START_PHOTO) {
          // 起始点保持序号1
          await _renameWithSequence(photo, type, 1);
        } else if (type == END_PHOTO) {
          // 结束点保持序号999
          await _renameWithSequence(photo, type, 999);
        } else {
          // 其他照片按顺序递增
          currentSequence++;
          await _renameWithSequence(photo, type, currentSequence);
        }
      }
    } catch (e) {
      print('重新排序照片失败: $e');
    }
  }

  // 辅助方法：使用新序号重命名照片
  static Future<void> _renameWithSequence(File photo, String type, int sequence) async {
    try {
      final oldPath = photo.path;
      final dir = path.dirname(oldPath);
      final oldName = path.basename(oldPath);
      final parts = oldName.split('_');

      if (parts.length >= 3) {
        final timestamp = parts.last.replaceAll('.jpg', '');
        final newName = generateFileName(type, sequence, timestamp);
        final newPath = path.join(dir, newName);

        if (oldPath != newPath) {
          await photo.rename(newPath);
        }
      }
    } catch (e) {
      print('重命名照片失败: $e');
    }
  }
}