// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../models/project.dart';
import '../widgets/upload_status_widget.dart';
import '../widgets/upload_history_dialog.dart';
import '../config/upload_options.dart';
import 'qr_scanner_screen.dart';
import 'batch_qr_scanner_screen.dart';
import 'project_photos_screen.dart';
import 'camera_screen.dart';
import 'qr_generator_screen.dart';
import 'qr_test_page.dart'; // 仅在开发测试时使用
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:file/file.dart';
import 'package:camera_photo/providers/project_provider.dart';
import 'package:camera_photo/providers/photo_provider.dart';

// 添加用于存储项目信息的辅助类
class ItemInfo {
  final String type;
  final Project? project;
  final Vehicle? vehicle;
  final Track? track;

  ItemInfo({
    required this.type,
    this.project,
    this.vehicle,
    this.track,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nameController = TextEditingController();
  // 添加滚动控制器用于上传状态面板
  final ScrollController _statusScrollController = ScrollController();
  late ProjectProvider _projectProvider;
  late PhotoProvider _photoProvider;
  // 添加ScaffoldMessengerState引用
  ScaffoldMessengerState? _scaffoldMessenger;
  
  // 添加折叠状态管理
  final Map<String, bool> _expandedProjects = {};
  final Map<String, bool> _expandedVehicles = {};

  // 添加用于计算总项目数的辅助方法
  int _calculateTotalItems(List<Project> projects) {
    int total = 0;
    for (var project in projects) {
      total += 1; // 项目本身
      for (var vehicle in project.vehicles) {
        total += 1; // 车辆
        total += vehicle.tracks.length; // 该车辆的所有轨迹
      }
    }
    return total;
  }

  // 添加用于获取指定索引项的辅助方法
  ItemInfo _getItemAtIndex(List<Project> projects, int index) {
    int currentIndex = 0;
    
    for (var project in projects) {
      if (currentIndex == index) {
        return ItemInfo(type: 'project', project: project);
      }
      currentIndex++;

      for (var vehicle in project.vehicles) {
        if (currentIndex == index) {
          return ItemInfo(type: 'vehicle', project: project, vehicle: vehicle);
        }
        currentIndex++;

        for (var track in vehicle.tracks) {
          if (currentIndex == index) {
            return ItemInfo(type: 'track', project: project, vehicle: vehicle, track: track);
          }
          currentIndex++;
        }
      }
    }

    throw Exception('Index out of range');
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<ProjectProvider>(context, listen: false).initialize());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    _photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    // 保存ScaffoldMessenger引用
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _statusScrollController.dispose();
    super.dispose();
  }


// 跳转到二维码扫描页面
  void _navigateToQRScanner() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QRScannerScreen()),
      );

      // 如果扫描被取消或返回null
      if (result == null || result.toString().trim().isEmpty) {
        return;
      }

      // 打印扫描结果，方便调试
      print('扫描到的二维码内容: $result');

      // 尝试解码UTF-8内容
      try {
        String projectName = result.toString().trim();
        
        // 如果内容看起来像JSON，尝试解析它
        if (projectName.startsWith('{') && projectName.endsWith('}')) {
          try {
            final Map<String, dynamic> jsonData = json.decode(projectName);
            if (jsonData.containsKey('name')) {
              projectName = jsonData['name'].toString();
            }
          } catch (e) {
            print('JSON解析失败，使用原始内容: $e');
          }
        }

        // 创建项目
        await Provider.of<ProjectProvider>(context, listen: false)
            .createProject(projectName);

        if (!mounted) return;
        
        // 显示成功提示
        _showSnackBar('已创建项目: "$projectName"');

        // 刷新项目列表
        Provider.of<ProjectProvider>(context, listen: false).initialize();
      } catch (e) {
        if (!mounted) return;
        
        // 显示创建失败提示，并提供更详细的错误信息
        _showSnackBar('创建项目失败: ${e.toString()}');
      }
    } catch (e) {
      if (!mounted) return;
      
      // 显示扫描错误提示
      _showSnackBar('扫描失败: ${e.toString()}');
    }
  }


// 跳转到批量扫描页面
  void _navigateToBatchQRScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BatchQRScannerScreen()),
    );

    if (result == true) {
      // 批量扫描成功并创建了项目，刷新项目列表
      Provider.of<ProjectProvider>(context, listen: false).initialize();
    }
  }


// 跳转到测试页面（仅在开发阶段使用）
  void _navigateToTestPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRTestPage()),
    );
  }

// 跳转到二维码生成页面
  void _navigateToQRGenerator(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRGeneratorScreen(project: project),
      ),
    );
  }


// 显示创建项目的选项
  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  '创建新项目',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('手动输入项目名称'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateDialog(
                    title: '新建项目',
                    onConfirm:  (name) => _createProjectWithErrorHandling(name),
                    // onConfirm: (name) => Provider.of<ProjectProvider>(
                    //   context,
                    //   listen: false,
                    // ).createProject(name),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('扫描二维码创建项目'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToQRScanner();
                },
              ),
              // ListTile(
              //   leading: const Icon(Icons.qr_code_2),
              //   title: const Text('批量扫描二维码'),
              //   subtitle: const Text('连续扫描多个二维码创建多个项目'),
              //   onTap: () {
              //     Navigator.pop(context);
              //     _navigateToBatchQRScanner();
              //   },
              // ),
              // 仅在开发阶段显示测试选项
              if (true) // 发布时改为 false
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('测试二维码生成器'),
                  subtitle: const Text('用于测试扫码功能'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToTestPage();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }


  // 上传状态面板
  Widget _buildUploadStatusPanel(ProjectProvider provider) {
    if (provider.uploadStatuses.isEmpty) return const SizedBox.shrink();

    final statuses = provider.uploadStatuses.values.toList()
      ..sort((a, b) => b.uploadTime.compareTo(a.uploadTime));

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      color: Colors.grey[100],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.upload_file, size: 20),
                const SizedBox(width: 8),
                Text(
                  '上传状态 (${provider.uploadStatuses.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => provider.clearCompletedUploads(),
                  child: const Text('清除已完成'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              controller: _statusScrollController,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: statuses.length,
              itemBuilder: (context, index) {
                final status = statuses[index];
                return UploadStatusWidget(
                  scrollController: _statusScrollController,
                  status: status,
                  onDismiss: status.isComplete
                      ? () => provider.clearProjectUploadStatus(status.projectId)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 在 HomeScreen 中更新创建轨迹的方法
  Future<void> _showCreateTrackDialog(Project project, Vehicle vehicle) async {
    final trackName = 'Track ${vehicle.tracks.length + 1}';
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建新轨迹'),
        content: Text('将创建轨迹: $trackName'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final track = await Provider.of<ProjectProvider>(context, listen: false)
                    .createTrack(trackName, vehicle.id);
                
                // 导航到照片界面
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProjectPhotosScreen(
                      directoryPath: track.path,
                      title: track.name,
                    ),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                _showSnackBar('创建轨迹失败: $e');
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _showProjectOptions(Project project) async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.folder, color: Colors.blue, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${project.vehicles.length} 辆车, ${_getTotalPhotos(project)} 张照片',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildOptionTile(
                        icon: Icons.cloud_upload,
                        iconColor: Colors.blue,
                        title: '上传项目',
                        subtitle: '将项目数据上传到服务器',
                        onTap: () async {
                          Navigator.pop(context);
                          await _showUploadConfirmation(project);
                        },
                      ),
                      _buildOptionTile(
                        icon: Icons.history,
                        iconColor: Colors.purple,
                        title: '上传历史',
                        subtitle: '查看项目的上传记录',
                        onTap: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (context) => UploadHistoryDialog(
                              projectId: project.id,
                              projectName: project.name,
                            ),
                          );
                        },
                      ),
                      _buildOptionTile(
                        icon: Icons.directions_car,
                        iconColor: Colors.green,
                        title: '新增车辆',
                        subtitle: '为项目添加新的车辆',
                        onTap: () {
                          Navigator.pop(context);
                          _showCreateVehicleDialog(project);
                        },
                      ),
                      _buildOptionTile(
                        icon: Icons.edit,
                        iconColor: Colors.orange,
                        title: '编辑项目',
                        subtitle: '修改项目名称',
                        onTap: () {
                          Navigator.pop(context);
                          _showCreateDialog(
                            title: '重命名项目',
                            onConfirm: (name) => provider.renameProject(project.id, name),
                          );
                        },
                      ),
                      _buildOptionTile(
                        icon: Icons.delete,
                        iconColor: Colors.red,
                        title: '删除项目',
                        subtitle: '永久删除项目及其所有数据',
                        onTap: () {
                          Navigator.pop(context);
                          _showDeleteConfirmationDialog(
                            title: '确认删除',
                            content: '确定要删除项目 "${project.name}" 吗？\n该操作将删除项目下的所有车辆、照片和轨迹数据。',
                            onConfirm: () async => await provider.deleteProject(project.id),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _showUploadConfirmation(Project project) async {
    int totalPhotos = project.photos.length;
    int totalVehicles = project.vehicles.length;
    
    for (var vehicle in project.vehicles) {
      totalPhotos += vehicle.photos.length;
      for (var track in vehicle.tracks) {
        totalPhotos += track.photos.length;
      }
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.cloud_upload, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('确认上传'),
            ],
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.folder, '项目名称', project.name),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.photo_library, '照片数量', '$totalPhotos'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.directions_car, '车辆数量', '$totalVehicles'),
                const SizedBox(height: 20),
                const Text(
                  '请选择上传类型:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildUploadTypeButton(
                      context,
                      icon: Icons.architecture,
                      label: '模型',
                      color: Colors.blue,
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _showTypeSelectionDialog(project, UploadType.model);
                      },
                    ),
                    _buildUploadTypeButton(
                      context,
                      icon: Icons.build,
                      label: '工艺',
                      color: Colors.green,
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _showTypeSelectionDialog(project, UploadType.craft);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadTypeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTypeSelectionDialog(Project project, UploadType type) async {
    List<String> options = [];
    if (type == UploadType.model) {
      options = ['A', 'B', 'C', 'D'];
    } else {
      options = ['1', '2', '3', '4'];
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                type == UploadType.model ? Icons.architecture : Icons.build,
                color: type == UploadType.model ? Colors.blue : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                '选择${type == UploadType.model ? "模型" : "工艺"}类型',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 300),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              shrinkWrap: true,
              children: options.map((option) => _buildOptionButton(
                context,
                option: option,
                type: type,
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    final projectProvider = Provider.of<ProjectProvider>(
                      context,
                      listen: false,
                    );
                    
                    // 显示上传中的提示
                    _showSnackBar('开始上传项目 ${project.name}，请稍候...');
                    
                    // 使用异步上传并处理可能的异常
                    await projectProvider.uploadProject(
                      project, 
                      type: type, 
                      value: option
                    );
                    
                    if (mounted) {
                      _showSnackBar('项目 ${project.name} 上传成功');
                    }
                  } catch (e) {
                    if (mounted) {
                      // 显示更友好的错误信息
                      String errorMsg = e.toString();
                      if (errorMsg.contains('ply文件生成失败')) {
                        errorMsg = '文件上传成功，但处理过程出现问题';
                      }
                      _showSnackBar('上传未完成: $errorMsg');
                    }
                  }
                },
              )).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required String option,
    required UploadType type,
    required VoidCallback onTap,
  }) {
    final color = type == UploadType.model ? Colors.blue : Colors.green;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              option,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectItem(Project project) {
    bool isExpanded = _expandedProjects[project.id] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _showProjectOptions(project),
            onLongPress: () {
              setState(() {
                _expandedProjects[project.id] = !isExpanded;
                // 如果折叠项目，同时折叠所有车辆
                if (!isExpanded) {
                  for (var vehicle in project.vehicles) {
                    _expandedVehicles[vehicle.id] = false;
                  }
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedProjects[project.id] = !isExpanded;
                        // 如果折叠项目，同时折叠所有车辆
                        if (!isExpanded) {
                          for (var vehicle in project.vehicles) {
                            _expandedVehicles[vehicle.id] = false;
                          }
                        }
                      });
                    },
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: isExpanded ? 0.25 : 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.keyboard_arrow_right, color: Colors.blue, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.folder, color: Colors.blue, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.directions_car, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${project.vehicles.length}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.photo, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${project.photos.length}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                children: [
                  const Divider(height: 1),
                  Row(
                    children: [
                      _buildProjectAction(
                        icon: Icons.photo_library,
                        label: '照片',
                        onTap: () => _showPhotos(context, project.path, '${project.name}的照片'),
                      ),
                      _buildProjectAction(
                        icon: Icons.camera_alt,
                        label: '拍摄',
                        onTap: () {
                          final provider = Provider.of<ProjectProvider>(context, listen: false);
                          provider.setCurrentProject(project);
                          provider.setCurrentVehicle(null);
                          provider.setCurrentTrack(null);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CameraScreen(),
                              settings: RouteSettings(
                                arguments: {
                                  'project': project,
                                  'vehicle': null,
                                  'track': null,
                                  'photoType': '模型点拍照',
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      _buildProjectAction(
                        icon: Icons.directions_car,
                        label: '车辆',
                        onTap: () => _showCreateVehicleDialog(project),
                      ),
                      _buildProjectAction(
                        icon: Icons.cloud_upload,
                        label: '上传',
                        onTap: () => _showUploadConfirmation(project),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: Colors.grey[700]),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleItem(Project project, Vehicle vehicle) {
    bool isExpanded = _expandedVehicles[vehicle.id] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(48, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _showVehicleOptions(project, vehicle),
            onLongPress: () {
              setState(() {
                _expandedVehicles[vehicle.id] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedVehicles[vehicle.id] = !isExpanded;
                      });
                    },
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: isExpanded ? 0.25 : 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.keyboard_arrow_right, color: Colors.green, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.directions_car, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.timeline, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${vehicle.tracks.length}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.photo, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${vehicle.photos.length}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                children: [
                  const Divider(height: 1),
                  Row(
                    children: [
                      _buildVehicleAction(
                        icon: Icons.photo_library,
                        label: '照片',
                        onTap: () => _showPhotos(
                          context,
                          vehicle.path,
                          '${project.name} - ${vehicle.name}的照片',
                        ),
                      ),
                      _buildVehicleAction(
                        icon: Icons.camera_alt,
                        label: '拍摄',
                        onTap: () {
                          final provider = Provider.of<ProjectProvider>(context, listen: false);
                          provider.setCurrentProject(project);
                          provider.setCurrentVehicle(vehicle);
                          provider.setCurrentTrack(null);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CameraScreen(),
                              settings: RouteSettings(
                                arguments: {
                                  'project': project,
                                  'vehicle': vehicle,
                                  'track': null,
                                  'photoType': '模型点拍照',
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      _buildVehicleAction(
                        icon: Icons.timeline,
                        label: '轨迹',
                        onTap: () => _showCreateTrackDialog(project, vehicle),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.grey[700]),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackItem(Project project, Vehicle vehicle, Track track) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(64, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _showTrackOptions(project, vehicle, track),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.timeline, color: Colors.orange, size: 18),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.photo, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${track.photos.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Column(
              children: [
                const Divider(height: 1),
                Row(
                  children: [
                    _buildTrackAction(
                      icon: Icons.photo_library,
                      label: '照片',
                      onTap: () => _showPhotos(
                        context,
                        track.path,
                        '${project.name} - ${vehicle.name} - ${track.name}的照片',
                      ),
                    ),
                    _buildTrackAction(
                      icon: Icons.camera_alt,
                      label: '拍摄',
                      onTap: () {
                        final provider = Provider.of<ProjectProvider>(context, listen: false);
                        provider.setCurrentProject(project);
                        provider.setCurrentVehicle(vehicle);
                        provider.setCurrentTrack(track);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CameraScreen(),
                            settings: RouteSettings(
                              arguments: {
                                'project': project,
                                'vehicle': vehicle,
                                'track': track,
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.grey[700]),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateVehicleDialog(Project project) {
    _showCreateDialog(
      title: '新建车辆',
      onConfirm: (name) async {
        try {
          final provider = Provider.of<ProjectProvider>(context, listen: false);
          await provider.createVehicle(name, project.id);
          if (mounted) {
            _showSnackBar('车辆 "$name" 创建成功');
          }
        } catch (e) {
          if (mounted) {
            _showSnackBar('创建车辆失败: $e');
          }
        }
      },
    );
  }

  void _showDeleteConfirmationDialog({
    required String title,
    required String content,
    required Function onConfirm,
  }) {
    // 在对话框弹出前先获取 Provider
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // 先关闭确认对话框
                Navigator.pop(dialogContext);
                // 执行删除操作
                await onConfirm();
                // 删除成功后刷新列表
                provider.initialize();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('删除成功')),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('删除失败: $e')),
                );
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showPhotos(BuildContext context, String directoryPath, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectPhotosScreen(
          directoryPath: directoryPath,
          title: title,
        ),
      ),
    );
  }

  // 1. 修复 _showCreateDialog 方法
  void _showCreateDialog({
    required String title,
    required Function(String) onConfirm,
  }) {
    // 确保每次打开对话框时都重置文本控制器
    _nameController.clear();

    showDialog(
      context: context,
      barrierDismissible: false, // 防止用户点击外部关闭对话框
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '名称',
            border: OutlineInputBorder(),
            // 添加更明确的提示
            hintText: '请输入项目名称',
          ),
          autofocus: true,
          // 添加提交功能
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              onConfirm(value);
              Navigator.pop(context);
              _nameController.clear();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nameController.clear();
              Navigator.pop(context);
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // 确保名称不为空
              if (_nameController.text.trim().isNotEmpty) {
                onConfirm(_nameController.text.trim());
                Navigator.pop(context);
                _nameController.clear();
              } else {
                // 显示错误提示
                _showSnackBar('项目名称不能为空');
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }


// 2. 使用 try-catch 包装项目创建过程，以捕获并显示任何错误
  void _createProjectWithErrorHandling(String name) async {
    try {
      final provider = Provider.of<ProjectProvider>(context, listen: false);
      await provider.createProject(name);

      if (mounted) {
        _showSnackBar('项目 "$name" 创建成功');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('创建项目失败: $e');
      }
      print('创建项目错误: $e');
    }
  }

  void _showVehicleOptions(Project project, Vehicle vehicle) {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.directions_car, color: Colors.green),
                    ),
                    title: Text(
                      vehicle.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${vehicle.tracks.length} 条轨迹, ${_getVehiclePhotos(vehicle)} 张照片',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_circle, color: Colors.blue),
                    ),
                    title: const Text('添加轨迹'),
                    subtitle: const Text('为该车辆添加新的轨迹'),
                    onTap: () {
                      Navigator.pop(context);
                      _showCreateTrackDialog(project, vehicle);
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit, color: Colors.orange),
                    ),
                    title: const Text('重命名'),
                    subtitle: const Text('修改车辆名称'),
                    onTap: () {
                      Navigator.pop(context);
                      _showCreateDialog(
                        title: '重命名车辆',
                        onConfirm: (name) => provider.renameVehicle(project.id, vehicle.id, name),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete, color: Colors.red),
                    ),
                    title: const Text('删除车辆'),
                    subtitle: const Text('永久删除车辆及其所有数据'),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteConfirmationDialog(
                        title: '确认删除',
                        content: '确定要删除车辆 "${vehicle.name}" 吗？\n该操作将删除该车辆下的所有照片和轨迹数据。',
                        onConfirm: () => provider.deleteVehicle(project.id, vehicle.id),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTrackOptions(Project project, Vehicle vehicle, Track track) {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  title: Text(track.name),
                  subtitle: Text('${track.photos.length} 张照片'),
                ),
                const Divider(height: 32),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit, color: Colors.orange),
                  ),
                  title: const Text('重命名轨迹'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateDialog(
                      title: '重命名轨迹',
                      onConfirm: (name) => provider.renameTrack(vehicle.id, track.id, name),
                    );
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: const Text('删除轨迹'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmationDialog(
                      title: '确认删除',
                      content: '确定要删除轨迹 "${track.name}" 吗？',
                      onConfirm: () => provider.deleteTrack(vehicle.id, track.id),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 修改获取项目照片数的方法，只统计项目目录下的照片
  int _getTotalPhotos(Project project) {
    // 只返回项目直接目录下的照片数量
    return project.photos.length;
  }

  // 修改获取车辆照片数的方法，只统计车辆目录下的照片
  int _getVehiclePhotos(Vehicle vehicle) {
    // 只返回车辆直接目录下的照片数量
    return vehicle.photos.length;
  }

  // 在 home_screen.dart 中添加照片名称格式化方法
  String _formatPhotoName(String photoPath) {
    final fileName = path.basename(photoPath);
    final RegExp pattern = RegExp(r'(.*?)_(\d+)\.jpg$');
    final match = pattern.firstMatch(fileName);
    
    if (match != null) {
      final prefix = match.group(1);
      final number = match.group(2);
      return '$prefix #$number';
    }
    return fileName;
  }

  // 使用保存的引用显示SnackBar
  void _showSnackBar(String message) {
    if (_scaffoldMessenger != null && mounted) {
      _scaffoldMessenger!.showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            title: const Text(
              '项目管理',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              // 添加全部展开/折叠按钮
              IconButton(
                icon: const Icon(Icons.unfold_more),
                tooltip: '展开/折叠全部',
                onPressed: () {
                  setState(() {
                    bool allExpanded = provider.projects.every((p) => _expandedProjects[p.id] ?? true);
                    for (var project in provider.projects) {
                      _expandedProjects[project.id] = !allExpanded;
                      for (var vehicle in project.vehicles) {
                        _expandedVehicles[vehicle.id] = !allExpanded;
                      }
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: '扫描二维码添加项目',
                onPressed: _navigateToQRScanner,
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ],
          ),
          body: Column(
            children: [
              _buildUploadStatusPanel(provider),
              Expanded(
                child: provider.projects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '暂无项目',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _showCreateOptions,
                              icon: const Icon(Icons.add),
                              label: const Text('创建项目'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: provider.projects.length,
                        itemBuilder: (context, index) {
                          final project = provider.projects[index];
                          bool isProjectExpanded = _expandedProjects[project.id] ?? false;
                          
                          List<Widget> items = [_buildProjectItem(project)];
                          
                          if (isProjectExpanded) {
                            for (var vehicle in project.vehicles) {
                              bool isVehicleExpanded = _expandedVehicles[vehicle.id] ?? false;
                              items.add(_buildVehicleItem(project, vehicle));
                              
                              if (isVehicleExpanded) {
                                items.addAll(vehicle.tracks.map(
                                  (track) => _buildTrackItem(project, vehicle, track)
                                ));
                              }
                            }
                          }
                          
                          return Column(children: items);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: provider.projects.isNotEmpty
              ? FloatingActionButton(
                  heroTag: 'home_add_project',
                  onPressed: _showCreateOptions,
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }
}