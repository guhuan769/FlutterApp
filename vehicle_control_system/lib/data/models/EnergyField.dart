class EnergyField {
  final String key;        // 英文键名
  final String label;      // 中文标签
  final String? unit;       // 单位
  final double? maxValue;   // 最大值
  final double? minValue;   // 最小值
  final double? autoIncrementValue; // 自增数值

  const EnergyField({
    required this.key,
    required this.label,
    this.unit,
    this.maxValue,
    this.minValue,
    this.autoIncrementValue,
  });
}
