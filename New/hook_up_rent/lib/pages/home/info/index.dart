/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-18 17:13:30
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-05-18 09:55:44
 * @FilePath: \hook_up_rent\lib\pages\home\info\index.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:flutter/material.dart';
import 'package:hook_up_rent/pages/home/info/data.dart';
import 'package:hook_up_rent/pages/home/info/item_widget.dart';

class Info extends StatelessWidget {
  final bool showTitle;
  final List<productionLineStatistics>? dataList;
  final Function()? OnClick; //回退按钮函数
  const Info({super.key, this.showTitle = false, this.dataList, this.OnClick});

  @override
  Widget build(BuildContext context) {
    // @override
    // void initState() {
    //   // TODO: implement initState
    //   super.initState();
    // }
    return Padding(
      padding: EdgeInsets.all(9.0),
      child: Container(
      
        child: Column(
          children: [
            if (showTitle)
              Container(

                alignment: Alignment.centerLeft,
                padding: EdgeInsets.all(10.0),
                child: Text(
                  '线路统计列表',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w600),
                ),
              ),
            Column(
              children: dataList!
                  .map((item) => ItemWidget(
                            data: item,
                          )
                      // Container(
                      //       height: 100,
                      //       margin: EdgeInsets.only(bottom: 10.0),
                      //       decoration: BoxDecoration(color: Colors.red),
                      // )
                      )
                  .toList(),
            )
          ],
        ),
      ),
    );
  }
}
