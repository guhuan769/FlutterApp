import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vehicle_control_system/data/enum/ToastType.dart';
import 'package:vehicle_control_system/data/models/EnergyField.dart';
import 'package:vehicle_control_system/data/models/data_packet.dart';
import 'package:vehicle_control_system/data/models/protocol_packet.dart';
import 'package:vehicle_control_system/pages/communication/tcp_server.dart';
import 'package:vehicle_control_system/pages/controls/counter_widget.dart';
import 'package:vehicle_control_system/pages/controls/counter_widget_four.dart';
import 'package:vehicle_control_system/pages/controls/custom_card_new.dart';
import 'package:vehicle_control_system/pages/controls/icon_text_button.dart';
import 'package:vehicle_control_system/pages/controls/toast.dart';
import 'package:vehicle_control_system/tool_box/ip_utils.dart';

class WeldingRealTimeConfigurationPanel extends StatefulWidget {
  const WeldingRealTimeConfigurationPanel({super.key});

  @override
  State<WeldingRealTimeConfigurationPanel> createState() =>
      _WeldingRealTimeConfigurationPanelState();
}

class _WeldingRealTimeConfigurationPanelState
    extends State<WeldingRealTimeConfigurationPanel> {
  final TextEditingController ipController = TextEditingController();
  final TextEditingController portController = TextEditingController();

  // 存储错误信息
  String? ipError;
  String? portError;
  String? stepError;

  // TCP相关变量
  Socket? _socket;
  StreamSubscription? _subscription;
  final TcpServer _tcpServer = TcpServer();
  String _receivedData = '等待数据...';
  bool isInformation = true;

  // 定义字段配置
  static const List<EnergyField> fields = [
    EnergyField(
        key: 'current',
        label: '电流',
        unit: '安',
        maxValue: 500,
        minValue: 100,
        autoIncrementValue: 1),
    EnergyField(
        key: 'voltage',
        label: '电压',
        unit: '伏特',
        maxValue: 40,
        minValue: 10,
        autoIncrementValue: 0.1),
  ];

  // 机器人偏移字段配置
  static const List<EnergyField> robotOffsetFields = [
    EnergyField(key: 'X', label: 'X', unit: '', autoIncrementValue: 1),
    EnergyField(key: 'Y', label: 'Y', unit: '', autoIncrementValue: 0.1),
    EnergyField(key: 'Z', label: 'Z', unit: '', autoIncrementValue: 0.1),
  ];

  // 定义控制器
  final Map<String, TextEditingController> energyControllers = {
    'current': TextEditingController(text: '0'),
    'voltage': TextEditingController(text: '0'),
  };

  final Map<String, TextEditingController> robotOffsetControllers = {
    'X': TextEditingController(text: '0'),
    'Y': TextEditingController(text: '0'),
    'Z': TextEditingController(text: '0'),
  };

  // 连接状态
  String? connectionStatus;

  double _currentValue = 0.0;
  double _voltageValue = 0.0;

  // 添加数据处理方法
  void _processEnergyData(String data) {
    try {
      // 检查数据是否为空
      if (data.isEmpty) return;

      // 解析数据包
      ProtocolPacket packet = ProtocolPacket.fromProtocolString(data);

      setState(() {
        // 根据模式类型更新相应的控制器
        switch (packet.modeType) {
          case 1: // 电流
            energyControllers['current']?.text = packet.coordinateValue.toString();
            _currentValue = packet.coordinateValue.toDouble();
            break;
          case 2: // 电压
            energyControllers['voltage']?.text = packet.coordinateValue.toString();
            _voltageValue = packet.coordinateValue.toDouble();
            break;
        }
      });
    } catch (e) {
      print('数据处理错误: $e');
    }
  }

  // 启动TCP服务器
  Future<void> _startTcpServer() async {
    await _tcpServer.startServer(address: '0.0.0.0', port: 9998);

    _tcpServer.dataStream.listen((data) {
      setState(() {
        _receivedData = data;
        isInformation = true;
      });
      // print('收到的数据eeee ${data}');
      // 处理接收到的数据
      _processEnergyData(data);

      Toast.show(
        context,
        "收到一条来自服务端的消息",
        type: ToastType.success,
      );

      print("收到数据: $_receivedData");

      // 解析协议数据
      ProtocolPacket packet = ProtocolPacket.fromProtocolString(_receivedData);

      // 更新对应的控制器值
      _updateValues(packet);
    });
  }

  // 更新控制器值
  void _updateValues(ProtocolPacket packet) {
    // 根据协议类型更新不同的控制器
    switch (packet.modeType) {
      case 1: // 电流
        energyControllers['current']?.text = packet.coordinateValue.toString();
        break;
      case 2: // 电压
        energyControllers['voltage']?.text = packet.coordinateValue.toString();
        break;
      case 3: // 机器人偏移
        String coordinate = _getCoordinateType(packet.coordinateType);
        robotOffsetControllers[coordinate]?.text =
            packet.coordinateValue.toString();
        break;
    }
  }

  String _getCoordinateType(int coordinateType) {
    switch (coordinateType) {
      case 1:
        return 'X';
      case 2:
        return 'Y';
      case 3:
        return 'Z';
      default:
        return 'Unknown';
    }
  }

  // 电流电压
  Future<void> _sendTCPData1({
    required String current,
    required double currentValue,
    required String voltage,
    required double voltageValue,
  }) async {
    final String ip = ipController.text;
    final String port = portController.text;

    // 验证 IP 和端口
    if (!IpUtils.isIpValid(ip) || !IpUtils.validatePort(port)) {
      Toast.show(
        context,
        "无效的 IP 或端口",
        type: ToastType.warning,
      );
      return;
    }

    Socket? socket;
    try {
      // 创建数据包
      final packet = DataPacket(
        current: current,
        currentValue: currentValue,
        voltage: voltage,
        voltageValue: voltageValue,
      );

      // 建立 TCP 连接
      socket = await Socket.connect(
        ip,
        int.parse(port),
        timeout: Duration(seconds: 5),
      );

      // 发送数据
      final data = packet.toProtocolString();
      socket.write(data);
      print('发送数据: $data');

      // 等待数据发送完成
      await socket.flush();

      setState(() {
        connectionStatus = '连接成功';
      });

      Toast.show(
        context,
        "数据发送成功",
        type: ToastType.success,
      );

    } catch (e) {
      print('连接错误: $e');
      setState(() {
        connectionStatus = '连接失败';
      });

      Toast.show(
        context,
        "连接失败: ${e.toString()}",
        type: ToastType.error,
      );

    } finally {
      // 确保socket正确关闭
      try {
        await socket?.flush();
        await socket?.close();
      } catch (e) {
        print('关闭连接错误: $e');
      }
    }
  }

  // 发送TCP数据方法
  Future<void> _sendTCPData({
    required int modeType,
    required int coordinateType,
    required double value,
  }) async {
    final String ip = ipController.text;
    final String port = portController.text;

    if (!IpUtils.isIpValid(ip) || !IpUtils.validatePort(port)) {
      Toast.show(
        context,
        "无效的 IP 或端口",
        type: ToastType.warning,
      );
      return;
    }

    final packet = ProtocolPacket(
      modeType: modeType,
      coordinateType: coordinateType,
      coordinateValue: value,
    );

    try {
      final socket = await Socket.connect(ip, int.parse(port),
          timeout: Duration(seconds: 5));

      final data = packet.toProtocolString();
      socket.write(data);
      print('发送数据: $data');

      socket.close();

      setState(() {
        connectionStatus = '连接成功';
      });

      Toast.show(
        context,
        "数据发送成功",
        type: ToastType.success,
      );
    } catch (e) {
      print('连接错误: $e');
      setState(() {
        connectionStatus = '连接失败';
      });

      Toast.show(
        context,
        "连接失败",
        type: ToastType.error,
      );
    }
  }

  // 发送机器人偏移数据
  void _sendRobotOffsetData(String axis, double value) {
    int coordinateType;
    switch (axis) {
      case 'X':
        coordinateType = 1;
        break;
      case 'Y':
        coordinateType = 2;
        break;
      case 'Z':
        coordinateType = 3;
        break;
      default:
        coordinateType = 1;
    }

    if (isInformation) {
      _sendTCPData(
        modeType: 3, // 3表示机器人偏移模式
        coordinateType: coordinateType,
        value: value,
      );
      setState(() {
        isInformation = false;
      });
    } else {
      Toast.show(
        context,
        "没有收到服务端回传信息!",
        type: ToastType.error,
      );
    }
  }

  Future<bool> testConnection(String ip, int port,
      {int timeoutSeconds = 5}) async {
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: Duration(seconds: timeoutSeconds),
      );
      socket.destroy();
      return true;
    } catch (e) {
      print('连接失败: $e');
      return false;
    }
  }

  void _handleGoValueChanged(newValue, key) {
    if (key == "current") {
      setState(() {
        _currentValue = newValue;
      });
    } else if (key == "voltage") {
      setState(() {
        _voltageValue = newValue;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    ipController.text = '127.0.0.1';
    portController.text = '9998';

    // 初始化能源控制器的默认值
    energyControllers['current']?.text = '0.0';
    energyControllers['voltage']?.text = '0.0';

    _startTcpServer();
  }

  @override
  void dispose() {
    _socket?.close();
    _subscription?.cancel();
    _tcpServer.stopServer();
    energyControllers.forEach((_, controller) => controller.dispose());
    robotOffsetControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text('焊接实时配置'),
    ),
    body: Padding(
    padding: const EdgeInsets.all(16.0),
    child: ListView(
    children: [
    // 连接设置卡片
    CustomCardNew(
    title: '连接设置',
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
    Expanded(
    child: TextField(
    controller: ipController,
    decoration: InputDecoration(
    labelText: 'IP 地址',
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8)),
    errorText: ipError,
    ),
    onChanged: (value) {
    setState(() {
    ipError = IpUtils.isIpValid(value)
    ? null
        : '请输入有效的 IP 地址';
    });
    },
    ),
    ),
    const SizedBox(width: 10),
    Expanded(
    child: TextField(
    controller: portController,
    decoration: InputDecoration(
    labelText: '端口',
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8)),
    errorText: portError,
    ),
    onChanged: (value) {
    setState(() {
    portError = IpUtils.validatePort(value)
    ? null
        : '请输入有效的端口号（1-65535）';
    });
    },
    ),
    ),
    const SizedBox(width: 10),
    ElevatedButton(
    onPressed: () async {
    if (IpUtils.isIpValid(ipController.text) &&
    IpUtils.validatePort(portController.text)) {
    int port = int.parse(portController.text);
    bool isConnected =
    await testConnection(ipController.text, port);
    setState(() {
    connectionStatus = isConnected ? "连接成功" : "连接失败";
    });
    if (!isConnected) {
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('连接失败，请检查网络设置')),
    );
    }
    } else {
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('IP 地址或端口无效，请检查')),
    );
    }
    },style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
    ),
      child: const Text('连接'),
    ),
    ],
    ),
      const SizedBox(height: 20),
      if (connectionStatus != null)
        Text(
          '连接状态: $connectionStatus',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: connectionStatus == '连接成功'
                ? Colors.green
                : Colors.red,
          ),
        ),
    ],
    ),
    ),

      // 能源监控卡片
      CustomCardNew(
        title: '能源监控',
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: 10.0,
            crossAxisSpacing: 10.0,
            childAspectRatio: 3.0,
            physics: NeverScrollableScrollPhysics(),
            children: fields.map((field) {
              return TextField(
                controller: energyControllers[field.key],
                readOnly: true,
                decoration: InputDecoration(
                  labelText: '${field.label}(${field.unit})',
                  border: const OutlineInputBorder(),
                ),
              );
            }).toList(),
          ),
        ),
      ),

      // 调节电流电压卡片
      CustomCardNew(
        title: '调节电流电压',
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              GridView.count(
                crossAxisCount: 1,
                shrinkWrap: true,
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
                childAspectRatio: 4.0,
                physics: const NeverScrollableScrollPhysics(),
                children: fields.map((field) {
                  return CounterWidget(
                    height: 80,
                    width: 200,
                    title: '${field.label} (${field.unit})',
                    initialValue: field.minValue!,
                    step: field.autoIncrementValue!,
                    maxValue: field.maxValue,
                    minValue: field.minValue,
                    maxErrorText: field.maxValue != null
                        ? '${field.label}不能超过${field.maxValue}${field.unit}'
                        : null,
                    minErrorText: field.minValue != null
                        ? '${field.label}不能小于${field.minValue}${field.unit}'
                        : null,
                    backgroundColor: Colors.grey.shade200,
                    iconColor: Colors.black,
                    textStyle: const TextStyle(
                        fontSize: 25.0, color: Colors.black),
                    onChanged: (value) =>
                        _handleGoValueChanged(value, field.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              IconTextButton(
                filled: true,
                height: 50,
                width: 150,
                icon: Icons.send,
                text: '发送',
                iconColor: Colors.grey,
                textColor: Colors.grey,
                iconSize: 30.0,
                textSize: 20.0,
                onPressed: () async {
                  await _sendTCPData1(
                      current: 'current',
                      currentValue: _currentValue,
                      voltage: 'voltage',
                      voltageValue: _voltageValue
                  );
                },
              ),
            ],
          ),
        ),
      ),

      // 调节机器人偏移卡片
      CustomCardNew(
        title: '调节机器人偏移',
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 1,
              shrinkWrap: true,
              mainAxisSpacing: 10.0,
              crossAxisSpacing: 10.0,
              childAspectRatio: 1.7,
              physics: const NeverScrollableScrollPhysics(),
              children: robotOffsetFields.map((field) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: CounterWidgetFour(
                    initialValue: 0,
                    step: field.autoIncrementValue!,
                    title: field.label,
                    backgroundColor: Colors.grey.shade200,
                    iconColor: Colors.blue,
                    textStyle: const TextStyle(
                        fontSize: 20, color: Colors.black),
                    titleStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    onLeftPressed: (value) {
                      _sendRobotOffsetData(field.key, value.toDouble());
                    },
                    onRightPressed: (value) {
                      _sendRobotOffsetData(field.key, value.toDouble());
                    },
                    onChanged: (value) =>
                        _handleGoValueChanged(value, field.key),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ],
    ),
    ),
    );
  }
}