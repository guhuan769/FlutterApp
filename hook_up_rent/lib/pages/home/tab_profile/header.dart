/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-19 11:51:13
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-23 09:03:05
 * @FilePath: \hook_up_rent\lib\pages\home\tab_profile\header.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:flutter/material.dart';
import 'package:hook_up_rent/widgets/common_image.dart';

var loginRegisterStyle = TextStyle(fontSize: 20.0, color: Colors.white);

class Header extends StatelessWidget {
  const Header({super.key});

//抽成一个函数
  Widget _notLoginBuilder(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 10.0, left: 20.0, bottom: 20.0),
      decoration: BoxDecoration(
        color: Colors.green,
      ),
      // decoration: BoxDecoration(color: Colors),
      height: 95.0,
      child: Row(
        children: [
          Container(
              height: 65.0,
              width: 65.0,
              margin: EdgeInsets.only(right: 15.0),
              child: CircleAvatar(
                child: CommonImage('static/images/user.png'),
                //一下是使用网络图片
                // backgroundImage: NetworkImage('static/images/home.png')
              )),
          Column(
            mainAxisAlignment: MainAxisAlignment.center, //水平居中
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Padding(padding: EdgeInsets.only(top: 6.0)),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('login');
                    },
                    child: Text(
                      '登录',
                      style: loginRegisterStyle,
                    ),
                  ),
                  Text(
                    '/',
                    style: loginRegisterStyle,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('register');
                    },
                    child: Text(
                      '注册',
                      style: loginRegisterStyle,
                    ),
                  ),
                ],
              ),
              Text(
                '登录后可以更多操作权限',
                style: loginRegisterStyle,
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _loginBuilder(BuildContext context) {
    String userName = '已登录用户名';
    String userImage = 'static/images/user.png';
    return Container(
      padding: EdgeInsets.only(top: 10.0, left: 20.0, bottom: 20.0),
      decoration: BoxDecoration(
        color: Colors.green,
      ),
      // decoration: BoxDecoration(color: Colors),
      height: 95.0,
      child: Row(
        children: [
          Container(
              height: 65.0,
              width: 65.0,
              margin: EdgeInsets.only(right: 15.0),
              child: CircleAvatar(
                child: CommonImage(userImage),
                //一下是使用网络图片
                // backgroundImage: NetworkImage('static/images/home.png')
              )),
          Column(
            mainAxisAlignment: MainAxisAlignment.center, //水平居中
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //
              // Padding(padding: EdgeInsets.only(top: 6.0)),
              Text(
                userName,
                style: loginRegisterStyle,
              ),
              Text(
                '查看编辑个人资料',
                style: loginRegisterStyle,
              )
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var isLogin = true;
    return isLogin ? _loginBuilder(context) : _notLoginBuilder(context);
  }
}
