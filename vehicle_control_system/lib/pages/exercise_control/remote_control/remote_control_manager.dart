import 'package:flutter/material.dart';
import 'package:vehicle_control_system/data/models/title_item.dart';
import 'package:get/get.dart';

class RemoteControlManager extends StatefulWidget {
  const RemoteControlManager({super.key});

  @override
  State<RemoteControlManager> createState() => _RemoteControlState();
}

class _RemoteControlState extends State<RemoteControlManager> {

  final List<TitleItem> items = [
    TitleItem(
      id:1,
      title: '智行者标准款',
      description: '这是描述1',
      imageUrl: 'https://www.itying.com/images/flutter/1.png',
    ),
    TitleItem(
      id:2,
      title: '领航者标准款',
      description: '这是描述2',
      imageUrl: 'https://www.itying.com/images/flutter/1.png',
    ),
    TitleItem(
      id:3,
      title: '风行者升降款',
      description: '这是描述3',
      imageUrl: 'https://www.itying.com/images/flutter/1.png',
    ),
    TitleItem(
      id:4,
      title: '风行者标准款',
      description: '这是描述3',
      imageUrl: 'https://www.itying.com/images/flutter/1.png',
    ),
    TitleItem(
      id:5,
      title: '神行者标准款',
      description: '这是描述3',
      imageUrl: 'https://www.itying.com/images/flutter/1.png',
    ),
    TitleItem(
      id:6,
      title: '履行者标准款',
      description: '这是描述3',
      imageUrl: 'https://www.itying.com/images/flutter/1.png',
    ),
    // 可以添加更多项
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('遥控器')),
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
                // Get.toNamed('/robotic_control_manager');
                // 导航到目标页面并传递参数

                switch(index)
                {
                  case 0:
                    Get.toNamed('/navigation', arguments: {'title': items[index].title});
                    break;
                  case 1:
                    Get.toNamed('/navigation', arguments: {'title': items[index].title});
                    break;
                  case 2:
                    break;
                  default:
                    Get.toNamed('/car_body_control', arguments: {'title': items[index].title});
                    break;
                }


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

