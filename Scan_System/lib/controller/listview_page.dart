import 'package:flutter/material.dart';

class ListviewPage extends StatefulWidget {
  const ListviewPage({super.key});

  @override
  State<ListviewPage> createState() => _ListviewPageState();
}

class _ListviewPageState extends State<ListviewPage> {
  @override
  Widget build(BuildContext context) {
    return Scrollbar(
        child: Center(
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 设置每行的列数
          childAspectRatio: 1.0, // 设置子元素的宽高比例
          mainAxisSpacing: 10.0, // 设置主轴间距
          crossAxisSpacing: 10.0, // 设置交叉轴间距
        ),
        itemCount: 10, // 数据项的数量
        itemBuilder: (context, index) => ListTile(
          title: Text('Item1 $index'),
        ),
      ),
    )

        // ListView.builder(
        //   itemCount: 1, // 假设您有一些数据
        //   itemBuilder: (context, index) {
        //
        //       Row(
        //       children: <Widget>[
        //
        //         Expanded(
        //           flex: 1,
        //           child: Container(
        //             width: 100,
        //             height: 100,
        //             margin: const EdgeInsets.all(5.0),
        //             padding: const EdgeInsets.all(0.0),
        //             decoration: BoxDecoration(
        //               border: Border.all(color: Colors.blueAccent),
        //             ),
        //             // 设置第一列的内容
        //             child: (),
        //           ),
        //         ),
        //         Expanded(
        //           flex: 1,
        //           child: Container(
        //             // 设置第二列的内容
        //             child: Text('description'),
        //           ),
        //         ),
        //         Expanded(
        //           flex: 1,
        //           child: Container(
        //             // 设置第三列的内容
        //             child: Text('price'),
        //           ),
        //         ),
        //       ],
        //     );
        //   },
        // ),
        );
  }
}
