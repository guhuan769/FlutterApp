import 'package:flutter/material.dart';

class IpConfigPage extends StatefulWidget {
  const IpConfigPage({super.key});

  @override
  State<IpConfigPage> createState() => _IpConfigPageState();
}

class _IpConfigPageState extends State<IpConfigPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            // Change 'Colors.red' to your desired color
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('IP配置'),
        ),
        body: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                decoration: const BoxDecoration(color: Colors.white),
                child: Form(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        keyboardType: TextInputType.text,
                        maxLines: 1,
                        maxLength: 12,
                        decoration: const InputDecoration(
                            // prefixIcon: Icon(Icons.addr),
                            hintText: "请输入IP地址",
                            contentPadding: EdgeInsets.symmetric(vertical: 10)),
                      ),
                      TextFormField(
                        keyboardType: TextInputType.text,
                        maxLines: 1,
                        maxLength: 5,
                        decoration: const InputDecoration(
                            hintText: "请输入端口",
                            contentPadding: EdgeInsets.symmetric(vertical: 10)),
                      ),
                      ElevatedButton(onPressed: () {}, child: const Text('保存')),
                    ],
                  ),
                ),
              ),
            )
          ],
        ));
  }
}
