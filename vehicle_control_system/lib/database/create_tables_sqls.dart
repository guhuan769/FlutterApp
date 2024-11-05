///数据表定义
class CreateTablesSqls{

  //关系表语句 CREATE TABLE IF NOT EXISTS  CREATE TABLE imgs(id INTEGER PRIMARY KEY,imgName TEXT(50),isSelect bool,path TEXT(500))
  static const createTableSql_Imgs =
   "CREATE TABLE IF NOT EXISTS title_items("
      "id INTEGER PRIMARY KEY,"
      "title TEXT(50),"
      "description TEXT(500),"
      "imageUrl TEXT(500),"
      "ip TEXT(50),"
      // "isSelect bool,path TEXT(500)"
      "port integer"
      ")";
  Map<String,String> getAllTables(){
    Map<String,String> map = Map<String,String>();
    map['title_items'] = createTableSql_Imgs;
    return map;
  }
}