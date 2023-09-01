/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-16 15:49:33
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-27 11:34:40
 * @FilePath: \hook_up_rent\lib\pages\login.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hook_up_rent/pages/utils/common_toast.dart';
import 'package:hook_up_rent/pages/utils/dio_http.dart';
import 'package:hook_up_rent/pages/utils/scoped_model_helper.dart';
import 'package:hook_up_rent/pages/utils/store.dart';
import 'package:hook_up_rent/routes.dart';
import 'package:hook_up_rent/scoped_model/auth.dart';
import 'package:hook_up_rent/widgets/page_content.dart';
//添加依赖
import 'dart:convert';
import 'package:scoped_model/scoped_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

//有状态组件
class _LoginPageState extends State<LoginPage> {
  bool showPassword = false;

  var usernameController = TextEditingController();
  var passwordController = TextEditingController();

  _loginHandle() async {
    try {
      var username = await usernameController.text;
      var password = await passwordController.text;
      if (username == '' || password == '') {
        CommonToast.showToast('用户名或密码不能为空!');
      }

      const url = '/api/LoginLoginByUserNameAndPwd';
      var params = {'userName': username, 'password': password};
      var res;

      res = await DioHttp.of(context).post(url, params);

      // var resMap = json.decode(res.data.toString());
      var resMap = json.decode(res.toString());
      var code = resMap["code"];
      var msg = resMap["msg"] ?? '内部错误';
      CommonToast.showToast(msg);
      if (code.toString().startsWith('0')) {
        String token = resMap["token"];
        Store store = await Store.getInstance();
        await store.setString(StoreKeys.token, token);

        ScopedModelHelper.getModel<AuthModel>(context).login(token, context);
        Timer(Duration(seconds: 1), () {
          //回到上一页面
          // Navigator.of(context).pop();
          Navigator.pushReplacementNamed(context, Routes.home);
        });
      }
    } catch (error, stacktrace) {
      CommonToast.showToast('网络无法访问 ERROR: ${error}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('登录'),
        ),
      ),
      body: SafeArea(
        minimum: EdgeInsets.all(30),
        //超过高度可以滚动
        child: ListView(
          children: [
            Padding(padding: EdgeInsets.all(10)),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: '用户名', hintText: '请输入用户名'),
            ),
            Padding(padding: EdgeInsets.all(10)),
            TextField(
              controller: passwordController,
              obscureText: !showPassword,
              decoration: InputDecoration(
                  labelText: '密码',
                  hintText: '请输入密码',
                  suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          showPassword = !showPassword;
                        });
                      },
                      icon: Icon(showPassword
                          ? Icons.visibility_off
                          : Icons.visibility))),
            ),
            Padding(padding: EdgeInsets.all(10)),
            Container(
              margin: EdgeInsets.all(10),
              child: ElevatedButton(
                child: Text("登录"),
                onPressed: () {
                  _loginHandle();
                  // Navigator.pushReplacementNamed(context, Routes.home);
                },
                // style: ElevatedButton.styleFrom(padding: EdgeInsets.all(110)),
              ),
            ),
            Padding(padding: EdgeInsets.all(10)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Text(
                //   '还没有账号,',
                // ),
                // TextButton(
                //     onPressed: () {
                //       Navigator.pushReplacementNamed(context, '/register');
                //     },
                //     child: Text('去注册~'))
              ],
            )
          ],
        ),
      ),
    );
  }
}
