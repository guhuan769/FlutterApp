// lib/screens/bluetooth_scan_screen.dart 更新版
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import 'bluetooth_debug_screen.dart';  // 导入调试工具

class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({Key? key}) : super(key: key);

  @override
  State<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  @override
  void initState() {
    super.initState();
    // 页面加载后自动开始扫描
    Future.microtask(() {
      Provider.of<BluetoothProvider>(context, listen: false).startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('连接蓝牙设备'),
        actions: [
          // 添加调试按钮
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              _showDebugMessage(context);
            },
            tooltip: '调试信息',
          ),
        ],
      ),
      body: Consumer<BluetoothProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // 错误消息
              if (provider.errorMessage.isNotEmpty)
                Container(
                  color: Colors.red.shade100,
                  padding: const EdgeInsets.all(8),
                  width: double.infinity,
                  child: Text(
                    provider.errorMessage,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),

              // 蓝牙状态
              _buildBluetoothStatus(provider),

              // LP848 设备信息提示
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.blue.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '设备说明：',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• 三脚架式蓝牙自拍杆(LP848)',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '• 请在扫描前确保设备电池已安装且开启',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '• 首次连接可能需要多次尝试',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              // 系统已连接设备
              _buildSystemConnectedDevices(context), // 更新为传入context

              // 设备列表
              Expanded(
                child: provider.devicesList.isEmpty
                    ? _buildEmptyListView(provider)
                    : _buildDeviceListView(provider, context), // 更新为传入context
              ),

              // 底部按钮
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(provider.isScanning
                            ? Icons.stop
                            : Icons.refresh),
                        label: Text(provider.isScanning
                            ? '停止扫描'
                            : '刷新设备'),
                        onPressed: provider.isScanning
                            ? () => provider.stopScan()
                            : () => provider.startScan(),
                      ),
                    ),
                    if (provider.connectionState == BtConnectionState.connected)
                      const SizedBox(width: 16),
                    if (provider.connectionState == BtConnectionState.connected)
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.bluetooth_disabled),
                          label: const Text('断开连接'),
                          onPressed: () => provider.disconnectDevice(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 显示蓝牙状态
  Widget _buildBluetoothStatus(BluetoothProvider provider) {
    IconData icon = Icons.bluetooth_disabled;
    Color color = Colors.grey;
    String statusText = '未连接';

    switch (provider.connectionState) {
      case BtConnectionState.disconnected:
        icon = Icons.bluetooth_disabled;
        color = Colors.grey;
        statusText = '未连接';
        break;
      case BtConnectionState.connecting:
        icon = Icons.bluetooth_searching;
        color = Colors.blue;
        statusText = '正在连接...';
        break;
      case BtConnectionState.connected:
        icon = Icons.bluetooth_connected;
        color = Colors.green;
        statusText = '已连接: ${provider.connectedDevice?.name ?? "LP848"}';
        break;
      case BtConnectionState.disconnecting:
        icon = Icons.bluetooth_disabled;
        color = Colors.orange;
        statusText = '正在断开连接...';
        break;
      case BtConnectionState.error:
        icon = Icons.error;
        color = Colors.red;
        statusText = '连接错误';
        break;
    }

    return Container(
      color: color.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (provider.isScanning)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
        ],
      ),
    );
  }

  // 系统已连接的设备 - 添加调试入口
  Widget _buildSystemConnectedDevices(BuildContext context) {
    // 获取已连接设备列表
    final List<BluetoothDevice> connectedDevices = FlutterBluePlus.connectedDevices;

    // 过滤出我们关心的设备
    final systemConnectedDevices = connectedDevices.where((device) =>
    device.name.contains("UGREEN") || device.name.contains("LP848")).toList();

    if (systemConnectedDevices.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bluetooth_connected, color: Colors.green),
              SizedBox(width: 8),
              Text(
                '系统已连接的设备',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Divider(),
          ...systemConnectedDevices.map((device) => ListTile(
            leading: Icon(Icons.bluetooth_connected, color: Colors.green),
            title: Text(device.name),
            subtitle: Text('点击连接 | 长按调试'),
            dense: true,
            onTap: () {
              Provider.of<BluetoothProvider>(context, listen: false)
                  .connectToDevice(device);
            },
            onLongPress: () {
              // 打开调试界面
              _navigateToDebugScreen(context, device);
            },
          )).toList(),
        ],
      ),
    );
  }

  // 空状态视图
  Widget _buildEmptyListView(BluetoothProvider provider) {
    return Center(
      child: provider.isScanning
          ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(),
          ),
          SizedBox(height: 16),
          Text('正在扫描设备...'),
          SizedBox(height: 8),
          Text(
            '请确保优绿LP848设备已开启\n并处于配对模式',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      )
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bluetooth_searching,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            '未找到设备',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            '请确保优绿LP848设备已开启\n若设备已在系统蓝牙中配对，请尝试重启应用',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () => provider.startScan(),
                icon: Icon(Icons.refresh),
                label: const Text('重新扫描'),
              ),
              SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  // 打开系统蓝牙设置
                  // 这里需要通过平台通道或插件实现
                },
                icon: Icon(Icons.settings),
                label: const Text('系统蓝牙'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 设备列表视图 - 添加调试入口
  Widget _buildDeviceListView(BluetoothProvider provider, BuildContext context) {
    return ListView.builder(
      itemCount: provider.devicesList.length,
      itemBuilder: (context, index) {
        final device = provider.devicesList[index];
        final isConnected = provider.connectedDevice?.id == device.id &&
            provider.connectionState == BtConnectionState.connected;
        final isConnecting = provider.connectedDevice?.id == device.id &&
            provider.connectionState == BtConnectionState.connecting;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Icon(
              isConnected
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth,
              color: isConnected ? Colors.green : Colors.blue,
            ),
            title: Text(
              device.name.isEmpty ? 'LP848蓝牙遥控器' : device.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.id.id),
                Text('点击连接 | 长按进入调试模式',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: isConnecting
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : isConnected
                ? const Icon(
              Icons.check_circle,
              color: Colors.green,
            )
                : const Icon(Icons.chevron_right),
            onTap: () {
              if (!isConnected && !isConnecting) {
                provider.connectToDevice(device);
              }
            },
            onLongPress: () {
              // 打开调试界面
              _navigateToDebugScreen(context, device);
            },
          ),
        );
      },
    );
  }

  // 跳转到调试界面
  void _navigateToDebugScreen(BuildContext context, BluetoothDevice device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BluetoothDebugScreen(device: device),
      ),
    );
  }

  // 显示调试信息消息框
  void _showDebugMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('蓝牙设备调试说明'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UGREEN-LP848蓝牙设备调试工具使用说明:'),
            SizedBox(height: 8),
            Text('1. 长按任意设备名称可以进入调试模式'),
            Text('2. 调试模式可以查看设备服务和特征'),
            Text('3. 找到按键触发特征后，可以将其添加到应用配置中'),
            SizedBox(height: 16),
            Text('UGREEN-LP848设备可能的服务:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('• HID服务(1812)\n• 电池服务(180F)\n• 设备信息服务(180A)\n• 自定义控制服务(FFE0)'),
            SizedBox(height: 16),
            Text('目前应用已配置服务列表:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(BluetoothProvider.POSSIBLE_SERVICE_UUIDS.join(', ')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }
}