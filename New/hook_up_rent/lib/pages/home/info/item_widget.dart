/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-19 09:52:18
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-05-22 09:19:49
 * @FilePath: \hook_up_rent\lib\pages\home\info\item_widget.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:flutter/material.dart';
import 'package:hook_up_rent/pages/home/info/data.dart';

var textStyle = TextStyle(color: Colors.black);
var textStyleButton = TextStyle(color: Colors.green);

class ItemWidget extends StatelessWidget {
  final productionLineStatistics data;

  const ItemWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/linedetail/${data.key}');
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
            height: 60.0,
            // padding: EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
            child: Row(
              children: [
                // CommonImage(
                //   data.imageUri,
                //   width: 120.0,
                //   height: 90.0,
                // ),
                // Padding(padding: EdgeInsets.only(left: 10.0)),
                Expanded(
                    child: Column(
                  //  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flex(
                      direction: Axis.horizontal,
                      children: [
                        Expanded(
                          flex: 22,
                          child: Container(
                            height: 60.0,
                            color: Colors.white,
                            // decoration: BoxDecoration(borderRadius: BorderRadius(Radius.circular(5))),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Column(
                                      children: [
                                        Text('        线路 ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            )),
                                      ],
                                    ),
                                    Text(data.lineName!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        )),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '今日产量 ',
                                      style: textStyle,
                                    ),
                                    Text(
                                      '${data.todayYield}',
                                      style: textStyle,
                                    ),
                                    Text(
                                      '    周产量 ',
                                      style: textStyle,
                                    ),
                                    Text(
                                      '${data.weekYield}',
                                      style: textStyle,
                                    ),
                                    Text(
                                      '    年产量 ',
                                      style: textStyle,
                                    ),
                                    Text(
                                      '${data.yearYield}',
                                      style: textStyle,
                                    ),
                                    // Row(
                                    //   // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    //   children: [
                                    //     Text(
                                    //       '今日产量 ',
                                    //       style: textStyle,
                                    //     ),
                                    //     Text(
                                    //       '${data.todayYield}',
                                    //       style: textStyle,
                                    //     ),
                                    //     // Text(
                                    //     //   data.time,
                                    //     //   style: textStyle,
                                    //     // ),
                                    //   ],
                                    // ),
                                    // Row(
                                    //   // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    //   children: [
                                    //     Text(
                                    //       '    周产量 ',
                                    //       style: textStyle,
                                    //     ),
                                    //     Text(
                                    //       '${data.weekYield}',
                                    //       style: textStyle,
                                    //     ),
                                    //     // Text(
                                    //     //   data.time,
                                    //     //   style: textStyle,
                                    //     // ),
                                    //   ],
                                    // ),
                                    // Row(
                                    //   // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    //   children: [
                                    //     Text(
                                    //       '    年产量 ',
                                    //       style: textStyle,
                                    //     ),
                                    //     Text(
                                    //       '${data.yearYield}',
                                    //       style: textStyle,
                                    //     ),
                                    //     // Text(
                                    //     //   data.time,
                                    //     //   style: textStyle,
                                    //     // ),
                                    //   ],
                                    // ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                              height: 60.0,
                              color: Colors.white,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Text('...', style:textStyleButton),
                                    ],
                                  )
                                ],
                              )),
                        ),
                      ],
                    )
                  ],
                )),
              ],
            )),
      ),
    );
  }
}
