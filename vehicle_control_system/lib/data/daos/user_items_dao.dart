import 'package:sqflite/sqflite.dart';
import '../../config/database_config.dart';

class UserItemsDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 插入一条 user_item
  Future<int> insert(Map<String, dynamic> userItem) async {
    final db = await _dbHelper.database;
    return await db.insert('user_item', userItem);
  }

  // 查询所有 user_items
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _dbHelper.database;
    return await db.query('user_item');
  }

  // 根据 ID 查询 user_item
  Future<Map<String, dynamic>?> getById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'user_item',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // 根据用户名查询 user_item
  Future<Map<String, dynamic>?> getByUsername(String username) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'user_item',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // 更新 user_item
  Future<int> update(Map<String, dynamic> userItem, int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'user_item',
      userItem,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 删除 user_item
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'user_item',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
