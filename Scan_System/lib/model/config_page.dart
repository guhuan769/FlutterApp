
class ConfigPage {
  ConfigPage({
      this.id,
      this.ip, 
      this.port, 
      this.isProhibit,});

  ConfigPage.fromJson(dynamic json) {
    id = json['id'];
    ip = json['Ip'];
    port = json['port'];
    isProhibit = json['isProhibit'];
  }
  
  int? id;
  String? ip;
  int? port;
  bool? isProhibit;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['Ip'] = ip;
    map['port'] = port;
    map['isProhibit'] = isProhibit;
    return map;
  }

}