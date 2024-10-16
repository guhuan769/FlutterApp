import 'package:flutter/material.dart';
import 'package:get/get.dart';

// import '../user/registerFirst.dart';
class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
              onPressed: () {                         
                Get.toNamed("/login");
              },
              child: const Text("登录")
          ),
          const SizedBox(height: 40),
          ElevatedButton(
              onPressed: () {               
                 Get.toNamed("/registerFirst");
                // Get.off(const RegisterFirstPage());
              },
              child: const Text("注册")
          ),
          const SizedBox(height: 40),
          ElevatedButton(
              onPressed: () {               
                 Get.toNamed("/shop",arguments: {
                  "id":3456
                 });
              },
              child: const Text("shop路由传值-中间件演示")
          )
        ],
      ),
    );
  }
}
