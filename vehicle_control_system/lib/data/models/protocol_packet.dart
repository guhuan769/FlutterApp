class ProtocolPacket {
  final int modeType;        // 模式类型（1: 基础，2: 工具，3: 轴）
  final double stepLength;   // 步长（单位：毫米）
  final int coordinateType;  // 坐标类型（1: X, 2: Y, 3: Z, 4: RX, 5: RY, 6: RZ）
  final double coordinateValue; // 坐标值

  ProtocolPacket({
    required this.modeType,
    required this.stepLength,
    required this.coordinateType,
    required this.coordinateValue,
  });

  // 协议包的字符串表示
  String toProtocolString() {
    return '类型:$modeType|步长:$stepLength|坐标:$coordinateType|坐标值:$coordinateValue';
  }
}
