import '../daos/title_items_dao.dart';
import '../models/title_item.dart';

class TitleItemsRepository {
  final TitleItemsDao _dao = TitleItemsDao();

  // 插入 title_item
  Future<int> insertTitleItem(Map<String, dynamic> titleItem) {
    return _dao.insert(titleItem);
  }

  // 获取所有 title_items
  Future<List<Map<String, dynamic>>> getAllTitleItems() {
    return _dao.getAll();
  }

  // 根据 ID 获取 title_item
  Future<Map<String, dynamic>?> getTitleItemById(int id) {
    return _dao.getById(id);
  }

  // 更新 title_item
  Future<int> updateTitleItem(Map<String, dynamic> titleItem, int id) {
    return _dao.update(titleItem, id);
  }

  // 删除 title_item
  Future<int> deleteTitleItem(int id) {
    return _dao.delete(id);
  }
}
