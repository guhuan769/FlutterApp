import 'dart:convert';
import 'dart:ffi' as ffi;
// import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';
import 'dart:typed_data';

class SendData {
  SendData({
    this.cRCHigh,
    this.cRCLow,
    required this.cmd,
    required this.sn,
    this.datas,
  })  : assert(cRCHigh! >= 0 && cRCHigh <= 255, ' cRCHigh must wait 8 '),
        assert(cRCLow! >= 0 && cRCLow <= 255, ' cRCLow must wait 8 ');

  SendData.fromJson(dynamic json) {
    cRCHigh = json['CRCHigh'];
    cRCLow = json['CRCLow'];
    cmd = json['Cmd'];
    sn = json['SN'];
    if (json['Datas'] != null) {
      datas = [];
      json['Datas'].forEach((v) {
        datas?.add(Datas.fromJson(v));
      });
    }
  }

  int? cRCHigh;
  int? cRCLow;
  int cmd = 0;
  int sn = 0;
  List<Datas>? datas = [];

  // Uint8List aa = Uint8List(2);
  // aa[0] = cmd;
  // aa.addAll(sn)

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['CRCHigh'] = cRCHigh;
    map['CRCLow'] = cRCLow;
    map['Cmd'] = cmd;
    map['SN'] = sn;
    if (datas != null) {
      map['Datas'] = datas?.map((v) => v.toJson()).toList();
    }
    return map;
  }

  Uint8List buildBytes() {
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
          byteData.setFloat32(offset, data, Endian.little);
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
            byteData.setInt32(offset, item.Data, Endian.little);
            offset += 4;
            break;
          case 0x257:
          case 0x253:
          case 0x251:
          case 0x5f1:
          case 0x3c:
          case 0x162:
          case 0x70:
          case 0x71:
          case 0x72:
          case 0x73:
          case 0x74:
            byteData.setUint8(offset, item.Data);
            offset += 1;
            break;
          case 0x290:
            var stringBytes = utf8.encode(item.Data.toString());
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
    // 返回 Uint8List
    return byteData.buffer.asUint8List(0, offset);
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
    address = json['Address'];
    length = json['Length'];
    data = json['Data'];
    datas = json['Datas'];
  }

  int? address;
  int? length;
  dynamic data;
  List<dynamic>? datas ;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['Address'] = address;
    map['Length'] = length;
    map['Data'] = data;
    map['Datas'] = datas;
    return map;
  }
}
