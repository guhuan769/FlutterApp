

import 'package:scan_system/Utils/common_toast.dart';

class ImageModel {
  ImageModel({
      this.id, 
      this.imgName, 
      this.isSelect, 
      this.path,});

  ImageModel.fromJson(dynamic json) {
    id = json['id'];
    imgName = json['imgName'];
    isSelect = CommonToast.intToBool(json['isSelect']);
    path = json['path'];
  }
  int? id;
  String? imgName;
  bool? isSelect;
  String? path;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['imgName'] = imgName;
    map['isSelect'] = isSelect;
    map['path'] = path;
    return map;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imgName': imgName,
      'isSelect': isSelect,
      'path': path,
    };
  }

}