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

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nameController = TextEditingController();
  // 添加滚动控制器用于上传状态面板
  final ScrollController _statusScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<ProjectProvider>(context, listen: false).initialize());
  }

  @override
  void dispose() {
    _statusScrollController.dispose();
    super.dispose();
  }


// 跳转到二维码扫描页面
  void _navigateToQRScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result == true) {
      // 扫描成功并创建了项目，刷新项目列表
      Provider.of<ProjectProvider>(context, listen: false).initialize();
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('创建轨迹失败: $e')),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _showProjectOptions(Project project) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.folder, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          project.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_upload),
                  title: const Text('上传项目'),
                  subtitle: const Text('将项目数据上传到服务器'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _showUploadConfirmation(project);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('上传历史'),
                  subtitle: const Text('查看项目的上传记录'),
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
                ListTile(
                  leading: const Icon(Icons.directions_car),
                  title: const Text('新增车辆'),
                  subtitle: const Text('为项目添加新的车辆'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateVehicleDialog(project);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('编辑项目'),
                  subtitle: const Text('修改项目名称'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateDialog(
                      title: '重命名项目',
                      onConfirm: (name) => Provider.of<ProjectProvider>(
                        context,
                        listen: false,
                      ).renameProject(project.id, name),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('删除项目'),
                  subtitle: const Text('永久删除项目及其所有数据'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmationDialog(
                      title: '确认删除',
                      content: '确定要删除项目 "${project.name}" 吗？\n该操作将删除项目下的所有车辆、照片和轨迹数据。',
                      onConfirm: () => Provider.of<ProjectProvider>(
                        context,
                        listen: false,
                      ).deleteProject(project.id),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
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
          title: const Text('确认上传'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('项目名称: ${project.name}'),
                const SizedBox(height: 8),
                Text('照片数量: $totalPhotos'),
                const SizedBox(height: 8),
                Text('车辆数量: $totalVehicles'),
                const SizedBox(height: 16),
                const Text('请选择上传类型:'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('模型'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _showTypeSelectionDialog(project, UploadType.model);
              },
            ),
            TextButton(
              child: const Text('工艺'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _showTypeSelectionDialog(project, UploadType.craft);
              },
            ),
          ],
        );
      },
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
          title: Text('选择${type == UploadType.model ? "模型" : "工艺"}类型'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: options.map((option) => ListTile(
                  title: Text(option),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
                    await projectProvider.uploadProject(project, type: type, value: option);
                  },
                )).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectItem(Project project) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.folder, color: Colors.blue),
        ),
        title: Text(
          project.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${project.vehicles.length} 辆车 · ${_getTotalPhotos(project)} 张照片',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.photo_library),
              tooltip: '查看照片',
              onPressed: () => _showPhotos(
                context,
                project.path,
                '${project.name}的照片',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              tooltip: '拍摄照片',
              onPressed: () {
                final provider = Provider.of<ProjectProvider>(context, listen: false);
                provider.setCurrentProject(project);
                provider.setCurrentVehicle(null);
                provider.setCurrentTrack(null);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CameraScreen(),
                    settings: RouteSettings(
                      arguments: {
                        'project': project,
                        'track': null,
                      },
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: '更多选项',
              onPressed: () => _showProjectOptions(project),
            ),
          ],
        ),
        children: project.vehicles.map((vehicle) => _buildVehicleItem(project, vehicle)).toList(),
      ),
    );
  }

  Widget _buildVehicleItem(Project project, Vehicle vehicle) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.directions_car, color: Colors.green),
          ),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${vehicle.tracks.length}轨迹 · ${_getVehiclePhotos(vehicle)}张照片',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Container(
            width: 108,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildIconButton(
                  icon: Icons.photo_library,
                  tooltip: '查看照片',
                  onPressed: () => _showPhotos(
                    context,
                    vehicle.path,
                    '${project.name} - ${vehicle.name}的照片',
                  ),
                ),
                _buildIconButton(
                  icon: Icons.camera_alt,
                  tooltip: '拍摄照片',
                  onPressed: () {
                    final provider = Provider.of<ProjectProvider>(context, listen: false);
                    provider.setCurrentProject(project);
                    provider.setCurrentVehicle(vehicle);
                    provider.setCurrentTrack(null);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CameraScreen(),
                        settings: RouteSettings(
                          arguments: {
                            'project': project,
                            'track': null,
                          },
                        ),
                      ),
                    );
                  },
                ),
                _buildIconButton(
                  icon: Icons.more_vert,
                  tooltip: '更多选项',
                  onPressed: () => _showVehicleOptions(project, vehicle),
                ),
              ],
            ),
          ),
          children: vehicle.tracks.map((track) => _buildTrackItem(project, vehicle, track)).toList(),
        ),
      ),
    );
  }

  Widget _buildTrackItem(Project project, Vehicle vehicle, Track track) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.timeline, color: Colors.orange),
          ),
          title: Text(
            track.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${track.photos.length}张照片',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          trailing: Container(
            width: 108,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildIconButton(
                  icon: Icons.photo_library,
                  tooltip: '查看照片',
                  onPressed: () => _showPhotos(
                    context,
                    track.path,
                    '${project.name} - ${vehicle.name} - ${track.name}的照片',
                  ),
                ),
                _buildIconButton(
                  icon: Icons.camera_alt,
                  tooltip: '拍摄照片',
                  onPressed: () {
                    final provider = Provider.of<ProjectProvider>(context, listen: false);
                    provider.setCurrentProject(project);
                    provider.setCurrentVehicle(vehicle);
                    provider.setCurrentTrack(track);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CameraScreen(),
                        settings: RouteSettings(
                          arguments: {
                            'project': project,
                            'track': track,
                          },
                        ),
                      ),
                    );
                  },
                ),
                _buildIconButton(
                  icon: Icons.more_vert,
                  tooltip: '更多选项',
                  onPressed: () => _showTrackOptions(project, vehicle, track),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 添加一个通用的IconButton构建方法
  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        icon: Icon(icon, size: 20),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: onPressed,
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('车辆 "$name" 创建成功')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('创建车辆失败: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  void _showDeleteConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('项目名称不能为空'),
                    backgroundColor: Colors.red,
                  ),
                );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('项目 "$name" 创建成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建项目失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('创建项目错误: $e');
    }
  }

  void _showVehicleOptions(Project project, Vehicle vehicle) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        vehicle.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('重命名'),
                subtitle: const Text('修改车辆名称'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateDialog(
                    title: '重命名车辆',
                    onConfirm: (name) => Provider.of<ProjectProvider>(
                      context,
                      listen: false,
                    ).renameVehicle(project.id, vehicle.id, name),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle),
                title: const Text('添加轨迹'),
                subtitle: const Text('为该车辆添加新的轨迹'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateTrackDialog(project, vehicle);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                subtitle: const Text('永久删除车辆及其所有数据'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(
                    title: '确认删除',
                    content: '确定要删除车辆 "${vehicle.name}" 吗？\n该操作将删除该车辆下的所有照片和轨迹数据。',
                    onConfirm: () => Provider.of<ProjectProvider>(
                      context,
                      listen: false,
                    ).deleteVehicle(project.id, vehicle.id),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrackOptions(Project project, Vehicle vehicle, Track track) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.timeline, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        track.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('重命名'),
                subtitle: const Text('修改轨迹名称'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateDialog(
                    title: '重命名轨迹',
                    onConfirm: (name) => Provider.of<ProjectProvider>(
                      context,
                      listen: false,
                    ).renameTrack(vehicle.id, track.id, name),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                subtitle: const Text('永久删除轨迹及其所有数据'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(
                    title: '确认删除',
                    content: '确定要删除轨迹 "${track.name}" 吗？\n该操作将删除该轨迹下的所有照片。',
                    onConfirm: () => Provider.of<ProjectProvider>(
                      context,
                      listen: false,
                    ).deleteTrack(vehicle.id, track.id),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // 添加获取项目总照片数的辅助方法
  int _getTotalPhotos(Project project) {
    int total = project.photos.length;
    for (var vehicle in project.vehicles) {
      total += vehicle.photos.length;
      for (var track in vehicle.tracks) {
        total += track.photos.length;
      }
    }
    return total;
  }

  // 添加获取车辆总照片数的辅助方法
  int _getVehiclePhotos(Vehicle vehicle) {
    int total = vehicle.photos.length;
    for (var track in vehicle.tracks) {
      total += track.photos.length;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('项目管理'),
            actions: [
              // 添加扫描按钮
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
              // 上传状态面板
              _buildUploadStatusPanel(provider),
              // 项目列表
              Expanded(
                child: provider.projects.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('暂无项目'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateDialog(
                          title: '新建项目',
                          onConfirm: (name) => provider.createProject(name),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('创建第一个项目'),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: provider.projects.length,
                  itemBuilder: (context, index) => _buildProjectItem(
                    provider.projects[index],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showCreateOptions,
            child: const Icon(Icons.add),
          ),
          // floatingActionButton: FloatingActionButton(
          //   onPressed: () => _showCreateDialog(
          //     title: '新建项目',
          //     onConfirm: (name) => provider.createProject(name),
          //   ),
          //   child: const Icon(Icons.add),
          // ),
        );
      },
    );
  }
}