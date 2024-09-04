import 'dart:io';
import 'dart:typed_data';
///
///西门子PLC控制
///
class S7utils{
  static Future<void> s7Connect(Socket socket) async {
    // 2. 发送COTP连接请求
    List<int> bytes = [
      // TPKT
      0x03,
      0x00,
      0x00, 0x16,

      // COTP
      0x11,
      0xe0, // 表示连接请求
      0x00, 0x00,
      0x00, 0x01,
      0x00,

      // 0xc0
      0xc0,
      0x01,
      0x0a, // 2的10次方 1024

      // 0xc1 通信源对应的相关配置 PC
      0xc1,
      0x02,
      0x10, // S7双边模式 也可以选择01- PG 02 OP
      0x00, // 不需要设置机架和插槽

      // 0xc2
      0xc2,
      0x02,
      0x03, // S7单边模式
      0x01  // 如果机架插槽为0，0 0x00 机架*32+插槽 (机架<<5)+插槽
    ];
    socket.add(Uint8List.fromList(bytes));
    await socket.flush();

    // 接收COTP CC结果 暂时注释
    bytes = List<int>.filled(27, 0);
    // await socket.listen((data) {
    //   bytes.setRange(0, data.length, data);
    // }).asFuture();

    // 3. 设置通信
    bytes = [
      // TPKT
      0x03,
      0x00,
      0x00, 0x19,

      // COTP
      0x02, // 在COTP这个环节，当前字节以后的字节数
      0xf0, // 表示数据传输
      0x80,

      // S7 - Header
      0x32, // 协议ID 默认0x32 0x72 S7Plus
      0x01, // 向PLC发送一个Job请求
      0x00, 0x00,
      0x00, 0x00, // 累加序号

      // Parameter 长度
      0x00, 0x08,
      // Data长度
      0x00, 0x00,

      // S7 - Parameter
      0xf0, // Setup Communication Function
      0x00,

      0x00, 0x01,
      0x00, 0x01, // 任务处理队列长度
      0x03, 0xc0, // PDU长度 960 480 字节 PLC 反馈 240 480 960
    ];
    socket.add(Uint8List.fromList(bytes));
    await socket.flush();

    // 接收响应
    List<int> resp = List<int>.filled(27, 0);
    // await socket.listen((data) {
    //   resp.setRange(0, data.length, data);
    // }).asFuture();

    // 解析PDU长度
    int pdu = (resp[25] << 8) + resp[26];
    print('PDU Length: $pdu');
  }

  static Future<void> s7Read(Socket socket) async {
    // DB1.DBW100   读取 DB2.DBX0.0 的数据
    // DB20.DBX6.0
    List<int> bytes = [
      // TPKT - 4bytes
      0x03,
      0x00,
      0x00, 0x1f, // 十进制 31    整个数据组的长度

      // COTP
      0x02,
      0xf0, // 数据传输
      0x80,

      // S7 - Header
      0x32, //协议ID 默认0x32 0x72 S7Plus
      0x01, // 向PLC发送一个Job请求
      0x00, 0x00,
      0x00, 0x01, //累加序号

      //Parameter 长度
      0x00, 0x0e,
      // Data 长度
      0x00, 0x00,

      // S7 - Parameter
      0x04, //向PLC发送一个读变量的请求
      0x01, //Item的数量 Item中包含了请求的地址以及类型相关信息

      // S7 - Parameter - Item
      0x12,
      0x0a, //当前Item部分，此字节往后还有10个字节
      0x10,
      0x02, //传输数据类型 02： byte 01 : bool  // 01 bit 02 byte 04 word
      0x00, 0x01, //读取的数量 如若读取10个的话就是0x0a

      // v - DB20.DBX6.0
      0x00, 0x14, // db number 对应DB块的编号，如果区域不是DB，这里写0
      0x84, //存储区  Datablock -> V   0x81 I区
      //变量地址 100 Byte -2 100 101 占3个字节
      0x00, 0x00, 0x30

      // 0000 0000 0000 0000 0000 0000 //表达字节 + 位信息
      // 0000 0000 0000 0000 0011 0 000
      // DB1.DBX100.5        0x64  0110 0100     [0-7    110]
      // 0000 0000 0000 0110 0010 0 000
      // 0x00 0x02 0x25

      //100 << 3 + 位信息
      //
    ];

    //socket.add(bytes); //读取地址变量数据的请求
    socket.add(Uint8List.fromList(bytes));
    await socket.flush();
    // List<int> resp = List.filled(27, 0);
    // await for (var data in socket) {
    //   resp.setRange(0, data.length, data);
    //   int pdu = (resp[26] << 8) | resp[25];
    // }
  }


}

