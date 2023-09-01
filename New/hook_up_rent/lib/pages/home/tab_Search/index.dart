/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-19 10:59:10
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-20 15:16:09
 * @FilePath: \hook_up_rent\lib\pages\home\tab_Search\index.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:flutter/material.dart';
import 'package:hook_up_rent/pages/home/tab_Search/dataList.dart';
import 'package:hook_up_rent/widgets/production_list_item_widget.dart';
import 'package:hook_up_rent/widgets/search_bar/index.dart';

class TabSearch extends StatelessWidget {
  const TabSearch({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SearchBarCustom(
          onSearch: () {
            Navigator.of(context).pushNamed('search');
          },
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 40.0,
            child: Text('filterbar'),
          ),
          Expanded(
              child: ListView(
            children: dataList
                .map((item) => ProductionListItemWidget(
                      data: item,
                    ))
                .toList(),
          ))
        ],
      ),
    );
  }
}
