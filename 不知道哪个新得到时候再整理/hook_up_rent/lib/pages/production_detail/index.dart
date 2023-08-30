/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-17 10:32:56
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-19 11:48:29
 * @FilePath: \hook_up_rent\lib\pages\production_detail\index.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%A
 */

import 'package:flutter/material.dart';

class ProductionDetailPage extends StatelessWidget {
  final String detailId;
  const ProductionDetailPage({super.key, required this.detailId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('detailid:$detailId'),
      ),
    );
  }
}
