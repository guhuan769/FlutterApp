/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-25 14:14:37
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-05-23 08:50:38
 * @FilePath: \hook_up_rent\lib\pages\production\line_detail_control\line_detail_control_item\index.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hook_up_rent/pages/charts/horizontal_bar_label_chart.dart';
import 'package:hook_up_rent/pages/production/line_detail/line_detail_entity.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:hook_up_rent/pages/production/line_detail_control/line_detail_control_item/test_flow_delegate.dart';
import 'package:hook_up_rent/pages/utils/dio_http.dart';
import 'package:hook_up_rent/pages/utils/store.dart';
import 'package:hook_up_rent/widgets/common_image.dart';
import 'package:hook_up_rent/config.dart';

var textStyle = const TextStyle(
  color: Colors.black,
);

class LineDetailControlItem extends StatefulWidget {
  final LineDetailEntity data;

  const LineDetailControlItem({super.key, required this.data});

  @override
  State<LineDetailControlItem> createState() => _LineDetailControlItemState();
}

class _LineDetailControlItemState extends State<LineDetailControlItem> {
  // late TabController _tabController;
  List tabs = []; //"步骤1", "步骤2", "步骤3"
  bool IsShow = false;
  late Timer _timer;

  @override
  void initState() {
    // TODO: implement initState
    _onLoading();
    // var bbb = widget.data;
    // _timer = Timer.periodic(const Duration(seconds: 1), (timer) {});
    // super.initState();
  }

  void _onLoading() async {
    Store store = await Store.getInstance();
    var token = await store.getString(StoreKeys.token);
    const url = '/api/ProductionGetProductionDeviceInfoApp';
    var params = {'key': widget.data.key};
    var res = await DioHttp.of(context).put(url, params, token);
    var resMap = json.decode(res.toString());
    setState(() {
      for (var json in resMap["data"]) {}
    });
  }

  //根据线路ID 查询相关信息
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 8),
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flex(
                      direction: Axis.horizontal,
                      children: [
                        Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '设备名称 ',
                                      style: textStyle,
                                    ),
                                    Text(
                                      '${widget.data.deviceName}',
                                      style: textStyle,
                                    ),
                                    // Expanded(
                                    //   child: Text("123321"),
                                    // ),
                                    // Expanded(
                                    //     child: Container(
                                    //   child: Row(
                                    //     mainAxisAlignment: MainAxisAlignment.end,
                                    //     children: [
                                    //       Row(
                                    //         children: [
                                    //           // Text('更多 ', style: textStyle),
                                    //           TextButton(
                                    //             child: Text(!IsShow ? '更多' : '收起',
                                    //                 style: textStyle),
                                    //             onPressed: () {
                                    //               setState(() {
                                    //                 IsShow = !IsShow;
                                    //               });
                                    //             },
                                    //           ),
                                    //         ],
                                    //       )
                                    //     ],
                                    //   ),
                                    // ))
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '设备状态 ',
                                      style: textStyle,
                                    ),
                                    // Text(
                                    //   '${widget.data.runState}',
                                    //   style: textStyle,
                                    // ),
                                    if (widget.data.runStateInt == 1)
                                      Container(
                                        // width: 80,
                                        child: Row(
                                          children: [
                                            // Text('状态 ',
                                            //     style: textStyle),
                                            CommonImage(
                                              'static/images/run.png',
                                              width: 40,
                                              height: 40,
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (widget.data.runStateInt == 2)
                                      Container(
                                        // width: 80,
                                        child: Row(
                                          children: [
                                            // Text('状态 ',
                                            //     style: textStyle),
                                            CommonImage(
                                              'static/images/yellow.png',
                                              width: 40,
                                              height: 40,
                                            ),
                                          ],
    ),
                                      ),
                                    if (widget.data.runStateInt == 3)
                                      Container(
                                        // width: 80,
                                        child: Row(
                                          children: [
                                            // Text('状态 ',
                                            //     style: textStyle),
                                            CommonImage(
                                              'static/images/complete.png',
                                              width: 40,
                                              height: 40,
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (widget.data.runStateInt == 4)
                                      Container(
                                        // width: 80,
                                        child: Row(
                                          children: [
                                            // Text('状态 ',
                                            //     style: textStyle),
                                            CommonImage(
                                              'static/images/stop.png',
                                              width: 40,
                                              height: 40,
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            )),
                        Expanded(
                            child: Row(
                          children: [
                            CommonImage(
                              // 'static/images/yellow.png',
                              '${Config.BaseUrl}/api/${widget.data.deviceImg}',
                              width: 80,
                              height: 80,
                            ),
                          ],
                        ))
                      ],
                    )

                    // if (IsShow)
                    //   Container(
                    //       margin: const EdgeInsets.only(top: 5),
                    //       // decoration: BoxDecoration(color: Colors.red),
                    //       height: 300,
                    //       child: Center(
                    //         child: MaterialApp(
                    //           home: DefaultTabController(
                    //             length: tabs.length,
                    //             initialIndex: 0,
                    //             child: Scaffold(
                    //               appBar: AppBar(
                    //                 backgroundColor: Colors.green,
                    //                 title: const Text("工序管理"),
                    //                 bottom: TabBar(
                    //                     indicatorColor: Colors.white,
                    //                     tabs: tabs
                    //                         .map((e) => Tab(
                    //                               text: e,
                    //                             ))
                    //                         .toList()),
                    //               ),
                    //               body: Container(
                    //                 // decoration:
                    //                 // BoxDecoration(color: Colors.green),
                    //                 child: TabBarView(
                    //                   // labelColor:Colors.red
                    //                   children: tabs
                    //                       .map(
                    //                         (e) => Scrollbar(
                    //                           child: SingleChildScrollView(
                    //                               child: Container(
                    //                             child: Column(
                    //                               mainAxisAlignment:
                    //                                   MainAxisAlignment.start,
                    //                               children: <Widget>[
                    //                                 Container(
                    //                                   decoration: BoxDecoration(
                    //                                       color: Colors.green,
                    //                                       borderRadius:
                    //                                           BorderRadius
                    //                                               .circular(5)),
                    //                                   margin:
                    //                                       const EdgeInsets.all(
                    //                                           8),
                    //                                   padding:
                    //                                       const EdgeInsets.only(
                    //                                           left: 3,
                    //                                           right: 3),
                    //                                   height: 30,
                    //                                   child: Row(
                    //                                     mainAxisAlignment:
                    //                                         MainAxisAlignment
                    //                                             .spaceBetween,
                    //                                     children: [
                    //                                       Text('弯弓设备 ',
                    //                                           style: textStyle),
                    //                                       Text('运行中',
                    //                                           style: textStyle),
                    //                                     ],
                    //                                   ),
                    //                                 ),
                    //                               ],
                    //                             ),
                    //                           )),
                    //                         ),
                    //                       )
                    //                       .toList(),
                    //                 ),
                    //               ),
                    //             ),
                    //           ),
                    //         ),
                    //       ))
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _timer.cancel();
    super.dispose();
  }
}
