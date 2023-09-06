/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-05-20 09:07:59
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-05-22 11:28:15
 * @FilePath: \hook_up_rent\lib\pages\production\line_detail_control\line_process_management.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hook_up_rent/pages/home/info/data.dart';
import 'package:hook_up_rent/pages/production/line_detail_control/entity/ProcessManagementByCodeResponse.dart';
import 'package:hook_up_rent/pages/utils/common_toast.dart';
import 'package:hook_up_rent/pages/utils/dio_http.dart';
import 'package:hook_up_rent/pages/utils/store.dart';
import 'package:hook_up_rent/widgets/common_image.dart';

var textStyle = const TextStyle(
  color: Colors.black,
);

class LineProcessManagement extends StatefulWidget {
  final String detailId;

  const LineProcessManagement({super.key, required this.detailId});

  @override
  State<LineProcessManagement> createState() => _LineProcessManagementState();
}

class _LineProcessManagementState extends State<LineProcessManagement> {
  // List tabs = ["步骤1", "步骤2", "步骤3"];
  List<ProcessManagementByCodeResponse> tabs = [];
  bool IsShow = false;
  int i = 0;
  late Timer _timer;

  @override
  void initState() {
    // TODO: implement initState
    _onLoading();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      // CommonToast.showToast("msg");
      i = 0;
      _onLoading();
    });
    // Future.delayed(Duration(seconds: 2), () => _onLoading());
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _timer.cancel();
    super.dispose();
  }

  void _onLoading() async {
    Store store = await Store.getInstance();
    var token = await store.getString(StoreKeys.token);
    const url = '/api/LineProcessManagementByCode'; //查询工序步骤
    var params = {'key': widget.detailId};
    var res = await DioHttp.of(context).putFormData(url, params, token);
    var resMap = json.decode(res.toString());
    setState(() {
      tabs = [];
      for (var json in resMap["data"]) {
        tabs.add(ProcessManagementByCodeResponse.fromJson(json));
        var jsonResMap = json["pubProcessManagements"];
        // for( int i = 0; i < jsonResMap.length,i++ ) {
        for (var jsonentity in jsonResMap) {
          var entity = CustomPubProcessManagementForm.fromJson(jsonentity);
          tabs[i].pubProcessManagements.add(entity);
        }
        i++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.all(8),
        // decoration: BoxDecoration(color: Colors.red),
        height: 300,
        child: Center(
          child: MaterialApp(
            home: DefaultTabController(
              length: tabs.length,
              initialIndex: 0,
              child: Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  title: Text("工序管理", style: textStyle),
                  bottom: TabBar(
                      indicatorColor: Colors.green,
                      tabs: tabs
                          .map((e) => Text(e.tName, style: textStyle))
                          .toList()),
                ),
                body: Container(
                  child: TabBarView(
                    children: tabs
                        .map(
                          (e) => Scrollbar(
                            child: SingleChildScrollView(
                                child: Container(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: e.pubProcessManagements
                                    .map(
                                      (e) => Container(
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(5)),
                                        margin: const EdgeInsets.all(8),
                                        padding: const EdgeInsets.only(
                                            left: 3, right: 3),
                                        height: 30,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              width: 80,
                                              child: Row(
                                                children: [
                                                  // Text('名称 ', style: textStyle),
                                                  Text('${e.tName} ',
                                                      style: textStyle),
                                                ],
                                              ),
                                            ),
                                            if (e.runtstatus == 1)
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
                                            if (e.runtstatus == 2)
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
                                            if (e.runtstatus == 3)
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
                                            if (e.runtstatus == 4)
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
                                            // const BottomNavigationBarItem(icon: Icon(Icons.data_array_sharp), label: '产量'),
                                            // BottomNavigationBarItem(icon: icon),
                                            // Text('${e.runtstatusName}',
                                            //     style: textStyle),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            )),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
