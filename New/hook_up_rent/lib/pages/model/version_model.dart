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