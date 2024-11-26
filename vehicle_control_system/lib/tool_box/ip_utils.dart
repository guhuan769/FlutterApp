import 'package:flutter/material.dart';

/// IP地址工具类
class IpUtils {
  /// 私有构造函数，防止实例化
  IpUtils._();

  /// IP地址的正则表达式
  static final RegExp _ipRegExp = RegExp(
      r'^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.'
      r'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.'
      r'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.'
      r'(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
  );

  // 验证端口
  static bool validatePort(String port) {
    final int? portInt = int.tryParse(port);
    return portInt != null && portInt >= 1 && portInt <= 65535;
  }

  /// 检查字符串是否为有效的IP地址
  ///
  /// [ipStr] 需要检查的IP地址字符串
  /// 返回true表示是有效的IP地址，false表示无效
  static bool isIpValid(String ipStr) {
    if (ipStr.isEmpty) return false;
    return _ipRegExp.hasMatch(ipStr);
  }

  /// 检查是否为本地回环地址
  ///
  /// [ipStr] 需要检查的IP地址字符串
  /// 返回true表示是本地回环地址，false表示不是
  static bool isLoopbackIp(String ipStr) {
    return isIpValid(ipStr) && (
        ipStr == '127.0.0.1' ||
            ipStr == 'localhost'
    );
  }

  /// 检查是否为私有IP地址
  ///
  /// [ipStr] 需要检查的IP地址字符串
  /// 返回true表示是私有IP地址，false表示不是
  static bool isPrivateIp(String ipStr) {
    if (!isIpValid(ipStr)) return false;

    final parts = ipStr.split('.');
    final first = int.parse(parts[0]);
    final second = int.parse(parts[1]);

    // Class A: 10.0.0.0 to 10.255.255.255
    if (first == 10) return true;

    // Class B: 172.16.0.0 to 172.31.255.255
    if (first == 172 && second >= 16 && second <= 31) return true;

    // Class C: 192.168.0.0 to 192.168.255.255
    if (first == 192 && second == 168) return true;

    return false;
  }

  /// IP地址转换为整数
  ///
  /// [ipStr] 需要转换的IP地址字符串
  /// 返回转换后的整数，如果IP无效则返回null
  static int? ipToInt(String ipStr) {
    if (!isIpValid(ipStr)) return null;

    final parts = ipStr.split('.');
    int result = 0;
    for (int i = 0; i < 4; i++) {
      result = (result << 8) | int.parse(parts[i]);
    }
    return result;
  }

  /// 整数转换为IP地址
  ///
  /// [number] 需要转换的整数
  /// 返回转换后的IP地址字符串
  static String intToIp(int number) {
    final StringBuffer sb = StringBuffer();
    for (int i = 3; i >= 0; i--) {
      sb.write((number >> (i * 8)) & 0xFF);
      if (i > 0) sb.write('.');
    }
    return sb.toString();
  }

  /// 检查是否为公网IP地址
  ///
  /// [ipStr] 需要检查的IP地址字符串
  /// 返回true表示是公网IP地址，false表示不是
  static bool isPublicIp(String ipStr) {
    return isIpValid(ipStr) &&
        !isLoopbackIp(ipStr) &&
        !isPrivateIp(ipStr);
  }

  /// 是否为IPv4地址
  ///
  /// [ipStr] 需要检查的IP地址字符串
  /// 返回true表示是IPv4地址，false表示不是
  static bool isIpv4(String ipStr) {
    return isIpValid(ipStr);
  }

  /// 获取IP地址的各个段
  ///
  /// [ipStr] IP地址字符串
  /// 返回包含4个整数的列表，如果IP无效则返回null
  static List<int>? getIpSegments(String ipStr) {
    if (!isIpValid(ipStr)) return null;

    return ipStr.split('.').map((s) => int.parse(s)).toList();
  }
}

// 使用示例：
void example() {

  const String ip1 = '192.168.1.1';
  const String ip2 = '256.1.2.3';
  const String ip3 = '127.0.0.1';
  const String ip4 = '8.8.8.8';

  // 检查IP是否有效
  print('Is $ip1 valid? ${IpUtils.isIpValid(ip1)}');  // true
  print('Is $ip2 valid? ${IpUtils.isIpValid(ip2)}');  // false

  // 检查IP类型
  print('Is $ip3 loopback? ${IpUtils.isLoopbackIp(ip3)}');  // true
  print('Is $ip1 private? ${IpUtils.isPrivateIp(ip1)}');    // true
  print('Is $ip4 public? ${IpUtils.isPublicIp(ip4)}');      // true

  // IP地址转换
  final int? intIP = IpUtils.ipToInt(ip1);
  if (intIP != null) {
    print('IP as integer: $intIP');
    print('Integer back to IP: ${IpUtils.intToIp(intIP)}');
  }

  // 获取IP段
  final segments = IpUtils.getIpSegments(ip1);
  if (segments != null) {
    print('IP segments: ${segments.join(", ")}');  // 192, 168, 1, 1
  }
}