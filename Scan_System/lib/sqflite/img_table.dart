import 'dart:convert';

import 'package:path/path.dart';
import 'package:scan_system/model/image_model.dart';
import 'package:scan_system/sqflite/TablesInit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'DBUtil.dart';

class ImgTable {
  var dataList = "";
  late Dbutil dbUtil;

  void initDB() async {
    Tablesinit tables = Tablesinit();
    tables.init();
    dbUtil = Dbutil();
  }

  void insertData(String Path) async {
    await dbUtil.open();
    Map<String, Object> par = Map<String, Object>();
    par['imgName'] = "imgs";
    par['path'] = Path;
    par['isSelect'] = false;
    int flag = await dbUtil.insertByHelper('imgs', par);
    print('flag:$flag');
    await dbUtil.close();
    queryData();
  }

  Future<List<Map>> queryData() async {
      await dbUtil.open();
      List<Map> data = await dbUtil.queryList("SELECT * FROM imgs");
      print('queryData data：$data');
      
      String showdata = "";
      if (data == null) {
        showdata = "";
      } else {
        // showdata = json.encode(data);
      }
      // setState(() {
      //dataList = showdata;
      //});
      await dbUtil.close();
      return data;
  }

  void delete(int Id) async {
    await dbUtil.open();
    List parameters = [Id];
    await dbUtil.delete('DELETE FROM imgs where id = ? ', parameters);
    //await dbUtil.deleteByHelper('imgs', 'id=?', [2]);
    await dbUtil.close();
    queryData();

  }

  void closeDB() {}

}
