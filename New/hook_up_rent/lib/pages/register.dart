/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-16 15:49:33
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-17 16:04:57
 * @FilePath: \hook_up_rent\lib\pages\login.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */

import 'package:flutter/material.dart';
import 'package:hook_up_rent/routes.dart';
import 'package:hook_up_rent/widgets/page_content.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

//有状态组件
class _RegisterPageState extends State<RegisterPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('注册'),
        ),
      ),
      body: SafeArea(
        minimum: EdgeInsets.all(30),
        //超过高度可以滚动
        child: ListView(
          children: [
            Padding(padding: EdgeInsets.all(10)),
            TextField(
              decoration: InputDecoration(labelText: '用户名', hintText: '请输入用户名'),
            ),
            Padding(padding: EdgeInsets.all(10)),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                  labelText: '密码',
                  hintText: '请输入密码',
                  // suffixIcon: IconButton(
                  //     onPressed: () {}, icon: Icon(Icons.visibility))
                  ),
            ),
            Padding(padding: EdgeInsets.all(10)),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                  labelText: '确认密码',
                  hintText: '请输入密码',
                  // suffixIcon: IconButton(
                  //     onPressed: () {}, icon: Icon(Icons.visibility))
                      ),
            ),
            Padding(padding: EdgeInsets.all(10)),
            Container(
              margin: EdgeInsets.all(10),
              child: ElevatedButton(
                child: Text("注册"),
                onPressed: () {},
                // style: ElevatedButton.styleFrom(padding: EdgeInsets.all(110)),
              ),
            ),
            Padding(padding: EdgeInsets.all(10)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '已有账号,',
                ),
                TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, Routes.login);
                    },
                    child: Text('去登录~'))
              ],
            )
          ],
        ),
      ),
    );
  }
}
