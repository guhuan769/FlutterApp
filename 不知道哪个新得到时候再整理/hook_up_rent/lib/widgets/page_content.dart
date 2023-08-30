/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-16 14:35:27
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-18 15:36:50
 * @FilePath: \hook_up_rent\lib\widgets\page_content.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
//导入 material 依赖
import 'package:flutter/material.dart';
import 'package:hook_up_rent/routes.dart';

//编写无状态组件
class PageContent extends StatelessWidget {
  final String name;
  //添加参数Name
  const PageContent({super.key, required this.name});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('当前页面:$name')),
      body: ListView(
        children: <Widget>[
          TextButton(
            onPressed: () {
              // 处理按钮点击事件
              Navigator.pushNamed(context, Routes.home);
            },
            child: Text(Routes.home),
          ),
          TextButton(
            onPressed: () {
              // 处理按钮点击事件
              Navigator.pushNamed(context, Routes.login);
            },
            child: Text(Routes.login),
          ),
          TextButton(
            onPressed: () {
              // 处理按钮点击事件
              Navigator.pushNamed(context, '/error');
            },
            child: Text('不存在的页面'),
          ),
          TextButton(
            onPressed: () {
              // 处理按钮点击事件
              Navigator.pushNamed(context, '/production/3333');
            },
            child: Text('生产明细页 id :3333'),
          ),
        ],
      ),
    );
  }
}
