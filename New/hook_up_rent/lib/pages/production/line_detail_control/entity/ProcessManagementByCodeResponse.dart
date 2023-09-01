/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-05-20 11:00:42
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-05-20 11:46:03
 * @FilePath: \hook_up_rent\lib\pages\production\line_detail_control\entity\ProcessManagementByCodeResponse.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'dart:ffi';

class ProcessManagementByCodeResponse {
  late String groupCode;
  late final String tName;
  late final List<CustomPubProcessManagementForm> pubProcessManagements = [];
  ProcessManagementByCodeResponse(this.groupCode, this.tName);

  ProcessManagementByCodeResponse.fromJson(Map<String, dynamic> json) {
    groupCode = json["groupCode"];
    tName = json["tName"];
    // pubProcessManagements = json["CustomPubProcessManagementForm"];

    // // 1.将color转成十六进制的数字
    // final colorInt = int.parse(color，radix: 16);
    // // 2.将透明度加进去
    // cColor = Color(colorInt xFF00000);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['groupCode'] = this.groupCode;
    data['tName'] = this.tName;
    data['pubProcessManagements'] = this.pubProcessManagements;
    return data;
  }
}

class CustomPubProcessManagementForm {
  late final String key;
  late final String groupCode;
  late final String tName;
  late final int lineCode;
  late final int runtstatus;
  late final String runtstatusName;
  late final int tStatus;
  late final String tStatusName;
  CustomPubProcessManagementForm(
      this.key,
      this.groupCode,
      this.tName,
      this.lineCode,
      this.runtstatus,
      this.runtstatusName,
      this.tStatus,
      this.tStatusName);

  CustomPubProcessManagementForm.fromJson(Map<String, dynamic> json) {
    key = json["key"];
    groupCode = json["groupCode"];
    tName = json["tName"];
    lineCode = json["lineCode"];
    runtstatus = json["runtstatus"];
    runtstatusName = json["runtstatusName"];
    tStatus = json["tStatus"];
    tStatusName = json["tStatusName"];
    // // 1.将color转成十六进制的数字
    // final colorInt = int.parse(color，radix: 16);
    // // 2.将透明度加进去
    // cColor = Color(colorInt xFF00000);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['key'] = this.key;
    data['groupCode'] = this.groupCode;
    data['tName'] = this.tName;
    data['lineCode'] = this.lineCode;
    data['runtstatus'] = this.runtstatus;
    data['runtstatusName'] = this.runtstatusName;
    data['tStatus'] = this.tStatus;
    data['tStatusName'] = this.tStatusName;
    return data;
  }
}
