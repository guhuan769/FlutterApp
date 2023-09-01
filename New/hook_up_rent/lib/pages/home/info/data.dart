import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
// part of 'example.dart';

class infoItem {
  final String title;
  final String imageUri;
  final String source;
  final String time;
  final String navigateUri;
  const infoItem(
      {required this.title,
      required this.imageUri,
      required this.source,
      required this.time,
      required this.navigateUri});
}

class productionLineStatistics {
  late final String key;
  late final String lineName;
  late final int todayYield;
  late final int weekYield;
  late final int monthYield;
  late final int yearYield;

  productionLineStatistics(this.key, this.lineName, this.todayYield,
      this.weekYield, this.monthYield, this.yearYield);

  productionLineStatistics.fromJson(Map<String, dynamic> json) {
    key = json["key"];
    lineName = json["lineName"];
    todayYield = json["todayYield"];
    weekYield = json["weekYield"];
    monthYield = json["monthYield"];
    yearYield = json["yearYield"];
  }
// // 1.将color转成十六进制的数字
// final colorInt = int.parse(color，radix: 16);
// // 2.将透明度加进去

  // factory productionLineStatistics.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  // Map<String, dynamic> toJson() => _$UserToJson(this);
}

const List<infoItem> infoData = [
  const infoItem(
      title:
          'title1title1title1title1title1title1title1title1title1title1title1title1title1title1title1title1',
      imageUri: 'static/images/home.png',
      source: 'source',
      time: '2天前',
      navigateUri: 'login'),
  const infoItem(
      title: 'title2',
      imageUri: 'static/images/home.png',
      source: 'source',
      time: '2天前',
      navigateUri: 'login'),
  const infoItem(
      title: 'title3',
      imageUri: 'static/images/home.png',
      source: 'source',
      time: '2天前',
      navigateUri: 'login'),
  const infoItem(
      title: 'title4',
      imageUri: 'static/images/home.png',
      source: 'source',
      time: '2天前',
      navigateUri: 'login'),
  const infoItem(
      title: 'title4',
      imageUri: 'static/images/home.png',
      source: 'source',
      time: '2天前',
      navigateUri: 'login'),
  const infoItem(
      title: 'title4',
      imageUri: 'static/images/home.png',
      source: 'source',
      time: '2天前',
      navigateUri: 'login'),
  const infoItem(
      title: 'title4',
      imageUri: 'static/images/home.png',
      source: 'source',
      time: '2天前',
      navigateUri: 'login'),
  const infoItem(
      title: 'title4',
      imageUri: 'static/images/home.png',
      source: 'source',
      time: '2天前',
      navigateUri: 'login'),
  const infoItem(
      title: 'title4',
      imageUri: 'static/images/home.png',
      source: 'source',
      time: '2天前',
      navigateUri: 'login'),
  const infoItem(
      title: 'title4',
      imageUri: 'static/images/home.png',
      source: 'source',
      time: '2天前',
      navigateUri: 'login'),
  const infoItem(
      title: 'title4',
      imageUri: 'static/images/home.png',
      source: 'source',
      time: '2天前',
      navigateUri: 'login'),
  const infoItem(
      title: 'title4',
      imageUri: 'static/images/home.png',
      source: 'source',
      time: '2天前',
      navigateUri: 'login'),
  const infoItem(
      title: 'title4',
      imageUri: 'static/images/home.png',
      source: 'source',
      time: '2天前',
      navigateUri: 'login'),
  const infoItem(
      title: 'title4',
      imageUri: 'static/images/home.png',
      source: 'source',
      time: '2天前',
      navigateUri: 'login'),
  const infoItem(
      title: 'title4',
      imageUri: 'static/images/home.png',
      source: 'source',
      time: '2天前',
      navigateUri: 'login'),
];
