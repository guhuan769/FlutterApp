// class ProtocolPacket {
//   final int modeType;
//   final int coordinateType;
//   final double coordinateValue;
//
//   ProtocolPacket({
//     required this.modeType,
//     required this.coordinateType,
//     required this.coordinateValue,
//   });
//
//   // 协议包的字符串表示
//   String toProtocolString() {
//     return 'modeType:$modeType|coordinateType:$coordinateType|coordinateValue:$coordinateValue';
//     return '类型:$modeType|坐标:$coordinateType|坐标值:$coordinateValue';
//   }
//
//   // 从字符串解析成 ProtocolPacket
//   static ProtocolPacket fromProtocolString(String data) {
//     try {
//       // 拆分输入数据
//       final parts = data.split('|');
//
//       // 解析各个字段
//       final modeType = _parseInt(parts[0].split(':')[1]);
//       final coordinateType = _parseInt(parts[1].split(':')[1]);
//       final coordinateValue = _parseDouble(parts[2].split(':')[1]);
//
//       return ProtocolPacket(
//         modeType: modeType,
//         coordinateType: coordinateType,
//         coordinateValue: coordinateValue,
//       );
//     } catch (e) {
//       print('数据解析错误: $e');
//       throw FormatException('Invalid format: $data');
//     }
//   }
//
//   // 辅助方法：解析为 int
//   static int _parseInt(String value) {
//     try {
//       return int.parse(value);
//     } catch (e) {
//       print('解析整数时出错: $e');
//       throw FormatException('无效的整数值: $value');
//     }
//   }
//
//   // 辅助方法：解析为 double
//   static double _parseDouble(String value) {
//     try {
//       return double.parse(value);
//     } catch (e) {
//       print('解析浮动数时出错: $e');
//       throw FormatException('无效的浮动数值: $value');
//     }
//   }
//
//   @override
//   String toString() {
//     return 'ProtocolPacket(modeType: $modeType, coordinateType: $coordinateType, coordinateValue: $coordinateValue)';
//   }
// }







class ProtocolPacket {
  final int modeType;
  final int coordinateType;
  final num coordinateValue;

  ProtocolPacket({
    required this.modeType,
    required this.coordinateType,
    required this.coordinateValue,
  });

  // 协议包的字符串表示
  String toProtocolString() {
    // 只保留一个 return 语句
    return 'modeType:$modeType|coordinateType:$coordinateType|coordinateValue:$coordinateValue';
  }

  // 从字符串解析成 ProtocolPacket
  static ProtocolPacket fromProtocolString(String data) {
    try {
      // 拆分输入数据，确保数据格式正确
      final parts = data.split('|');
      if (parts.length != 3) {
        throw FormatException('数据格式错误: 缺少必要字段');
      }

      // 解析各个字段，确保格式正确
      int modeType = _parseInt(parts[0].split(':')[1]);
      int coordinateType = _parseInt(parts[1].split(':')[1]);
      double coordinateValue = _parseDouble(parts[2].split(':')[1]);

      return ProtocolPacket(
        modeType: modeType,
        coordinateType: coordinateType,
        coordinateValue: coordinateValue,
      );
    } catch (e) {
      // 打印详细的错误信息
      print('数据解析错误: $e');
      throw FormatException('无效的格式: $data');
    }
  }

  // 辅助方法：解析为 int
  static int _parseInt(String value) {
    try {
      // 移除多余的空格，防止解析错误
      return int.parse(value.trim());
    } catch (e) {
      print('解析整数时出错: $e，值: $value');
      throw FormatException('无效的整数值: $value');
    }
  }

  // 辅助方法：解析为 double
  static double _parseDouble(String value) {
    try {
      // 移除多余的空格，防止解析错误
      return double.parse(value.trim());
    } catch (e) {
      print('解析浮动数时出错: $e，值: $value');
      throw FormatException('无效的浮动数值: $value');
    }
  }

  @override
  String toString() {
    return 'ProtocolPacket(modeType: $modeType, coordinateType: $coordinateType, coordinateValue: $coordinateValue)';
  }
}
