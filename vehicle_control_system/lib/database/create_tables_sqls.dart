///数据表定义
class CreateTablesSqls{

  //关系表语句 CREATE TABLE IF NOT EXISTS  CREATE TABLE imgs(id INTEGER PRIMARY KEY,imgName TEXT(50),isSelect bool,path TEXT(500))
  static const createTableSql_Imgs =
   "CREATE TABLE IF NOT EXISTS imgs(id INTEGER PRIMARY KEY,imgName TEXT(50),isSelect bool,path TEXT(500))";

  Map<String,String> getAllTables(){
    Map<String,String> map = Map<String,String>();
    map['Imgs'] = createTableSql_Imgs;
    return map;
  }
}