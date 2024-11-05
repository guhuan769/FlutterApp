import '../daos/user_items_dao.dart';
import '../models/user_item.dart';

class UserItemsRepository {
  final UserItemsDao _dao = UserItemsDao();

  // 插入 user_item
  Future<int> insertUserItem(Map<String, dynamic> userItem) {
    return _dao.insert(userItem);
  }

  // 获取所有 user_items
  Future<List<Map<String, dynamic>>> getAllUserItems() {
    return _dao.getAll();
  }

  // 根据 ID 获取 user_item
  Future<Map<String, dynamic>?> getUserItemById(int id) {
    return _dao.getById(id);
  }

  // 根据用户名获取 user_item
  Future<Map<String, dynamic>?> getUserItemByUsername(String username) {
    return _dao.getByUsername(username);
  }

  // 更新 user_item
  Future<int> updateUserItem(Map<String, dynamic> userItem, int id) {
    return _dao.update(userItem, id);
  }

  // 删除 user_item
  Future<int> deleteUserItem(int id) {
    return _dao.delete(id);
  }
}
