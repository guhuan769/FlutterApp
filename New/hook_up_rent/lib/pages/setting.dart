/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-19 16:39:00
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-28 10:20:08
 * @FilePath: \hook_up_rent\lib\pages\setting.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:flutter/material.dart';
import 'package:flutter_app_update/flutter_app_update.dart';
import 'package:flutter_app_update/update_model.dart';
import 'package:hook_up_rent/pages/AppUpdate.dart';
import 'package:hook_up_rent/pages/utils/common_toast.dart';
import 'package:hook_up_rent/routes.dart';

//无状态组件
class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  void initState() {
    super.initState();
    AzhonAppUpdate.listener((map) {
      print(map['type']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('设置')),
      body: ListView(
        padding: EdgeInsets.only(top: 10.0),
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(children: [
              Container(

                child: ElevatedButton(
                  child: FractionallySizedBox(
                    widthFactor: 0.92,
                    child: Center(child: Text("退出登录")),
                  ),
                  onPressed: () {
                    CommonToast.showToast('已经退出登录');
                    // Navigator.of(context).pushReplacementNamed('login');
                    // Navigator.pushNamed(context, Routes.login);
                    // Navigator.of(context).popUntil(ModalRoute.withName('login'));
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        "/login", ModalRoute.withName("/login"));
                    // Navigator.
                  },
                ),
              ),
              Container(
                child: AppUpdate(),
              )
              // ElevatedButton(
              //   child:AppUpdate(),// Center(child: Text("检查更新")),
              //   onPressed: () {
              //     // AppUpdate();
              //     // UpdateModel model = UpdateModel(
              //     //     'http://192.168.1.99:5118/api/FileDownload/Download?subDirectory=D:\\upload\\app-release.apk',
              //     //     "app-release.apk",

              //     //     /// android res/mipmap 目录下的图片名称
              //     //     "ic_launcher",
              //     //     ''
              //     //     // 'http://192.168.1.99:5118/api/FileDownload/Download?subDirectory',//=D:\\upload\app-release.apk
              //     //     );
              //     // AzhonAppUpdate.update(model)
              //     //     .then((value) => debugPrint('$value'));
              //   },
              // ),
            ]),
          )
        ],
      ),
    );
  }
}
