// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:vehicle_control_system/data/repositories/title_items_repo.dart';
//
// class CarBodyControl extends StatelessWidget {
//   // final String title;
//
//   // const CarBodyControl({super.key,  required this.title});
//   const CarBodyControl({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     // 使用 Get.arguments 获取传递的参数
//     final args = Get.arguments as Map<String, dynamic>?;
//     final title = args?['title'] ?? 'Default Title'; // 使用默认值避免参数为 null
//     final TitleItemsRepository _repo = TitleItemsRepository();
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Title Items222"),
//       ),
//       body: FutureBuilder<List<Map<String, dynamic>>>(
//         future: _repo.getAllTitleItems(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text("Error: ${snapshot.error}"));
//           }
//           final titleItems = snapshot.data ?? [];
//           return ListView.builder(
//             itemCount: titleItems.length,
//             itemBuilder: (context, index) {
//               final item = titleItems[index];
//               return ListTile(
//                 title: Text(item['title']),
//                 subtitle: Text(item['description']),
//               );
//             },
//           );
//         },
//       ),
//     );
//
//     // return Scaffold(
//     //   appBar: AppBar(title: Text(title)),
//     //   body: Center(
//     //     child: Text('这是 $title 的控制界面'),
//     //   ),
//     // );
//   }
// }


//  实现啦split的增删改查


import 'package:flutter/material.dart';
import 'package:vehicle_control_system/data/repositories/title_items_repo.dart';

class CarBodyControl extends StatefulWidget {
  @override
  _CarBodyControlState createState() => _CarBodyControlState();
}

class _CarBodyControlState extends State<CarBodyControl> {
  final TitleItemsRepository _repo = TitleItemsRepository();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  List<Map<String, dynamic>> _titleItems = [];

  @override
  void initState() {
    super.initState();
    _fetchTitleItems();
  }

  // 获取所有标题项
  void _fetchTitleItems() async {
    final titleItems = await _repo.getAllTitleItems();
    setState(() {
      _titleItems = titleItems;
    });
  }

  // 添加标题项
  void _addTitleItem() async {
    final newTitleItem = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'imageUrl': _imageUrlController.text,
      'ip': _ipController.text,
      'port': int.tryParse(_portController.text) ?? 0,
    };

    await _repo.insertTitleItem(newTitleItem);
    _fetchTitleItems();  // 刷新列表

    // 清空输入框
    _titleController.clear();
    _descriptionController.clear();
    _imageUrlController.clear();
    _ipController.clear();
    _portController.clear();

    // 关闭输入框弹出框
    Navigator.pop(context);
  }

  // 编辑标题项
  void _editTitleItem(int id) async {
    final titleItem = await _repo.getTitleItemById(id);
    if (titleItem != null) {
      _titleController.text = titleItem['title'];
      _descriptionController.text = titleItem['description'];
      _imageUrlController.text = titleItem['imageUrl'];
      _ipController.text = titleItem['ip'] ?? '';
      _portController.text = titleItem['port'].toString();

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Edit Title Item"),
            content: Column(
              children: [
                TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Title')),
                TextField(controller: _descriptionController, decoration: InputDecoration(labelText: 'Description')),
                TextField(controller: _imageUrlController, decoration: InputDecoration(labelText: 'Image URL')),
                TextField(controller: _ipController, decoration: InputDecoration(labelText: 'IP (optional)')),
                TextField(controller: _portController, decoration: InputDecoration(labelText: 'Port')),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  final updatedTitleItem = {
                    'title': _titleController.text,
                    'description': _descriptionController.text,
                    'imageUrl': _imageUrlController.text,
                    'ip': _ipController.text,
                    'port': int.tryParse(_portController.text) ?? 0,
                  };

                  _repo.updateTitleItem(updatedTitleItem, id);
                  _fetchTitleItems(); // 刷新列表
                  Navigator.pop(context); // 关闭对话框
                },
                child: Text('Save'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
            ],
          );
        },
      );
    }
  }

  // 删除标题项
  void _deleteTitleItem(int id) async {
    await _repo.deleteTitleItem(id);
    _fetchTitleItems(); // 刷新列表
  }

  // 新增按钮
  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Title Item"),
          content: Column(
            children: [
              TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Title')),
              TextField(controller: _descriptionController, decoration: InputDecoration(labelText: 'Description')),
              TextField(controller: _imageUrlController, decoration: InputDecoration(labelText: 'Image URL')),
              TextField(controller: _ipController, decoration: InputDecoration(labelText: 'IP (optional)')),
              TextField(controller: _portController, decoration: InputDecoration(labelText: 'Port')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _addTitleItem,
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Title Items'),
      ),
      body: Column(
        children: [
          // 新增标题项按钮
          ElevatedButton(
            onPressed: _showAddDialog,
            child: Text('Add Title Item'),
          ),
          // 标题项列表
          Expanded(
            child: ListView.builder(
              itemCount: _titleItems.length,
              itemBuilder: (context, index) {
                final item = _titleItems[index];
                return ListTile(
                  title: Text(item['title']),
                  subtitle: Text(item['description']),
                  onTap: () => _editTitleItem(item['id']), // 编辑功能
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteTitleItem(item['id']), // 删除功能
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
