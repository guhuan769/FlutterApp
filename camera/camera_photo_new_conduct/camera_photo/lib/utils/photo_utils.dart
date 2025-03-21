// lib/utils/photo_utils.dart
import 'dart:io';
import 'package:path/path.dart' as path;

class PhotoUtils {
  static const String START_PHOTO = '起始点拍照';
  static const String MIDDLE_PHOTO = '中间点拍照';
  static const String MODEL_PHOTO = '模型点拍照';
  static const String END_PHOTO = '结束点拍照';

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
    // 查找同类型的照片
    final sameTypePhotos = photos
        .where((p) => getPhotoType(p.path) == photoType)
        .toList();
    
    if (sameTypePhotos.isEmpty) {
      // 如果没有同类型照片，根据类型返回初始序号
      if (photoType == START_PHOTO) return 1;
      if (photoType == END_PHOTO) return 1;
      return 1; // 其他类型也从1开始
    }
    
    // 找到最大序号并加1
    sameTypePhotos.sort((a, b) => 
      getPhotoSequence(a.path).compareTo(getPhotoSequence(b.path))
    );
    return getPhotoSequence(sameTypePhotos.last.path) + 1;
  }

  // 生成文件名
  // static String generateFileName(String photoType, int sequence, String timestamp) {
  //   return '${photoType}_${sequence.toString().padLeft(3, '0')}_$timestamp.jpg';
  // }

  static String generateFileName(String photoType, int sequence, String timestamp, String angle) {
    return '${photoType}_${sequence.toString().padLeft(3, '0')}_${timestamp}_${angle}°.jpg';
  }

  // 按照类型和序号排序照片
  static List<File> sortPhotos(List<File> photos) {
    // 按照类型分组
    final startPhotos = photos.where((p) => getPhotoType(p.path) == START_PHOTO).toList();
    final endPhotos = photos.where((p) => getPhotoType(p.path) == END_PHOTO).toList();
    final middlePhotos = photos.where((p) {
      final type = getPhotoType(p.path);
      return type == MIDDLE_PHOTO;
    }).toList();
    final modelPhotos = photos.where((p) {
      final type = getPhotoType(p.path);
      return type == MODEL_PHOTO;
    }).toList();
    
    // 每组内部按序号排序
    startPhotos.sort((a, b) => getPhotoSequence(a.path).compareTo(getPhotoSequence(b.path)));
    middlePhotos.sort((a, b) => getPhotoSequence(a.path).compareTo(getPhotoSequence(b.path)));
    modelPhotos.sort((a, b) => getPhotoSequence(a.path).compareTo(getPhotoSequence(b.path)));
    endPhotos.sort((a, b) => getPhotoSequence(a.path).compareTo(getPhotoSequence(b.path)));
    
    // 合并四组照片，保持顺序：起始点 -> 中间点 -> 模型点 -> 结束点
    final sortedPhotos = [...startPhotos, ...middlePhotos, ...modelPhotos, ...endPhotos];
    return sortedPhotos;
  }

  // 重新排序所有照片并更新序号
  static Future<void> reorderPhotos(List<File> photos) async {
    try {
      // 按照类型分组
      final startPhotos = photos.where((p) => getPhotoType(p.path) == START_PHOTO).toList();
      final endPhotos = photos.where((p) => getPhotoType(p.path) == END_PHOTO).toList();
      final middlePhotos = photos.where((p) => getPhotoType(p.path) == MIDDLE_PHOTO).toList();
      final modelPhotos = photos.where((p) => getPhotoType(p.path) == MODEL_PHOTO).toList();
      
      // 每组内部按序号排序
      startPhotos.sort((a, b) => getPhotoSequence(a.path).compareTo(getPhotoSequence(b.path)));
      middlePhotos.sort((a, b) => getPhotoSequence(a.path).compareTo(getPhotoSequence(b.path)));
      modelPhotos.sort((a, b) => getPhotoSequence(a.path).compareTo(getPhotoSequence(b.path)));
      endPhotos.sort((a, b) => getPhotoSequence(a.path).compareTo(getPhotoSequence(b.path)));
      
      // 重新分配序号 - 保持原有序号不变
      // 起始点照片保持原有序号
      for (int i = 0; i < startPhotos.length; i++) {
        final currentSequence = getPhotoSequence(startPhotos[i].path);
        await _renameWithSequence(startPhotos[i], START_PHOTO, currentSequence);
      }
      
      // 中间点照片保持原有序号
      for (int i = 0; i < middlePhotos.length; i++) {
        final currentSequence = getPhotoSequence(middlePhotos[i].path);
        await _renameWithSequence(middlePhotos[i], MIDDLE_PHOTO, currentSequence);
      }
      
      // 模型点照片保持原有序号
      for (int i = 0; i < modelPhotos.length; i++) {
        final currentSequence = getPhotoSequence(modelPhotos[i].path);
        await _renameWithSequence(modelPhotos[i], MODEL_PHOTO, currentSequence);
      }
      
      // 结束点照片保持原有序号
      for (int i = 0; i < endPhotos.length; i++) {
        final currentSequence = getPhotoSequence(endPhotos[i].path);
        await _renameWithSequence(endPhotos[i], END_PHOTO, currentSequence);
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
        final newName = generateFileName(type, sequence, timestamp,"");
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