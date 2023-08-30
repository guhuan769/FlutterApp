/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-18 13:04:19
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-25 15:13:25
 * @FilePath: \hook_up_rent\lib\pages\tab_index\index.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE1
 */
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hook_up_rent/pages/home/info/data.dart';
import 'package:hook_up_rent/pages/home/info/index.dart';
import 'package:hook_up_rent/pages/home/tab_index/index_navigator.dart';
import 'package:hook_up_rent/pages/utils/dio_http.dart';
import 'package:hook_up_rent/pages/utils/store.dart';
import 'package:hook_up_rent/widgets/search_bar/index.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:pull_to_refresh/pull_to_refresh.dart';

class TabIndex extends StatefulWidget {
  const TabIndex({super.key});

  static const List<Tab> myTabs = <Tab>[
    Tab(text: '线路统计列表'),
    // Tab(text: '设备统计列表'),
  ];

  @override
  State<TabIndex> createState() => _TabIndexState();
}

class _TabIndexState extends State<TabIndex> {
  final List<productionLineStatistics> dataList = [];
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  // _TabIndexState() {
  //   dataList.add(infoItem(
  //       title:
  //           'title1title1title1title1title1title1title1title1title1title1title1title1title1title1title1title1',
  //       imageUri: 'static/images/home.png',
  //       source: 'source',
  //       time: '2天前',
  //       navigateUri: 'login'));
  // }

  void _init() async {
    Store store = await Store.getInstance();
    var token = await store.getString(StoreKeys.token);
    // Map<String, dynamic> decodedToken = await JwtDecoder.decode(token);
    _refreshData();
  }

  Future<void> _refreshData() async {
    Store store = await Store.getInstance();
    var token = await store.getString(StoreKeys.token);
    Map<String, dynamic> decodedToken = await JwtDecoder.decode(token);

    const url = '/api/ProductionGetProductionLineInfoApp';
    var res = await DioHttp.of(context).put(url, null, token);
    var resMap = json.decode(res.toString());
    setState(() {
      dataList.clear();
      for (var json in resMap["data"]) {
        dataList.add(productionLineStatistics.fromJson(json));
      }
    });
    // _refreshController.refreshCompleted();
    _refreshController.requestRefresh();
    await Future.delayed(Duration(milliseconds: 1000));
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    // monitor network fetch
    await Future.delayed(Duration(milliseconds: 1000));
    // if failed,use loadFailed(),if no data return,use LoadNodata()
    // items.add((items.length+1).toString());
    if (mounted)
      setState(() {
        // dataList.add(productionLineStatistics('3', '4', 0, 0, 0, 0));
        // _refreshData();
      });
    // _refreshController.loadNoData();
    _refreshController.loadNoData();
    // _refreshController.canLoading();
    // _refreshController.loadNoData();
  }

  @override
  void initState() {
    //解析toke
    // TODO: implement initState
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: TabIndex.myTabs.length,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: TabIndex.myTabs,
          ),
          title: Text('产量'),
          // SearchBarCustom(
          //   onSearch: () {
          //     Navigator.of(context).pushNamed('search');
          //   },
          // ),
          // backgroundColor: Colors.white,
          //Container(
          //child: IconButton(onPressed: () {}, icon: Icon(Icons.add),),
          //decoration:BoxDecoration(color: Colors.red),
          //),
          // body:Text('data')
        ),
        body: TabBarView(children: [
          SmartRefresher(
            onRefresh: _refreshData,
            enablePullDown: true,
            enablePullUp: true,
            controller: _refreshController,
            onLoading: _onLoading,
            header: WaterDropHeader(),
            //     CustomHeader(
            //   builder: (BuildContext context, RefreshStatus? mode) {
            //     return Container(
            //       height: 55.0,
            //       child: Center(child: Text("刷新")),
            //     );
            //   },
            // ), //WaterDropHeader()
            footer: CustomFooter(
              builder: (BuildContext context, LoadStatus? mode) {
                Widget body;
                if (mode == LoadStatus.idle) {
                  body = Text("上拉加载");
                } else if (mode == LoadStatus.loading) {
                  body = CupertinoActivityIndicator();
                } else if (mode == LoadStatus.failed) {
                  body = Text("加载失败！点击重试！");
                } else if (mode == LoadStatus.canLoading) {
                  body = Text("松手,加载更多!");
                } else {
                  body = Text("没有更多数据了!");
                }
                return Container(
                  height: 55.0,
                  child: Center(child: body),
                );
              },
            ),
            child: ListView(
              // scrollDirection: ,
              children: [
                // IndexNavigator(),//禁用首页菜单
                Info(
                  showTitle: false,
                  dataList: dataList,
                ),
                // Text('这里是内容区域'),
              ],
            ),
          ),
          // ListView(
          //   children: [
          //     // IndexNavigator(),//禁用首页菜单
          //     // Info(showTitle: true),
          //     Text('132132'),
          //   ],
          // ),
        ]),
      ),
    );
  }
}
