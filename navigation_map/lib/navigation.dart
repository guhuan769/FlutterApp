import 'package:flutter/material.dart';
import 'package:navigation_map/Utils/common_toast.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  @override
  Widget build(BuildContext context) {
    return  Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "相对运行",
                  hintText: "请输入坐标",
                  prefixIcon: Icon(Icons.table_view),
                ),
              ),
            ),
            IconButton(onPressed: (){
              CommonToast.showToast('相对运行');
            }, icon: Icon(Icons.send)),
            // ElevatedButton(onPressed: (){}, child: Text('data'))
          ],
        ),
        Row(
          children: [
            const Expanded(
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "绝对运行",
                  hintText: "请输入坐标",
                  prefixIcon: Icon(Icons.table_view),
                ),
              ),
            ),
            IconButton(onPressed: (){
              CommonToast.showToast('绝对运行');
            }, icon: const Icon(Icons.send)),
            // ElevatedButton(onPressed: (){}, child: Text('data'))
          ],
        ),
        // Row(
        //   children: [
        //
        //   ],
        // ),
      ],
    );
  }
}
