// hex_utils.dart
class HexUtils {
  /// 将数字转换为带有分隔符的16进制字符串格式。
  /// 格式：每2位16进制数前加 "0x"，例如：0x12 0x34 0x56。
  static String toHexWithSeparator(int number) {
    // 将数字转换为3个字节的16进制字符串
    String hexString = number.toRadixString(16).padLeft(6, '0').toUpperCase();

    // 插入分隔符并加上0x¡™™
    String formattedString = '0x' + hexString.replaceAllMapped(
      RegExp(r'.{2}'),
          (match) => '${match.group(0)} 0x',
    ).trimRight();

    // 去掉末尾多余的" 0x"
    return formattedString.substring(0, formattedString.length - 3);
  }
}


// import 'path/to/hex_utils.dart';
//
// void main() {
//   int number = 1193046; // 例如，输入数字
//   String hexWithSeparator = HexUtils.toHexWithSeparator(number);
//   print(hexWithSeparator); // 输出：0x12 0x34 0x56
// }
