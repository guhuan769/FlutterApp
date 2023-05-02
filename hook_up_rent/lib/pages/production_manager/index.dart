import 'package:flutter/material.dart';
import 'package:hook_up_rent/pages/home/tab_Search/dataList.dart';
import 'package:hook_up_rent/widgets/production_list_item_widget.dart';

class ProductionManagerPage extends StatelessWidget {
  const ProductionManagerPage({super.key});

  //可以使用构造初始化

  static const List<Tab> myTabs = <Tab>[
    Tab(text: '工单列表'),
    Tab(text: '待开发'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: myTabs.length,
      initialIndex: 0,
      child: Scaffold(
        //居中按钮
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        //按钮浮动
        floatingActionButton: GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed('productionorderAdd');
          },
          child: Container(
            height: 40,
            decoration: BoxDecoration(
                color: Colors.green, borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(20),
            child: Center(
              child: Text(
                '新增',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        appBar: AppBar(
          title: Text('生产管理子系统'),
          bottom: const TabBar(
            tabs: myTabs,
          ),
        ),
        body: TabBarView(children: [
          ListView(
            children: dataList
                .map((item) => ProductionListItemWidget(
                      data: item,
                    ))
                .toList(),
          ),
          ListView(
            children: dataList
                .map((item) => ProductionListItemWidget(
                      data: item,
                    ))
                .toList(),
          ),
        ]),
      ),
    );
  }
}
