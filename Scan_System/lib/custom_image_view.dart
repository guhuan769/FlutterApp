// import 'package:flutter/material.dart';
//
// import 'package:flutter_advanced_networkimage_2/provider.dart';
// import 'package:flutter_advanced_networkimage_2/transition.dart';
// import 'package:flutter_advanced_networkimage_2/zoomable.dart';

// class CustomImageView extends StatefulWidget {
//   const CustomImageView({super.key});
//
//   @override
//   State<CustomImageView> createState() => _CustomImageViewState();
// }
//
// class _CustomImageViewState extends State<CustomImageView> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         child: Text('123'),
//       ),
//     );
//   }
// }

//
//
// final networkUriReg = RegExp('^http');
// final localUriReg = RegExp('^static');
//
// class CustomImageView extends StatelessWidget {
//   final String src;
//   final double? width;
//   final double? height;
//   final BoxFit? fit;
//   // const CustomImageView({super.key});
//   const CustomImageView(this.src, {super.key, this.width, this.height, this.fit});
//
//   @override
//   Widget build(BuildContext context) {
//     if (networkUriReg.hasMatch(src)) {
//       return Image(
//         width: width,
//         height: height,
//         fit: fit,
//         image: AdvancedNetworkImage(src,
//             useDiskCache: true,
//             //缓存7天
//             cacheRule: CacheRule(maxAge: Duration(days: 7)),
//             //超时
//             timeoutDuration: Duration(seconds: 20)),
//       );
//     }
//     if (localUriReg.hasMatch(src)) {
//       return Image.asset(
//         src,
//         width: width,
//         height: height,
//         fit: fit,
//       );
//     }
//     assert(false, '图片地址 SRC 不合法');
//     return Container();
//   }
// }
