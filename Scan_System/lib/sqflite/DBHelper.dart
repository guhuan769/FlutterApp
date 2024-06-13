import 'package:path/path.dart';
import 'Constants.dart' as Constants;
import 'create_tables_sqls.dart';
import 'package:sqflite/sqflite.dart';

//
// class DBHelper {
//   late Database db;
//
//   Future<void> init() async {
//     final path = await getDatabasesPath();
//     final dbPath = join(path, 'img_database.db');
//     db = await openDatabase(dbPath, version: 1, onCreate: (Database newDb, int version) {
//       // 创建表定义
//       newDb.execute(
//           "CREATE TABLE IF NOT EXISTS img(id INTEGER PRIMARY KEY,imgName TEXT(50),isSelect bool,path TEXT(500))"
//       );
//     });
//   }
//
//   Future<void> close() async {
//     await db.close();
//   }
//
//   Future<List<Map>> query(String table, {List<String>? columns}) async {
//     init();
//     final query = '$table WHERE id = ?';
//     final values = [1]; // 示例参数，你可以根据需要替换
//     final result = await db.query(table);
//     // final result = await db.query(table, where:' 1 = 1');
//     return result;
//   }
//
//   Future<List<Map>> queryAll(String table) async {
//     final query = table ;//+ ' WHERE id = ?';
//     final values = [1]; // 示例参数，你可以根据需要替换
//     final result = await db.rawQuery(query);
//     return result;
//   }
//
// }

class DBHelper {
  static const String DATABASE_NAME = 'img_database.db';
  // static final String TABLE_NAME = 'users';
  // static final String COLUMN_ID = 'id';
  // static final String COLUMN_NAME = 'name';
  // static final String COLUMN_EMAIL = 'email';

  static Future<bool> initDB() async {
    try {
      final database = await openDatabase(DATABASE_NAME, version: 1,
          onCreate: (db, version) async {
        await db.execute(
        "CREATE TABLE IF NOT EXISTS img(id INTEGER PRIMARY KEY,imgName TEXT(50),isSelect bool,path TEXT(500))");
        //prohibit 禁止
        await db.execute("CREATE TABLE config(id INTEGER PRIMARY KEY,ip TEXT(50),port INTEGER,isProhibit bool)");
      });
      return true;
    } on Exception catch (e) {
      print('${e}');
      return false;
    }
  }

  // 获取所有用户
  static Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final database = await openDatabase(DATABASE_NAME);
    final List<Map<String, dynamic>> users = await database.query(table);
    await database.close();
    return users;
  }

  // 添加新用户
  static Future<bool> insert(String table,Map<String, dynamic> json) async {
    try {
      final database = await openDatabase(DATABASE_NAME);
      await database.insert(table,json,conflictAlgorithm: ConflictAlgorithm.replace,);
      await database.close();
      return true;
    } on Exception catch (e) {
      return false;
    }
  }


  // 删除用户
  static Future<bool> delete(String table,int id) async {
    try {
      final database = await openDatabase(DATABASE_NAME);
      await database.delete(table, where: 'id = ?', whereArgs: [id]);
      await database.close();
      return true;
    } on Exception catch (e) {
      return false;
    }
  }

  // 删除用户
  static Future<bool> deleteAll(String table) async {
    try {
      final database = await openDatabase(DATABASE_NAME);
      await database.delete(table);
      await database.close();
      return true;
    } on Exception catch (e) {
      return false;
    }
  }



}
