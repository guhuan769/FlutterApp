import 'package:flutter/material.dart';

import '../Utils/common_toast.dart';

///
/// 主页
///
class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    debugPrint("select home page");
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 当false时，阻止当前路由被弹出。
      onPopInvoked: (didPop) async {
        CommonToast.showHint(context);
      },
      child: const Center(
        child: Text('待开发'),
      ),
    );
  }
}
