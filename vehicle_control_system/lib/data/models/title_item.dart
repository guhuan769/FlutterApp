class TitleItem {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final String? ip;
  final int port;

  TitleItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.ip,
    this.port = 0,
  });

  // 将数据库中的 Map 转换为 TitleItem 实例
  factory TitleItem.fromMap(Map<String, dynamic> json) => TitleItem(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    imageUrl: json['imageUrl'],
    ip: json['ip'],
    port: json['port'],
  );
}
