/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-20 15:00:34
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-20 15:49:07
 * @FilePath: \hook_up_rent\lib\widgets\production_List_Item_Widget.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */

import 'package:flutter/material.dart';
import 'package:hook_up_rent/pages/home/info/item_widget.dart';
import 'package:hook_up_rent/pages/home/tab_Search/dataList.dart';
import 'package:hook_up_rent/widgets/common_image.dart';
import 'package:hook_up_rent/widgets/common_tag.dart';

class ProductionListItemWidget extends StatelessWidget {
  final ProductionListItemData data;

  const ProductionListItemWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
      child: Row(
        children: [
          CommonImage(
            data.imageUri,
            width: 32.5,
            height: 100,
          ),
          Padding(padding: EdgeInsets.only(left: 10.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title, maxLines: 1,
                  //文本省略号
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  data.subTitle, maxLines: 1,
                  //文本省略号
                  overflow: TextOverflow.ellipsis,
                ),
                //Wrap得好处是可以换下一行
                Wrap(
                  children: data.tags
                      .map((e) => CommonTag.origin(
                            title: e,
                            backgroundColor: Colors.red,
                          ))
                      .toList(),
                ),
                Text('${data.price}'),
              ],
            ),
          )
        ],
      ),
    );
  }
}
