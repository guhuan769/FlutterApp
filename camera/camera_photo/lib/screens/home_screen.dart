// lib/screens/home_screen.dart
import 'package:camera_photo/config/upload_options.dart';
import 'package:camera_photo/screens/system_camera_screen.dart';
import 'package:camera_photo/services/system_camera_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../models/project.dart';
import '../widgets/upload_status_widget.dart';
import 'camera_screen.dart';
import 'project_photos_screen.dart';
import 'qr_scanner_screen.dart';
import 'batch_qr_scanner_screen.dart';
import 'qr_generator_screen.dart';
// 1. 在文件头部添加导入
import 'qr_scanner_screen.dart';
import 'batch_qr_scanner_screen.dart';
import 'qr_test_page.dart'; // 仅在开发测试时使用
import 'system_camera_screen.dart'; // 添加在文件头部

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
              itemCount: provider.uploadStatuses.length,
              itemBuilder: (context, index) {
                final status = provider.uploadStatuses.values.elementAt(index);
                return UploadStatusWidget(
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

  // 在 HomeScreen 中更新创建轨迹的方法 - 自动根据现有轨迹数量生成序号名称
  void _showCreateTrackDialog(Project project) {
    // 自动生成序号名称 (基于已有轨迹数量 + 1)
    final nextTrackNumber = project.tracks.length + 1;
    final autoTrackName = nextTrackNumber.toString();

    // 预设轨迹名称为数字序号
    _nameController.text = autoTrackName;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建轨迹'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '轨迹名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
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
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                try {
                  final provider = Provider.of<ProjectProvider>(context, listen: false);
                  await provider.createTrack(_nameController.text, project.id);

                  // 确保显示新创建的轨迹
                  await provider.initialize();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('轨迹 "${_nameController.text}" 创建成功')),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('创建轨迹失败: $e')),
                    );
                  }
                } finally {
                  _nameController.clear();
                }
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  // 在 HomeScreen 中更新创建轨迹的方法
  void _showCreateTrackDialog1(Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建轨迹'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '轨迹名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
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
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                try {
                  final provider = Provider.of<ProjectProvider>(context, listen: false);
                  await provider.createTrack(_nameController.text, project.id);

                  // 确保显示新创建的轨迹
                  await provider.initialize();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('轨迹 "${_nameController.text}" 创建成功')),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('创建轨迹失败: $e')),
                    );
                  }
                } finally {
                  _nameController.clear();
                }
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUploadConfirmation(Project project) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认上传'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('项目名称: ${project.name}'),
            const SizedBox(height: 8),
            Text('照片数量: ${project.photos.length}'),
            Text('轨迹数量: ${project.tracks.length}'),
            const SizedBox(height: 16),
            // 添加类型选择
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showTypeSelectionDialog(project, UploadType.model);
                  },
                  child: const Text('模型上传'),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showTypeSelectionDialog(project, UploadType.craft);
                  },
                  child: const Text('工艺上传'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  // 添加类型选择对话框
  void _showTypeSelectionDialog(Project project, UploadType type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == UploadType.model ? '选择模型' : '选择工艺'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: (type == UploadType.model ? UploadOptions.models : UploadOptions.crafts)
                .map((value) => ListTile(
              title: Text(value),
              onTap: () {
                Navigator.pop(context);
                final provider = Provider.of<ProjectProvider>(context, listen: false);
                provider.uploadProject(project, type: type, value: value);
              },
            ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }


  Widget _buildProjectItem(BuildContext context, Project project) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 项目标题部分
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // 项目信息行
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
                        child: Row(
                          children: [
                            // 照片数量
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.photo, size: 14),
                                const SizedBox(width: 4),
                                Text('${project.photos.length}'),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // 轨迹数量
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timeline, size: 14),
                                const SizedBox(width: 4),
                                Text('${project.tracks.length}'),
                              ],
                            ),
                            const SizedBox(width: 8),
                            // 上传状态图标
                            if (Provider.of<ProjectProvider>(context).getProjectUploadStatus(project.id) != null)
                              const Icon(Icons.sync, size: 14, color: Colors.blue),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // 操作按钮组
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 查看照片按钮
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.photo_library, size: 20),
                          onPressed: () => _showPhotos(
                            context,
                            project.path,
                            '${project.name}的照片',
                          ),
                          tooltip: '查看照片',
                        ),
                      ),
                      // 拍照按钮
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.camera_alt, size: 20),
                          onPressed: () {
                            final provider = Provider.of<ProjectProvider>(context, listen: false);
                            provider.setCurrentProject(project);
                            provider.setCurrentTrack(null);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SystemCameraScreen()), // 使用SystemCameraScreen替换CameraScreen
                            );
                          },
                          tooltip: '拍照',
                        ),
                      ),
                      // 上传按钮
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.upload, size: 20),
                          onPressed: () => _showUploadConfirmation(project),
                          tooltip: '上传项目',
                        ),
                      ),
                      // 更多操作菜单
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: PopupMenuButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_vert, size: 20),
                          itemBuilder: (context) => [
                            // 重命名选项
                            PopupMenuItem(
                              child: ListTile(
                                leading: const Icon(Icons.edit),
                                title: const Text('重命名'),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onTap: () {
                                  Navigator.pop(context);
                                  Future.microtask(() {
                                    _nameController.text = project.name;
                                    _showCreateDialog(
                                      title: '重命名项目',
                                      onConfirm: (name) {
                                        Provider.of<ProjectProvider>(
                                          context,
                                          listen: false,
                                        ).renameProject(project.id, name);
                                      },
                                    );
                                  });
                                },
                              ),
                            ),
                            // 删除选项
                            PopupMenuItem(
                              child: ListTile(
                                leading: const Icon(Icons.delete, color: Colors.red),
                                title: const Text('删除', style: TextStyle(color: Colors.red)),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onTap: () {
                                  Navigator.pop(context);
                                  Future.microtask(() {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('确认删除'),
                                        content: Text('确定要删除项目 "${project.name}" 吗？\n'
                                            '该操作将删除项目下的所有照片和轨迹数据。'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('取消'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Provider.of<ProjectProvider>(
                                                context,
                                                listen: false,
                                              ).deleteProject(project.id);
                                              Navigator.pop(context);
                                            },
                                            child: const Text(
                                              '删除',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [_buildTracksList(project)],
      ),
    );
  }


  void _showPhotos(BuildContext context, String path, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectPhotosScreen(
          path: path,
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


  Widget _buildTracksList(Project project) {
    return Column(
      children: [
        ...project.tracks.map((track) => ListTile(
          leading: const Icon(Icons.timeline),
          title: Text(track.name),
          subtitle: Text('${track.photos.length} 张照片'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.photo_library),
                onPressed: () => _showPhotos(
                  context,
                  track.path,
                  '${project.name} - ${track.name}的照片',
                ),
              ),

              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: () {
                  final provider = Provider.of<ProjectProvider>(
                    context,
                    listen: false,
                  );
                  provider.setCurrentProject(project);
                  provider.setCurrentTrack(track);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SystemCameraScreen()), // 使用SystemCameraScreen替换CameraScreen
                  );
                },
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('重命名'),
                    onTap: () {
                      Future.microtask(() {
                        _nameController.text = track.name;
                        _showCreateDialog(
                          title: '重命名轨迹',
                          onConfirm: (name) {
                            Provider.of<ProjectProvider>(
                              context,
                              listen: false,
                            ).renameTrack(project.id, track.id, name);
                          },
                        );
                      });
                    },
                  ),
                  PopupMenuItem(
                    child: const Text('删除'),
                    onTap: () {
                      Future.microtask(() {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('确认删除'),
                            content: Text('确定要删除轨迹 "${track.name}" 吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Provider.of<ProjectProvider>(
                                    context,
                                    listen: false,
                                  ).deleteTrack(project.id, track.id);
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  '删除',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton.icon(
            onPressed: () => _showCreateTrackDialog(project),
            icon: const Icon(Icons.add),
            label: const Text('添加轨迹'),
          ),
        ),
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        //   child: ElevatedButton.icon(
        //     onPressed: () => _showCreateDialog(
        //       title: '新建轨迹',
        //       onConfirm: (name) {
        //         Provider.of<ProjectProvider>(
        //           context,
        //           listen: false,
        //         ).createTrack(name, project.id);
        //       },
        //     ),
        //     icon: const Icon(Icons.add),
        //     label: const Text('添加轨迹'),
        //   ),
        // ),
      ],
    );
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
                    context,
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