import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ImgModel {
  final int id;
  final String imgName;
  final bool isSelect;
  final String path;

  ImgModel(
      {required this.id,
        required this.imgName,
      required this.isSelect,
      required this.path});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imgName': imgName,
      'isSelect': isSelect,
      'path': path,
    };
  }

  // 方便print时，更好得插卡可能对象的信息
  @override
  String toString() {
    // TODO: implement toString
    return 'ImgModel{id:$id,imgName:$imgName,isSelect:$isSelect,path:$path}';
  }
}


void testSqflite() async {

  // 打开或创建数据库
  final database = openDatabase(
    // 设置数据库的路径
    join(await getDatabasesPath(), 'img_database.db'),
    // 首次创建数据库时，创建一个表来存储 img_table
    onCreate: (db, version) {
      return db.execute(
        "CREATE TABLE imgs(id INTEGER PRIMARY KEY,imgName TEXT,isSelect bool,path TEXT)",
      );
    },
    // 设置版本
    version: 1,
  );

  Future<void> insertImg(ImgModel imgmodel) async {
    // 获取数据库的引用
    final Database db = await database;

    // 将Dog插入表中。 同时指定conflictAlgorithm, 表示如果多次插入同一Img，它将替换先前的数据
    await db.insert(
      ('imgs'),
      imgmodel.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 查询所有 Imgs
  Future<List<ImgModel>> imgs() async {
    final Database db = await database;

    // 查询表中所有 Imgs.
    final List<Map<String,dynamic>> maps = await db.query('imgs');

    // 将List<Map<String,dynamic> 转换为 List<Imgs> 类型
    return List.generate(maps.length, (i) {
      return ImgModel(
          id: maps[i]['id'],
          imgName:maps[i]['imgName'] ,
          isSelect: maps[i]['isSelect'],
          path: maps[i]['path']
      );
    });
  }

  Future<void> updateImg(ImgModel imgModel) async{
    final db = await database;

    // 更新给定的Imgs
    await db.update(
      ('imgs'),
      imgModel.toMap(),
      where: "id = ?",
      // 将Imgs 的 ID 作为whereArg 传递，以防止SQL注入
      whereArgs: [imgModel.id],
    );
  }

  Future<void> deleteImg(int id) async {
    final db = await database;

    // 删除
    await db.delete(
      'imgs',
      // 使用 where 子语句删除指定的img
      where: 'id = ? ',
      whereArgs: [id],
    );
  }

  var fido = ImgModel(
    id: 0,
    imgName: '测试',
    isSelect: false,
    path: '没有路径',
  );

  // 初始化数据
  await insertImg(fido);

  print(await imgs());

  // 更新 fido 的相关属性 并将其保存到数据库
  fido = ImgModel(
      id: fido.id,
      imgName: fido.imgName,
      isSelect: fido.isSelect,
      path: fido.path);

  print(await imgs());

  // 删除 fido
  await deleteImg(fido.id);

  // 关闭数据库
  var db = await database;
  db.close();
}
