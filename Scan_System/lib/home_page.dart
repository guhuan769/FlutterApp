import 'package:flutter/material.dart';

///
/// 主页
///
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    debugPrint("select home page");
  }
  @override
  Widget build(BuildContext context) {
    return const Center(
      child:  Text('待开发'),
    );
  }
}
