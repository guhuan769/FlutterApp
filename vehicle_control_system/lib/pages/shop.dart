import 'package:flutter/material.dart';
import 'package:get/get.dart';
class ShopPage extends StatefulWidget {
 //接收命名路由跳转传值
 
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  @override
  void initState() {   
    super.initState();  
    print(Get.arguments);  //获取上个页面的传值  
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        title: const Text("shop"),
      ),
      body: const Center(
        child:  Text("shop页面"),
      ),
    );
  }
}