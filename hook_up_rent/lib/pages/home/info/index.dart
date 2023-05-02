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
      padding: EdgeInsets.all(9),
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
