import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});
  void _alertDialog(context) async {
    var result = await showDialog(
        barrierDismissible: false, //表示点击灰色背景的时候是否消失弹出框
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("提示信息!"),
            content: const Text("您确定要删除吗"),
            actions: [
              TextButton(
                  onPressed: () {
                    print("ok");
                    Navigator.of(context).pop("ok"); //点击按钮让AlertDialog消失
                  },
                  child: const Text("确定")),
              TextButton(
                  onPressed: () {
                    print("cancel");
                    Navigator.of(context).pop("取消");
                  },
                  child: const Text("取消"))
            ],
          );
        });
    print("-----------");
    print(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Title'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () {
                  _alertDialog(context);
                },
                child: const Text("Flutter默认的dialog")),
            ElevatedButton(
                onPressed: () {
                  Get.defaultDialog(
                      title: "提示信息!",
                      middleText: "您确定要删除吗?",
                      confirm: ElevatedButton(
                          onPressed: () {
                            print("确定");
                            // Navigator.of(context).pop();
                            Get.back();
                          },
                          child: const Text("确定")),
                      cancel: ElevatedButton(
                          onPressed: () {
                            print("取消");
                            Get.back();
                          },
                          child: const Text("取消")));
                },
                child: const Text("Getx defaultDialog")),
            ElevatedButton(
                onPressed: () {
                  Get.snackbar("提示?", "您还有没有登录",
                      snackPosition: SnackPosition.BOTTOM);
                },
                child: const Text("Getx snackbar")),
            ElevatedButton(
                onPressed: () {
                  Get.bottomSheet(Container(
                    color:Get.isDarkMode?Colors.black26:Colors.white,
                    height: 200,
                    child: Column(
                      children:  [
                        ListTile(
                          leading: Icon(Icons.wb_sunny_outlined,
                              color: Get.isDarkMode?Colors.white:Colors.black87),
                          onTap: (){
                            //切换主题
                            Get.changeTheme(ThemeData.light());
                            Get.back();

                          },
                          title:  Text(
                            "白天模式",
                            style: TextStyle(color: Get.isDarkMode?Colors.white:Colors.black87),
                          ),
                        ),
                        ListTile(
                          leading: Icon(Icons.wb_sunny, color: Get.isDarkMode?Colors.white:Colors.black87),
                          onTap: (){
                            //切换主题
                            Get.changeTheme(ThemeData.dark());
                            Get.back();
                          },
                          title: Text(
                            "夜晚模式",
                            style: TextStyle(color: Get.isDarkMode?Colors.white:Colors.black87),
                          ),
                        )
                      ],
                    ),
                  ));
                },
                child: const Text("Getx bottomSheet切换主题"))
          ],
        ),
      ),
    );
  }
}
