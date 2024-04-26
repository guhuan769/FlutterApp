/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-16 14:50:34
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-23 11:07:02
 * @FilePath: \hook_up_rent\lib\pages\home\index.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_app_update/azhon_app_update.dart';
import 'package:flutter_app_update/update_model.dart';
import 'package:hook_up_rent/config.dart';
import 'package:hook_up_rent/pages/home/tab_Search/index.dart';
import 'package:hook_up_rent/pages/home/tab_index/index.dart';
import 'package:hook_up_rent/pages/home/tab_info/index.dart';
import 'package:hook_up_rent/pages/home/tab_profile/index.dart';
import 'package:hook_up_rent/pages/model/version_model.dart';
import 'package:hook_up_rent/pages/utils/dio_http.dart';
import 'package:hook_up_rent/widgets/common_image.dart';
import 'package:hook_up_rent/widgets/page_content.dart';
import 'package:hook_up_rent/pages/utils/store.dart';
import 'package:package_info_plus/package_info_plus.dart';

//需要准备 4个内容块  shared_preferences
List<Widget> tabViewList = [
  TabIndex(),
  // TabSearch(),
  // TabInfo(),
  TabProfile(),
];
//
List<BottomNavigationBarItem> barItemList = [
  // BottomNavigationBarItem(
  //     icon: CommonImage(
  //       'static/images/database.png',
  //       width: 16,
  //       height: 16,
  //     ),
  //     label: '产量'),
  BottomNavigationBarItem(icon: Icon(Icons.data_array_sharp), label: '产量'),
  // BottomNavigationBarItem(icon: Icon(Icons.search), label: '搜索'),
  // BottomNavigationBarItem(icon: Icon(Icons.info), label: '资讯'),
  BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: '我的'),
];

//有状态组件
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  bool _isDownload = false;
  double _currentRatio = 0.0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    //
    super.initState();
  }

  _updateApp(context) async {
    Store store = await Store.getInstance();
    var token = await store.getString(StoreKeys.token);
    const url = '/api/VersionGetAppVersion';
    var res;
    res = await DioHttp.of(context).get(url, null, token);
    var resMap = json.decode(res.toString());
    var dataEntity = resMap["dataEntity"];
    var code = resMap["code"];
    var msg = resMap["msg"] ?? '内部错误';
    // print("shuJu:${jsonEncode(resMap["data"])}");
    if (code == 0) {
      // VersionModel model = VersionModel.fromJson(resMap['data']);
      var version = resMap['data'][0]["version"];
      PackageInfo info = await PackageInfo.fromPlatform();
      if (version != info.version) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (content) {
              return Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("发现新版本",style: TextStyle(color: Colors.black54),),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text("发现新版本$version 更新内容待扩展...",style: TextStyle(color: Colors.black54),),
                      ),
                      _isDownload
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Container(
                                width: 215,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.cyan,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 215 * _currentRatio,
                                      decoration: BoxDecoration(
                                        color: Colors.cyanAccent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: Center(
                                        child: Text(
                                          "${(_currentRatio * 100).toInt()}%",
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : InkWell(
                              onTap: () {
                                // Navigator.pop(context);

                                //String url =
                                 //   "${Config.BaseUrl}/api/FileDownload/Download?subDirectory=${resMap['data'][0]["path"]}";

                                String url =
                                    "${Config.BaseUrl}/api/FileDownload/Download?subDirectory=${resMap['data'][0]["path"]}";
                                UpdateModel updateModel = UpdateModel(
                                  url,
                                  "app-release.apk",
                                  "ic_launcher",
                                  "",
                                  showBgdToast: false,
                                );
                                setState(() {
                                  _isDownload = true;
                                });
                                //下载
                                AzhonAppUpdate.update(updateModel)
                                    .then((value) {});
                                AzhonAppUpdate.listener((map) {
                                  if (map["type"] == "downloading") {
                                    //下载进度
                                    setState(() {
                                      _currentRatio =
                                          map["progress"] / map["max"];
                                      if (_currentRatio == 1.0) {
                                        _currentRatio = 0.0;
                                      }
                                    });
                                  } else if (map["type"] == "done") {
                                    //下载完成
                                    setState(() {
                                      _isDownload = false;
                                      _currentRatio = 0.0;
                                    });
                                  } else if (map["type"] == "error") {
                                    //下载出错
                                    setState(() {
                                      _isDownload = false;
                                      _currentRatio = 0.0;
                                    });
                                  }
                                });
                              },
                              child: Container(
                                height: 60,
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey,
                                        width: 1,
                                  ),
                                ),
                                child: Center(child: Text("点击我更新",style: TextStyle(color: Colors.black54,fontSize: 20))),
                              ),
                            ),
                    ],
                  ),
                ),
              );
            });
      }
    }
  }

// void checkVersion() {
//   const url = '/api/LoginLoginByUserNameAndPwd';
//   DioHttp.of(context).post(url).then((value) {}).catchError((e) {});
// }

  @override
  Widget build(BuildContext context) {
    _updateApp(context);
    return Scaffold(
      body: tabViewList[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: barItemList,
        currentIndex: _selectedIndex,
        // selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
