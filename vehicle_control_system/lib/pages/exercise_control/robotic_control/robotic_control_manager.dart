import 'package:flutter/material.dart';
import 'package:vehicle_control_system/data/models/title_item.dart';
import 'package:get/get.dart';

class RoboticControlManager extends StatefulWidget {
  const RoboticControlManager({super.key});

  @override
  State<RoboticControlManager> createState() => _RemoteControlState();
}

class _RemoteControlState extends State<RoboticControlManager> {

  final List<TitleItem> items = [
    TitleItem(
      id:1,
      title: '法拉科',
      description: '这是描述1',
      imageUrl: 'https://www.itying.com/images/flutter/1.png',
    ),
    TitleItem(
      id:2,
      title: '川崎',
      description: '这是描述2',
      imageUrl: 'https://www.itying.com/images/flutter/1.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('机器人运动控制管理')),
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
                Get.toNamed('/roboti_control_panel', arguments: {'title': items[index].title});

                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => CarBodyControl(title: items[index].title),
                //   ),
                // );

              },
            ),
          );
        },
      ),
    );
  }
}

