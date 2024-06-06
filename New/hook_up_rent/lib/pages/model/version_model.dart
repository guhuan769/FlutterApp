/*
 * @Author: error: error: git config user.name & please set dead value or install git && error: git config user.email & please set dead value or install git & please set dead value or install git
 * @Date: 2024-05-27 16:11:02
 * @LastEditors: error: error: git config user.name & please set dead value or install git && error: git config user.email & please set dead value or install git & please set dead value or install git
 * @LastEditTime: 2024-06-06 16:32:58
 * @FilePath: \hook_up_rent\lib\pages\model\version_model.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
class VersionModel {
  VersionModel({
      this.code,
      this.path,
      this.filename,
      this.tstatus,
      this.createUser,
      this.createCompanyItemCode,
      this.createCompanyCode,
      this.createTime,
      this.version, 
      this.forceUpdateStatus,
      this.platformType,});

  VersionModel.fromJson(dynamic json) {
    code = json['code'];
    path = json['path'];
    filename = json['filename'];
    tstatus = json['tstatus'];
    createUser = json['createUser'];
    createCompanyItemCode = json['createCompanyItemCode'];
    createCompanyCode = json['createCompanyCode'];
    createTime = json['createTime'];
    version = json['version'];
    forceUpdateStatus = json['forceUpdateStatus'];
    platformType = json['platformType'];
  }
  
  String? code;
  String? path;
  String? filename;
  int? tstatus;
  int? createUser;
  int? createCompanyItemCode;
  int? createCompanyCode;
  String? createTime;
  String? version;
  int? forceUpdateStatus;
  int? platformType;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['code'] = code;
    map['path'] = path;
    map['filename'] = filename;
    map['tstatus'] = tstatus;
    map['createUser'] = createUser;
    map['createCompanyItemCode'] = createCompanyItemCode;
    map['createCompanyCode'] = createCompanyCode;
    map['createTime'] = createTime;
    map['version'] = version;
    map['forceUpdateStatus'] = forceUpdateStatus;
    map['platformType'] = platformType;
    return map;
  }

}