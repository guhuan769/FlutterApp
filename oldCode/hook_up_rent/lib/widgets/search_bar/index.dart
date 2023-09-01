/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-20 16:33:54
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-04-21 15:05:48
 * @FilePath: \hook_up_rent\lib\widgets\search_bar\index.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AEs
 */
import 'package:flutter/material.dart';
import 'package:hook_up_rent/widgets/common_image.dart';

class SearchBarCustom extends StatefulWidget {
  final bool showLoaction; //展示位置按钮
  final Function()? goBackCallback; //回退按钮函数
  final String? inputValue; //搜索框输入值
  final String? defaultInputValue; //搜索框默认值
  final Function()? onChancel; //取消按钮、
  final bool? showMap; //展示地图按钮
  final Function() onSearch; //用户点击搜索框触发
  final ValueChanged<String>? onSearchSubmit; //用户输入关键词后点击

  const SearchBarCustom(
      {super.key,
      this.showLoaction = false,
      this.goBackCallback,
      this.inputValue = '',
      this.defaultInputValue = '请输入搜索词',
      this.onChancel,
      this.showMap,
      required this.onSearch,
      this.onSearchSubmit}); //用户输入上搜索词后，点击

  @override
  State<SearchBarCustom> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBarCustom> {
  String _searchWord = '';
  late TextEditingController _controller;
  late FocusNode _focus;
  @override
  void initState() {
    // TODO: implement initState
    _focus = new FocusNode();
    _controller = TextEditingController(text: widget.inputValue);
    super.initState();
  }

  _onClear() {
    _controller.clear();
    setState(() {
      _searchWord = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: BoxDecoration(
      //   color: Colors.red
      // )
      // ,
      child: Row(
        children: [
          if (widget.showLoaction)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Icon(
                      Icons.room,
                      color: Colors.black,
                      size: 16,
                    ),
                    Text(
                      '项目',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    )
                  ],
                ),
              ),
            ),
          if (widget.goBackCallback != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: widget.goBackCallback,
                child: Icon(
                  Icons.chevron_left,
                  color: Colors.black87,
                ),
              ),
            ),
          Expanded(
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(18.0)),
              margin: const EdgeInsets.only(right: 10),
              child: TextField(
                //使用焦点
                focusNode: _focus,
                onTap: () {
                  //失去焦点
                  if (null == widget.onSearchSubmit) {
                    _focus.unfocus();
                  }
                  widget.onSearch();
                },
                // () {
                // Navigator.of(context).pushNamed('search');
                //  ;
                // }
                // ,
                onSubmitted: widget.onSearchSubmit,
                onChanged: (String value) {
                  setState(() {
                    _searchWord = value;
                  });
                },
                controller: _controller,
                textInputAction: TextInputAction.search,
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.start,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '请输入搜索词',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  contentPadding: EdgeInsets.only(top: -4),
                  prefixIcon: Padding(
                    padding:
                        const EdgeInsets.only(top: 0.0, left: 5, right: 0.0),
                    child: Icon(
                      Icons.search,
                      size: 24,
                      color: Colors.grey,
                    ),
                  ),
                  // alignLabelWithHint: false,
                  prefixIconConstraints: BoxConstraints(minWidth: 5),
                  //清除按钮
                  suffixIcon: GestureDetector(
                    onTap: () {
                      _onClear();
                    },
                    child: Icon(
                      Icons.clear,
                      size: 18,
                      color: _searchWord == '' ? Colors.grey[200] : Colors.grey,
                    ),
                  ),
                  // ),
                ),
              ),
            ),
          ),
          if (widget.onChancel != null)
            GestureDetector(
              onTap: () {
                widget.onChancel;
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  '取消',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
          if (widget.showMap != null)
            CommonImage(
              'static/images/地图灰色.png',
              width: 16,
              height: 16,
            )
        ],
      ),
    );
  }
}
