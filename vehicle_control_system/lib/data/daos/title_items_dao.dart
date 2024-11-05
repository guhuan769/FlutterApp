import 'package:sqflite/sqflite.dart';
import '../../config/database_config.dart';

class TitleItemsDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 插入一条 title_item
  Future<int> insert(Map<String, dynamic> titleItem) async {
    final db = await _dbHelper.database;
    return await db.insert('title_items', titleItem);
  }

  // 查询所有 title_items
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _dbHelper.database;
    return await db.query('title_items');
  }

  // 根据 ID 查询 title_item
  Future<Map<String, dynamic>?> getById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'title_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // 更新 title_item
  Future<int> update(Map<String, dynamic> titleItem, int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'title_items',
      titleItem,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 删除 title_item
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'title_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
