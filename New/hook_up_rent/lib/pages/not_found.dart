//添加依赖
import 'package:flutter/material.dart';

//添加无状态组件
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('404'),
        ),
        body: Center(child: Text('你访问的页面还不存在!')));
  }
}
