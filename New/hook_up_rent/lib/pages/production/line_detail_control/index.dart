/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-25 14:11:21
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-05-23 11:51:02
 * @FilePath: \hook_up_rent\lib\pages\production\line_detail_control\index.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hook_up_rent/pages/charts/horizontal_bar_label_chart.dart';
import 'package:hook_up_rent/pages/home/info/data.dart';
import 'package:hook_up_rent/pages/production/line_detail/line_detail_entity.dart';
import 'package:hook_up_rent/pages/production/line_detail_control/line_detail_control_item/index.dart';
import 'package:hook_up_rent/pages/production/line_detail_control/line_process_management.dart';
import 'package:hook_up_rent/pages/utils/dio_http.dart';
import 'package:hook_up_rent/pages/utils/store.dart';
import 'package:hook_up_rent/widgets/common_image.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

var textStyle = const TextStyle(
  color: Colors.black,
);

class LineDetailControl extends StatefulWidget {
  final bool showTitle;
  final List<LineDetailEntity>? dataList;
  final String detailId;

  const LineDetailControl(
      {super.key,
      required this.showTitle,
      this.dataList,
      required this.detailId});

  @override
  State<LineDetailControl> createState() => _LineDetailControlState();
}

class _LineDetailControlState extends State<LineDetailControl> {
  late productionLineStatistics lineDetail =
      productionLineStatistics('', 'lineName', 0, 0, 0, 0);
  void _init() async {
    Store store = await Store.getInstance();
    var token = await store.getString(StoreKeys.token);
    Map<String, dynamic> decodedToken = await JwtDecoder.decode(token);

    const url = '/api/ProductionGetProductionLineInfoApps';
    var params = {'key': widget.detailId};
    var res = await DioHttp.of(context).put(url, params, token);
    var resMap = json.decode(res.toString());
    var dataEntity = resMap["dataEntity"];

    setState(() {
      lineDetail = productionLineStatistics(
          dataEntity['key'],
          dataEntity['lineName'],
          dataEntity['todayYield'],
          dataEntity['weekYield'],
          dataEntity['monthYield'],
          dataEntity['yearYield']);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          if (widget.showTitle)
            Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.all(10.0),
              child: Text(
                '设备列表',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
              ),
            ),
          Padding(
            //报表图
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 100,
              decoration: BoxDecoration(color: Colors.white),
              child: HorizontalBarLabelChart.withSampleData(lineDetail),
            ),
          ),
          Padding(
            //工序
            padding: const EdgeInsets.all(8.0),
            child: Container(
              child: Row(
                children: [
                  Text('正常 ', style: textStyle),
                  CommonImage(
                    'static/images/run.png',
                    width: 40,
                    height: 40,
                  ),
                  Text('停止 ', style: textStyle),
                  CommonImage(
                    'static/images/yellow.png',
                    width: 40,
                    height: 40,
                  ),
                  // Text('已完成 ', style: textStyle),
                  // CommonImage(
                  //   'static/images/complete.png',
                  //   width: 40,
                  //   height: 40,
                  // ),
                  Text('故障 ', style: textStyle),
                  CommonImage(
                    'static/images/stop.png',
                    width: 40,
                    height: 40,
                  ),
                ],
              ),
            ),
          ),
          // //工序管理
          // Padding(
          //   //工序
          //   padding: const EdgeInsets.all(0.0),
          //   child: Container(
          //     decoration: BoxDecoration(color: Colors.white),
          //     child: LineProcessManagement(
          //       detailId: widget.detailId,
          //     ),
          //   ),
          // ),
          Column(
            children: [
              if (widget.dataList!.length == 0) Text('没有相关设备信息'),
            ],
          ),
          Column(
            children: widget.dataList!
                .map((e) => LineDetailControlItem(
                      data: e,
                    ))
                .toList(),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
}
