/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-24 15:35:30
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-29 13:27:48
 * @FilePath: \hook_up_rent\lib\pages\production\line_detail\index.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hook_up_rent/pages/charts/horizontal_bar_label_chart.dart';
import 'package:hook_up_rent/pages/production/line_detail/line_detail_entity.dart';
import 'package:hook_up_rent/pages/production/line_detail_control/index.dart';
import 'package:hook_up_rent/pages/utils/dio_http.dart';
import 'package:hook_up_rent/pages/utils/store.dart';

class LineDetail extends StatefulWidget {
  final String detailId;
  const LineDetail({super.key, required this.detailId});

  @override
  State<LineDetail> createState() => _LineDetailState();
}

class _LineDetailState extends State<LineDetail> {
  final List<LineDetailEntity> lines = [];
  void _onLoading() async {
    Store store = await Store.getInstance();
    var token = await store.getString(StoreKeys.token);
    const url = '/api/ProductionGetProductionDeviceInfoApp';
    var params = {'key': widget.detailId};
    var res = await DioHttp.of(context).put(url, params, token);
    var resMap = json.decode(res.toString());
    setState(() {
      for (var json in resMap["data"]) {
        lines.add(LineDetailEntity.fromJson(json));
      }
    });
  }

  @override
  void initState() {
    //初始化数据
    // TODO: implement initState
    _onLoading();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设备列表'), //${widget.detailId}
      ),
      body: ListView(
        children: [
          LineDetailControl(
            showTitle: true,
            dataList: lines,
            detailId: widget.detailId,
          ),
        ],
      ),
    );
  }
}
