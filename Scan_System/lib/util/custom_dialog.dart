// import 'package:flutter/material.dart';
//
// class CustomDialog {
//   static void chooseCustom(BuildContext context,
//       {Widget? title,
//       Widget? content,
//       VoidCallback? onLeftClicked,
//       String leftText = "取消",
//       VoidCallback? onRightClicked,
//       String rightText = "确定",
//       bool dismissible = true}) {
//     void _handleButtonClick(VoidCallback onPressed) {
//       onPressed();
//       Navigator.pop(context);
//     }
//
//     List<Widget> actions = [];
//     if (onLeftClicked != null) {
//       actions.add(TextButton(
//         onPressed: () => _handleButtonClick(onLeftClicked),
//         child: Text(leftText),
//       ));
//       if (onRightClicked != null) {
//         actions.add(TextButton(
//           onPressed: () => _handleButtonClick(onRightClicked),
//           child: Text(rightText),
//         ));
//       }
//     } else if (onRightClicked != null) {
//       actions.add(Row(mainAxisAlignment: MainAxisAlignment.end, children: [
//         TextButton(
//           onPressed: () => _handleButtonClick(onRightClicked),
//           child: Text(rightText),
//         )
//       ]));
//     }
//
//     // set up the AlertDialog
//     AlertDialog alert = AlertDialog(
//       actionsAlignment: MainAxisAlignment.spaceBetween,
//       titlePadding: EdgeInsets.only(top: 15, left: 15, right: 15),
//       contentPadding: EdgeInsets.only(top: 20, left: 15, right: 15),
//       actionsPadding: EdgeInsets.only(top: 20, bottom: 15, left: 15, right: 15),
//       title: title,
//       content: content,
//       actions: actions.isEmpty ? null : actions,
//     );
//
//     showDialog(
//       barrierDismissible: dismissible,
//       context: context,
//       builder: (BuildContext context) {
//         return alert;
//       },
//     );
//   }
// }
//
// // Future<bool?> showMyDialog(BuildContext context,
// //     {String content = '', String left = '取消', String right = '确定'}) async {
// //   return showDialog<bool?>(
// //     context: context,
// //     builder: (BuildContext context) {
// //       return AlertDialog(
// //         content: Text(content),
// //         actionsPadding: EdgeInsets.zero,
// //         actions: [
// //           Container(
// //             decoration: BoxDecoration(
// //               border: Border(
// //                 top: BorderSide(
// //                   color: Colors.grey.withOpacity(0.5), // 边框颜色
// //                   width: 1.0, // 边框宽度
// //                 ),
// //               ),
// //             ),
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: [
// //                 Expanded(
// //                   child: TextButton(
// //                     child: Text(left, style: const TextStyle(fontSize: 16)),
// //                     onPressed: () {
// //                       Navigator.of(context).pop(false);
// //                     },
// //                   ),
// //                 ),
// //                 Container(
// //                   width: 1,
// //                   height: 48,
// //                   color: Colors.grey.withOpacity(0.5),
// //                 ),
// //                 Expanded(
// //                   child: TextButton(
// //                     child: Text(right, style: const TextStyle(fontSize: 16)),
// //                     onPressed: () {
// //                       Navigator.of(context).pop(true);
// //                     },
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       );
// //     },
// //   );
// // }
