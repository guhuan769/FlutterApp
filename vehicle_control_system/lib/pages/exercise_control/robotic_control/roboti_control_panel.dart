// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:vehicle_control_system/pages/controls/radio_option.dart';
//
// class RobotiControlPanel extends StatefulWidget {
//   @override
//   _RobotiControlPanelState createState() => _RobotiControlPanelState();
// }
//
// class _RobotiControlPanelState extends State<RobotiControlPanel> {
//   final TextEditingController ipController = TextEditingController();
//   final TextEditingController portController = TextEditingController();
//   String selectedOption = '基础';
//
//   @override
//   Widget build(BuildContext context) {
//     final args = Get.arguments as Map<String, dynamic>?;
//     final title = args?['title'] ?? 'Default Title'; // 使用默认值避免参数为 null
//
//     return Scaffold(
//       appBar: AppBar(title: Text(title)),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // IP and Port Section
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: ipController,
//                     decoration: InputDecoration(labelText: 'IP Text'),
//                   ),
//                 ),
//                 SizedBox(width: 10),
//                 Expanded(
//                   child: TextField(
//                     controller: portController,
//                     decoration: InputDecoration(labelText: 'Port Text'),
//                   ),
//                 ),
//                 SizedBox(width: 10),
//                 ElevatedButton(
//                   onPressed: () {
//                     // Handle connection logic
//                   },
//                   child: Text('连接 Button'),
//                 ),
//               ],
//             ),
//             SizedBox(height: 20),
//             // Selection Radio Buttons
//             Text('单选', style: TextStyle(fontSize: 18)),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 RadioOption(
//                   title: '基础',
//                   groupValue: selectedOption,
//                   onChanged: (value) {
//                     setState(() {
//                       selectedOption = value!;
//                     });
//                   },
//                 ),
//                 RadioOption(
//                   title: '工具',
//                   groupValue: selectedOption,
//                   onChanged: (value) {
//                     setState(() {
//                       selectedOption = value!;
//                     });
//                   },
//                 ),
//                 RadioOption(
//                   title: '轴',
//                   groupValue: selectedOption,
//                   onChanged: (value) {
//                     setState(() {
//                       selectedOption = value!;
//                     });
//                   },
//                 ),
//               ],
//             ),
//             SizedBox(height: 20),
//             // Step Length
//             Row(
//               children: [
//                 Text('步长', style: TextStyle(fontSize: 16)),
//                 SizedBox(width: 10),
//                 Expanded(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       border: OutlineInputBorder(),
//                       labelText: '1毫米到500毫米',
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 20),
//             // Coordinates Section
//             Expanded(
//               child: Container(
//                 padding: EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.black),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('- x'),
//                     Text('- y'),
//                     Text('- z'),
//                     Text('- rx'),
//                     Text('- ry'),
//                     Text('- rz'),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vehicle_control_system/pages/controls/custom_card_new.dart';
import 'package:vehicle_control_system/pages/controls/radio_option.dart';

class RobotiControlPanel extends StatefulWidget {
  @override
  _RobotiControlPanelState createState() => _RobotiControlPanelState();
}

class _RobotiControlPanelState extends State<RobotiControlPanel> {
  final TextEditingController ipController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  String selectedOption = '基础';

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final title = args?['title'] ?? 'Default Title';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // IP and Port Section
            CustomCardNew(
              title: '连接设置',
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ipController,
                      decoration: InputDecoration(
                        labelText: 'IP 地址',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: portController,
                      decoration: InputDecoration(
                        labelText: '端口',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      // Handle connection logic
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('连接'),
                  ),
                ],
              ),
            ),

            // Selection Radio Buttons
            CustomCardNew(
              title: '模式选择',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  RadioOption(
                    title: '基础',
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value!;
                      });
                    },
                  ),
                  RadioOption(
                    title: '工具',
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value!;
                      });
                    },
                  ),
                  RadioOption(
                    title: '轴',
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value!;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Step Length
            CustomCardNew(
              title: '步长',
              child: Row(
                children: [
                  Text(
                    '步长',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelText: '1毫米到500毫米',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Coordinates Section
            CustomCardNew(
              title: '坐标',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('- x'),
                  Text('- y'),
                  Text('- z'),
                  Text('- rx'),
                  Text('- ry'),
                  Text('- rz'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
