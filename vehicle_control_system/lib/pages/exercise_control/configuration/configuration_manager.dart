import 'package:flutter/material.dart';
import 'package:vehicle_control_system/data/models/title_item.dart';
import 'package:get/get.dart';

class ConfigurationManager extends StatefulWidget {
  const ConfigurationManager({super.key});

  @override
  State<ConfigurationManager> createState() => _ConfigurationManagerState();
}

class _ConfigurationManagerState extends State<ConfigurationManager> {

  final List<TitleItem> items = [
    TitleItem(
      id:1,
      title: '焊接实时配置',
      description: '这是描述1这是描述1这是描述1这是描述1这是描述1这是描述1这是描述1这是描述1这是描述1',
      imageUrl: 'https://www.itying.com/images/flutter/1.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('配置管理')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              contentPadding: EdgeInsets.all(10.0),
              leading: Image.network(items[index].imageUrl),
              title: Text(items[index].title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Text(items[index].description),
              isThreeLine: true,
              onTap: () {
                print(items[index].title);
                //实现增删改查
                // Get.toNamed('/car_body_control', arguments: {'title': items[index].title});
                Get.toNamed('/welding_real_time_configuration_panel', arguments: {'title': items[index].title});
              },
            ),
          );
        },
      ),
    );
  }
}
