/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-25 14:14:37
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-29 13:32:05
 * @FilePath: \hook_up_rent\lib\pages\production\line_detail_control\line_detail_control_item\index.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:flutter/material.dart';
import 'package:hook_up_rent/pages/charts/horizontal_bar_label_chart.dart';
import 'package:hook_up_rent/pages/production/line_detail/line_detail_entity.dart';
import 'package:charts_flutter/flutter.dart' as charts;

var textStyle = TextStyle(color: Colors.white);

class LineDetailControlItem extends StatelessWidget {
  final LineDetailEntity data;
  const LineDetailControlItem({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 80,
        decoration: BoxDecoration(color: Colors.green),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '设备名称 ',
                          style: textStyle,
                        ),
                        Text(
                          '${data.deviceName}',
                          style: textStyle,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '设备状态 ',
                          style: textStyle,
                        ),
                        Text(
                          '${data.runState}',
                          style: textStyle,
                        ),
                      ],
                    ),
                    // Container(
                    //   height: 100,
                    //   decoration: BoxDecoration(color: Colors.red),
                    //   child: 
                    // )
                  ],
                )),
              ],
            )
          ],
        ),
      ),
    );
  }
}
