/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-18 13:37:08
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-18 14:08:21
 * @FilePath: \hook_up_rent\lib\pages\home\tab_index\index_navigator_item.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:flutter/material.dart';

class IndexNavigatorItem {
  final String title;
  final String imageUri;
  final Function(BuildContext contenxt) onTap;
  IndexNavigatorItem(this.title, this.imageUri, this.onTap);
}

List<IndexNavigatorItem> navigatorItemList = [
  IndexNavigatorItem('首页', 'static/images/home.png',
      (contenxt) => {Navigator.of(contenxt).pushReplacementNamed('login')}),
  IndexNavigatorItem('数据', 'static/images/database.png',
      (contenxt) => {Navigator.of(contenxt).pushReplacementNamed('login')}),
];
