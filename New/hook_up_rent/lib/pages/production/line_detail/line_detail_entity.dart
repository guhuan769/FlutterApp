/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-25 13:41:35
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-05-22 11:35:45
 * @FilePath: \hook_up_rent\lib\pages\production\line_detail\line_detail_entity.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */

import 'dart:ffi';

class LineDetailEntity {
  late String key;
  late final String deviceName;
  late final String deviceImg;
  late final String runState;
  late int runStateInt;

  LineDetailEntity(this.key, this.deviceName,this.deviceImg, this.runState,this.runStateInt);

  LineDetailEntity.fromJson(Map<String, dynamic> json) {
    key = json["key"];
    deviceName = json["deviceName"];
    deviceImg = json["deviceImg"];
    runState = json["runState"];
    runStateInt = json["runStateInt"];
    
    // // 1.将color转成十六进制的数字
    // final colorInt = int.parse(color，radix: 16);
    // // 2.将透明度加进去
    // cColor = Color(colorInt xFF00000);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = new Map<String, dynamic>();
    data['key'] = this.key;
    data['deviceName'] = this.deviceName;
    data['runState'] = this.runState;
    data['runStateInt'] = this.runStateInt;
    return data;
  }
}
