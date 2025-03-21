package com.elon.camera_photo_system.presentation.home

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.elon.camera_photo_system.R
import com.elon.camera_photo_system.presentation.navigation.Screen

@Composable
fun HomeScreen(
    navController: NavController,
    modifier: Modifier = Modifier
) {
    var expandedProject by remember { mutableStateOf(false) }
    var expandedVehicle by remember { mutableStateOf(false) }
    var expandedTrack by remember { mutableStateOf(false) }
    var showAddProjectDialog by remember { mutableStateOf(false) }
    var showSettingsDialog by remember { mutableStateOf(false) }

    Box(modifier = modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
        ) {
            // 顶部栏
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "相机系统",
                    style = MaterialTheme.typography.headlineMedium
                )
                IconButton(onClick = { showSettingsDialog = true }) {
                    Icon(
                        painter = painterResource(R.drawable.ic_settings),
                        contentDescription = "设置"
                    )
                }
            }

            // 可滚动的内容
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
            ) {
                // 项目模块（根节点）
                TreeItem(
                    title = "项目管理",
                    expanded = expandedProject,
                    onExpandClick = { expandedProject = !expandedProject },
                    onActionClick = { navController.navigate(Screen.ProjectList.route) }
                )

                // 项目模块的子项
                AnimatedVisibility(visible = expandedProject) {
                    Column(
                        modifier = Modifier.padding(start = 32.dp)
                    ) {
                        // 项目相册
                        ActionButton(
                            text = "项目相册",
                            iconResId = R.drawable.ic_project_gallery,
                            onClick = { navController.navigate(Screen.ProjectGallery.route) }
                        )

                        // 添加车辆
                        ActionButton(
                            text = "添加车辆",
                            iconResId = R.drawable.ic_vehicle_add,
                            onClick = { /* TODO: 添加车辆功能 */ }
                        )

                        // 上传功能
                        ActionButton(
                            text = "上传项目",
                            iconResId = R.drawable.ic_project_upload,
                            onClick = { /* TODO: 上传功能 */ }
                        )

                        // 车辆子模块
                        TreeItem(
                            title = "车辆管理",
                            expanded = expandedVehicle,
                            onExpandClick = { expandedVehicle = !expandedVehicle },
                            onActionClick = { navController.navigate(Screen.VehicleList.route) }
                        )

                        // 车辆模块的子项
                        AnimatedVisibility(visible = expandedVehicle) {
                            Column(
                                modifier = Modifier.padding(start = 32.dp)
                            ) {
                                // 添加轨迹
                                ActionButton(
                                    text = "添加轨迹",
                                    iconResId = R.drawable.ic_track_add,
                                    onClick = { /* TODO: 添加轨迹功能 */ }
                                )

                                // 车辆拍照
                                ActionButton(
                                    text = "车辆拍照",
                                    iconResId = R.drawable.ic_vehicle_camera,
                                    onClick = { navController.navigate(Screen.VehicleCamera.route) }
                                )

                                // 车辆相册
                                ActionButton(
                                    text = "车辆相册",
                                    iconResId = R.drawable.ic_gallery,
                                    onClick = { navController.navigate(Screen.VehicleGallery.route) }
                                )

                                // 轨迹管理
                                TreeItem(
                                    title = "轨迹管理",
                                    expanded = expandedTrack,
                                    onExpandClick = { expandedTrack = !expandedTrack },
                                    onActionClick = { navController.navigate(Screen.TrackList.route) }
                                )

                                // 轨迹模块的子项
                                AnimatedVisibility(visible = expandedTrack) {
                                    Column(
                                        modifier = Modifier.padding(start = 32.dp)
                                    ) {
                                        // 轨迹拍照
                                        ActionButton(
                                            text = "轨迹拍照",
                                            iconResId = R.drawable.ic_camera,
                                            onClick = { navController.navigate(Screen.TrackCamera.route) }
                                        )
                                        
                                        // 轨迹相册
                                        ActionButton(
                                            text = "轨迹相册",
                                            iconResId = R.drawable.ic_gallery,
                                            onClick = { navController.navigate(Screen.TrackGallery.route) }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 全局浮动按钮
        FloatingActionButton(
            onClick = { showAddProjectDialog = true },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(16.dp)
        ) {
            Icon(
                painter = painterResource(R.drawable.ic_project_add),
                contentDescription = "添加项目"
            )
        }

        // 添加项目对话框
        if (showAddProjectDialog) {
            AlertDialog(
                onDismissRequest = { showAddProjectDialog = false },
                title = { Text("添加项目") },
                text = {
                    Column {
                        OutlinedButton(
                            onClick = { /* TODO: 手动添加项目 */ },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Icon(
                                painter = painterResource(R.drawable.ic_project_add_manual),
                                contentDescription = null,
                                modifier = Modifier.padding(end = 8.dp)
                            )
                            Text("手动添加")
                        }
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        OutlinedButton(
                            onClick = { /* TODO: 扫描二维码添加项目 */ },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Icon(
                                painter = painterResource(R.drawable.ic_project_add_scan),
                                contentDescription = null,
                                modifier = Modifier.padding(end = 8.dp)
                            )
                            Text("扫描二维码")
                        }
                    }
                },
                confirmButton = {},
                dismissButton = {
                    TextButton(onClick = { showAddProjectDialog = false }) {
                        Text("取消")
                    }
                }
            )
        }

        // 设置对话框
        if (showSettingsDialog) {
            SettingsDialog(
                onDismiss = { showSettingsDialog = false }
            )
        }
    }
}

@Composable
private fun TreeItem(
    title: String,
    expanded: Boolean,
    onExpandClick: () -> Unit,
    onActionClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val rotationState by animateFloatAsState(
        targetValue = if (expanded) 90f else 0f,
        label = "rotation"
    )

    Surface(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        color = MaterialTheme.colorScheme.primaryContainer,
        shape = MaterialTheme.shapes.small
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onExpandClick) {
                Icon(
                    painter = painterResource(R.drawable.ic_chevron_right),
                    contentDescription = if (expanded) "收起" else "展开",
                    modifier = Modifier.rotate(rotationState)
                )
            }
            
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier
                    .weight(1f)
                    .clickable(onClick = onActionClick)
            )
            
            IconButton(onClick = onActionClick) {
                Icon(
                    painter = painterResource(R.drawable.ic_arrow_forward),
                    contentDescription = "进入$title"
                )
            }
        }
    }
}

@Composable
private fun ActionButton(
    text: String,
    iconResId: Int,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        color = MaterialTheme.colorScheme.surfaceVariant,
        shape = MaterialTheme.shapes.small
    ) {
        Row(
            modifier = Modifier
                .clickable(onClick = onClick)
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                painter = painterResource(iconResId),
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary
            )
            Text(
                text = text,
                style = MaterialTheme.typography.bodyLarge
            )
        }
    }
}

@Composable
private fun SettingsDialog(
    onDismiss: () -> Unit
) {
    var defaultResolution by remember { mutableStateOf("1080p (1920x1080)") }
    var enableBluetooth by remember { mutableStateOf(true) }
    var enableAutoFocus by remember { mutableStateOf(true) }
    var enableGridLines by remember { mutableStateOf(true) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("设置") },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
            ) {
                // 默认分辨率设置
                Text(
                    text = "默认分辨率",
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.padding(vertical = 8.dp)
                )
                val resolutions = listOf("4K (3840x2160)", "1080p (1920x1080)", "720p (1280x720)")
                resolutions.forEach { resolution ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { defaultResolution = resolution }
                            .padding(vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = resolution == defaultResolution,
                            onClick = { defaultResolution = resolution }
                        )
                        Text(
                            text = resolution,
                            modifier = Modifier.padding(start = 8.dp)
                        )
                    }
                }

                Divider(modifier = Modifier.padding(vertical = 8.dp))

                // 蓝牙设置
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("启用蓝牙自拍杆")
                    Switch(
                        checked = enableBluetooth,
                        onCheckedChange = { enableBluetooth = it }
                    )
                }

                // 自动对焦设置
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("启用自动对焦")
                    Switch(
                        checked = enableAutoFocus,
                        onCheckedChange = { enableAutoFocus = it }
                    )
                }

                // 网格线设置
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("显示网格线")
                    Switch(
                        checked = enableGridLines,
                        onCheckedChange = { enableGridLines = it }
                    )
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    // TODO: 保存设置
                    onDismiss()
                }
            ) {
                Text("确定")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("取消")
            }
        }
    )
} 