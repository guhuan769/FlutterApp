/*
 * @Author: guhuan769 769540542@qq.com
 * @Date: 2023-04-29 10:03:23
 * @LastEditors: guhuan769 769540542@qq.com
 * @LastEditTime: 2023-05-20 09:30:50
 * @FilePath: \hook_up_rent\lib\pages\charts\horizontal_bar_label_chart.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
/// Horizontal bar chart with bar label renderer example and hidden domain axis.
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:hook_up_rent/pages/home/info/data.dart';
import 'package:hook_up_rent/pages/production/line_detail/line_detail_entity.dart';

class HorizontalBarLabelChart extends StatelessWidget {
  final List<charts.Series<dynamic, String>> seriesList;
  final bool? animate;

  HorizontalBarLabelChart(this.seriesList, {this.animate});

  factory HorizontalBarLabelChart.withSampleData(
      productionLineStatistics data) {
    return HorizontalBarLabelChart(
      _createSampleData(data),
      animate: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return charts.BarChart(
      seriesList,
      animate: animate,
      vertical: false,
      barRendererDecorator: new charts.BarLabelDecorator<String>(),
      domainAxis:
          new charts.OrdinalAxisSpec(renderSpec: new charts.NoneRenderSpec()),
    );
  }

  static List<charts.Series<OrdinalSales, String>> _createSampleData(
      productionLineStatistics detailData) {
    //  String? aa = data.aa;
    final data = [
      new OrdinalSales('今日产量', detailData.todayYield),
      new OrdinalSales('周产量', detailData.weekYield),
      new OrdinalSales('月产量', detailData.monthYield),
      new OrdinalSales('年产量', detailData.yearYield),
    ];
    return [
      new charts.Series<OrdinalSales, String>(
          id: 'Sales',
          domainFn: (OrdinalSales sales, _) => sales.title,
          measureFn: (OrdinalSales sales, _) => sales.yield,
          data: data,
          labelAccessorFn: (OrdinalSales sales, _) =>
              '${sales.title}: ${sales.yield.toString()}')
    ];
  }
}

class OrdinalSales {
  final String title;
  final int yield;

  OrdinalSales(this.title, this.yield);
}
