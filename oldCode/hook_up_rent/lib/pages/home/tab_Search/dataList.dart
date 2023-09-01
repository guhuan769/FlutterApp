/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-20 10:45:26
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-20 15:21:08
 * @FilePath: \hook_up_rent\lib\pages\home\tab_Search\dataList.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:flutter/material.dart';

class ProductionListItemData {
  final String id;
  final String title;
  final String subTitle;
  final String imageUri;
  final List<String> tags;
  final int price;

  ProductionListItemData(
      this.id, this.title, this.subTitle, this.imageUri, this.tags, this.price);
}

List<ProductionListItemData> dataList = [
  ProductionListItemData('production/1', 'title1title1title1title1title1title1title1title1title1title1title1title1title1', 'subTitle',
      'static/images/user.png', ['附近', '附近1'], 1110),
  ProductionListItemData('production/2', 'title2', 'subTitle',
      'static/images/user.png', ['附近', '附近1'], 2222),
  ProductionListItemData('production/3', 'title3', 'subTitle',
      'static/images/user.png', ['附近', '附近1'], 3333),
  ProductionListItemData('production/4', 'title4', 'subTitle',
      'static/images/user.png', ['附近', '附近1'], 4444),
  ProductionListItemData('production/5', 'title5', 'subTitle',
      'static/images/user.png', ['附近', '附近1'], 55555),
  ProductionListItemData('production/6', 'title6', 'subTitle',
      'static/images/user.png', ['附近', '附近1'], 6666),
  ProductionListItemData('production/7', 'title7', 'subTitle',
      'static/images/user.png', ['附近', '附近1'], 7777),
];
