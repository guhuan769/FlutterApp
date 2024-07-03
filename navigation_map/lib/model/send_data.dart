import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:crclib/catalog.dart';
import 'package:crclib/crclib.dart';

class SendData {
  SendData({
    this.cRCHigh,
    this.cRCLow,
    required this.cmd,
    required this.sn,
    this.datas,
  })  : assert(cRCHigh == null || cRCHigh >= 0 && cRCHigh <= 255,
            ' cRCHigh must wait 8 '),
        assert(cRCLow == null || cRCLow >= 0 && cRCLow <= 255,
            ' cRCLow must wait 8 ');

  SendData.fromJson(dynamic json) {
    cRCHigh = json['cRCHigh'];
    cRCLow = json['cRCLow'];
    cmd = json['cmd'];
    sn = json['sn'];
    if (json['datas'] != null) {
      datas = [];
      json['datas'].forEach((v) {
        datas?.add(Datas.fromJson(v));
      });
    }
  }

  int? cRCHigh;
  int? cRCLow;
  int cmd = 0;
  int sn = 0;
  List<Datas>? datas = [];

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['cRCHigh'] = cRCHigh;
    map['cRCLow'] = cRCLow;
    map['cmd'] = cmd;
    map['sn'] = sn;
    if (datas != null) {
      map['Datas'] = datas?.map((v) => v.toJson()).toList();
    }
    return map;
  }

  // TODO: 把所有的字节发出去
  Uint8List? buildAllBytes() {
    return null;
  }

  Uint8List buildBytesAddCrc() {
    // 初始化 ByteData 对象
    int byteDataLength = 1024;
    ByteData byteData = ByteData(byteDataLength); // 假设足够大以容纳所有数据
    int offset = 0;

    // 添加 Cmd 和 SN
    byteData.setUint8(offset, cmd);
    offset += 1;
    byteData.setUint8(offset, sn);
    offset += 1;

    // 遍历 Datas
    for (var item in datas ?? []) {
      // 添加 Address 和 Length
      byteData.setInt16(offset, item.address, Endian.little);
      offset += 2;
      byteData.setInt16(offset, item.length, Endian.little);
      offset += 2;

      // 添加数据
      if (item.datas != null) {
        for (var data in item.datas) {
          // 创建一个ByteData对象，足够存储一个32位的值
          //ByteData datafloat = ByteData(4);
          // 将int值设置为Float32和Float64
          //datafloat.setFloat32(0, data.toDouble(), Endian.little); // 使用32位浮点数表示
          // double float32Value = byteData.getFloat32(0);
          // int doubleValue = int.parse(data);
          double doubleValue = double.parse(data);

          byteData.setFloat32(offset, doubleValue, Endian.little);
          double float32Value = byteData.getFloat32(offset, Endian.little);
          offset += 4;
        }
      } else if (item.data != null) {
        switch (item.address) {
          case 0x248:
          case 0x250:
          case 0x40:
          case 0x3d0:
          case 0x3d4:
          case 0x260:
          case 0x256:
            byteData.setInt32(offset, int.parse(item.data), Endian.little);
            offset += 1;
            break;
          case 0x257:
          case 0x253:
          case 0x251:
          case 0x5f1:
            byteData.setInt32(offset, item.data, Endian.little);
            offset += 1;
            break;
          case 0x3c:
          case 0x162:
          case 0x70:
          case 0x71:
          case 0x72:
          case 0x73:
          case 0x74:
            byteData.setInt32(offset, item.data, Endian.little);
            offset += 4;
            break;
          case 0x290:
            var stringBytes = utf8.encode(item.data.toString());
            for (var b in stringBytes) {
              byteData.setUint8(offset, b);
              offset += 1;
            }
            break;
          default:
            // 处理默认情况
            break;
        }
      }
    }

    Uint8List dataArray = byteData.buffer.asUint8List(0, offset);
    String hexString =
        dataArray.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    CrcValue crcValue = Crc16X25().convert(dataArray);
    // int crcIntValue = int.parse(crcValue.toString());
    int crcIntValue = crcValue.toBigInt().toInt();
    var high8Bits = (crcIntValue >> 8) & 0xFF;
    var low8Bits = crcIntValue & 0xFF;
    cRCHigh = high8Bits;
    cRCLow = low8Bits;
    // 返回 Uint8List
    return dataArray;
  }
}

class Datas {
  Datas({
    this.address,
    this.length,
    this.data,
    this.datas,
  });

  Datas.fromJson(dynamic json) {
    address = json['address'];
    length = json['length'];
    data = json['data'];
    datas = json['datas'];
  }

  int? address;
  int? length;
  dynamic data;
  List<dynamic>? datas;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['address'] = address;
    map['length'] = length;
    map['data'] = data;
    map['datas'] = datas;
    return map;
  }
}
