/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-23 14:35:45
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-23 14:35:50
 * @FilePath: \hook_up_rent\lib\pages\utils\scoped_model_helper.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter/material.dart';

class ScopedModelHelper {
  static T getModel<T extends Model>(BuildContext context) {
    return ScopedModel.of<T>(context, rebuildOnChange: true);
  }
}
