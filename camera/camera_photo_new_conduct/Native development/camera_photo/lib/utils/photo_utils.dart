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
    // 直接检查文件名是否以特定类型开头
    if (fileName.startsWith(START_PHOTO)) return START_PHOTO;
    if (fileName.startsWith(MIDDLE_PHOTO)) return MIDDLE_PHOTO;
    if (fileName.startsWith(MODEL_PHOTO)) return MODEL_PHOTO;
    if (fileName.startsWith(END_PHOTO)) return END_PHOTO;
    return '';
  }

  // 从文件名解析序号（更新以支持带角度的文件名）
  static int getPhotoSequence(String filePath) {
    try {
      final fileName = path.basename(filePath);
      // 这里使用正则表达式来匹配序号，它会匹配文件名最后的数字部分（在.jpg前面）
      final RegExp regex = RegExp(r'_(\d+)\.jpg$');
      final match = regex.firstMatch(fileName);
      if (match != null && match.group(1) != null) {
        return int.tryParse(match.group(1)!) ?? 999;
      }
    } catch (e) {
      print('解析序号失败: $e');
    }
    return 999;
  }

  // 从文件名中提取角度信息
  static String getPhotoAngle(String filePath) {
    try {
      final fileName = path.basename(filePath);
      final RegExp regex = RegExp(r'_(\d+)度_');
      final match = regex.firstMatch(fileName);
      if (match != null && match.group(1) != null) {
        return match.group(1)!;
      }
    } catch (e) {
      print('解析角度失败: $e');
    }
    return '';
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

  // 格式化照片显示名称（用于UI显示）
  static String formatPhotoNameForDisplay(String filePath) {
    final photoType = getPhotoType(filePath);
    final sequence = getPhotoSequence(filePath);
    final angle = getPhotoAngle(filePath);
    
    // 格式化显示名称，首先显示类型，然后是序号
    final typeDisplayName = photoType.replaceAll('拍照', '');
    final sequenceStr = sequence.toString().padLeft(2, '0');
    
    if (angle.isNotEmpty) {
      return '$typeDisplayName #$sequenceStr\n(${angle}°)';
    } else {
      return '$typeDisplayName #$sequenceStr';
    }
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
    
    // 对于未能识别类型的照片，添加到列表末尾
    final otherPhotos = photos.where((p) => 
      !startPhotos.contains(p) && 
      !middlePhotos.contains(p) && 
      !modelPhotos.contains(p) && 
      !endPhotos.contains(p)
    ).toList();
    
    sortedPhotos.addAll(otherPhotos);
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
      // 我们不修改序号，只是保留现有逻辑作为参考
    } catch (e) {
      print('重新排序照片失败: $e');
    }
  }
}