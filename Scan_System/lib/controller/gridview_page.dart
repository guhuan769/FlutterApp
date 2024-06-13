import 'package:flutter/material.dart';
import 'package:scan_system/Utils/common_toast.dart';

class GridviewPage extends StatefulWidget {
  //TODO:传入菜单数据
  const GridviewPage({super.key});

  @override
  State<GridviewPage> createState() => _GridviewPageState();
}

class _GridviewPageState extends State<GridviewPage> {
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
        itemCount: 3, // 数据项的数量
        itemBuilder: (context, index) => Container(
            width: 100,
            height: 100,
            margin: const EdgeInsets.all(5.0),
            padding: const EdgeInsets.all(0.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent),
            ),
            child: SizedBox(
              width: double.infinity, // 设置宽度为无穷大
              height: double.infinity, // 设置高度为无穷大
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.green, // 设置背景颜色为红色
                ),
                child: ElevatedButton(onPressed:(){
                  CommonToast.showToast('msg');
                }, child: const Text('IP配置')),
              ),
              // IconButton(
              //   onPressed: () async {},
              //   icon: const Icon(Icons.settings),
              //   color: Colors.green,
              // ),
            )),
      ),
    ));
  }
}
