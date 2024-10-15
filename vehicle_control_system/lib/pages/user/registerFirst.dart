import 'package:flutter/material.dart';
import 'package:get/get.dart';
class RegisterFirstPage extends StatefulWidget {
  const RegisterFirstPage({super.key});

  @override
  State<RegisterFirstPage> createState() => _RegisterFirstPageState();
}

class _RegisterFirstPageState extends State<RegisterFirstPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("注册第一步")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("注册第一步"),
              const SizedBox(height: 40),
              ElevatedButton(onPressed: () {              
                Get.toNamed("/registerSecond");
              }, child: const Text("下一步"))
            ],
          ),
        ));
  }
}
