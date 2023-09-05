/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-18 14:54:01
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-18 15:58:40
 * @FilePath: \hook_up_rent\lib\widgets\common_image.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:flutter/material.dart';

import 'package:flutter_advanced_networkimage_2/provider.dart';
import 'package:flutter_advanced_networkimage_2/transition.dart';
import 'package:flutter_advanced_networkimage_2/zoomable.dart';

final networkUriReg = RegExp('^http');
final localUriReg = RegExp('^static');

class CommonImage extends StatelessWidget {
  final String src;
  final double? width;
  final double? height;
  final BoxFit? fit;
  const CommonImage(this.src, {super.key, this.width, this.height, this.fit});

  @override
  Widget build(BuildContext context) {
    if (networkUriReg.hasMatch(src)) {
      return Image(
        width: width,
        height: height,
        fit: fit,
        image: AdvancedNetworkImage(src,
            useDiskCache: true,
            //缓存7天
            cacheRule: CacheRule(maxAge: Duration(days: 7)),
            //超时
            timeoutDuration: Duration(seconds: 20)),
      );
    }
    if (localUriReg.hasMatch(src)) {
      return Image.asset(
        src,
        width: width,
        height: height,
        fit: fit,
      );
    }
    assert(false, '图片地址 SRC 不合法');
    return Container();
  }
}
//如果以HTTP开始那么即使网络图片
// final networkUriRef=RegExp('^http');
// final localUriRef=RegExp('^static');


// class CommonImage extends StatelessWidget{
//   final String str;
//   final double width;
//   final double height;
//   final BoxFit fit;

//   const CommonImage(this.src,{key key,this.width,this.height,this.fit});
//   Widget build
// }

