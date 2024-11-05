class UserItem {
  final int id;
  final String username;
  final String password;

  UserItem({
    required this.id,
    required this.username,
    required this.password,
  });

  // 将数据库中的 Map 转换为 UserItem 实例
  factory UserItem.fromMap(Map<String, dynamic> json) => UserItem(
    id: json['id'],
    username: json['username'],
    password: json['password'],
  );
}
