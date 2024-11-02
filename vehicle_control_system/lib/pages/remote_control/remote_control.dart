import 'package:flutter/material.dart';
import 'package:vehicle_control_system/pages/remote_control/car_body_control.dart';

class RemoteControl extends StatefulWidget {
  const RemoteControl({super.key});

  @override
  State<RemoteControl> createState() => _RemoteControlState();
}

class _RemoteControlState extends State<RemoteControl> {

  final List<Item> items = [
    Item(
      id:1,
      title: '智行者标准款',
      description: '这是描述1',
      imageUrl: 'https://www.itying.com/images/flutter/1.png',
    ),
    Item(
      id:2,
      title: '领航者标准款',
      description: '这是描述2',
      imageUrl: 'https://www.itying.com/images/flutter/1.png',
    ),
    Item(
      id:3,
      title: '风行者升降款',
      description: '这是描述3',
      imageUrl: 'https://www.itying.com/images/flutter/1.png',
    ),
    Item(
      id:4,
      title: '风行者标准款',
      description: '这是描述3',
      imageUrl: 'https://www.itying.com/images/flutter/1.png',
    ),
    Item(
      id:5,
      title: '神行者标准款',
      description: '这是描述3',
      imageUrl: 'https://www.itying.com/images/flutter/1.png',
    ),
    Item(
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CarBodyControl(title: items[index].title),
                  ),
                );

              },
            ),
          );
        },
      ),
    );
  }
}

class Item {
  final int id;
  final String title;
  final String description;
  final String imageUrl;

  Item({required this.id,required this.title, required this.description, required this.imageUrl});
}
