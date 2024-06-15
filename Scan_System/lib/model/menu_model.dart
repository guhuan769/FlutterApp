class MenuModel {
  MenuModel({
      this.menuId, 
      this.menuName, 
      this.isDisable,this.page});

  MenuModel.fromJson(dynamic json) {
    menuId = json['menu_id'];
    menuName = json['menu_name'];
    isDisable = json['is_disable'];
  }
  double? menuId;
  String? menuName;
  bool? isDisable;
  Object? page;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['menu_id'] = menuId;
    map['menu_name'] = menuName;
    map['is_disable'] = isDisable;
    return map;
  }

}