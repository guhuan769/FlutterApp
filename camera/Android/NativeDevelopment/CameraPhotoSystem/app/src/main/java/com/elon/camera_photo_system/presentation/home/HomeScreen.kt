package com.elon.camera_photo_system.presentation.home

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.elon.camera_photo_system.domain.model.Project
import com.google.accompanist.swiperefresh.SwipeRefresh
import com.google.accompanist.swiperefresh.rememberSwipeRefreshState
import java.time.format.DateTimeFormatter
import androidx.compose.foundation.background
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.navigation.NavController
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.elon.camera_photo_system.presentation.home.state.UploadState
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.expandVertically
import androidx.compose.animation.shrinkVertically
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.text.style.TextAlign
import com.elon.camera_photo_system.domain.model.upload.ModelType
import com.elon.camera_photo_system.domain.model.upload.ProcessType
import com.elon.camera_photo_system.domain.model.upload.UploadPhotoType
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.VisualTransformation

import androidx.compose.foundation.interaction.MutableInteractionSource


/**
 * 项目模块主界面 - 项目列表
 * 实现功能：
 * 1. 项目列表展示
 * 2. 模型点拍照入口
 * 3. 项目相册入口
 * 4. 添加车辆入口
 * 5. 项目上传功能
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    state: HomeScreenState,
    uploadState: UploadState,
    onProjectClick: (Project) -> Unit,
    onRefresh: () -> Unit,
    onAddProject: () -> Unit,
    onTakeModelPhoto: (Project) -> Unit,
    onOpenGallery: (Project) -> Unit,
    onAddVehicle: (Project) -> Unit,
    onUploadProject: (Project) -> Unit,
    onDeleteProject: (Project) -> Unit,
    onNavigateToSettings: () -> Unit,
    modelTypes: List<ModelType> = listOf(ModelType.DEFAULT), // 模型类型列表
    processTypes: List<ProcessType> = listOf(ProcessType.DEFAULT), // 工艺类型列表
    onSelectUploadType: (UploadPhotoType, String) -> Unit = { _, _ -> }, // 选择上传类型和ID的回调
    onManageModelTypes: () -> Unit = {}, // 管理模型类型按钮点击事件
    onManageProcessTypes: () -> Unit = {} // 管理工艺类型按钮点击事件
) {
    val swipeRefreshState = rememberSwipeRefreshState(state.isLoading)
    var showDeleteDialog by remember { mutableStateOf<Project?>(null) }
    var showUploadDialog by remember { mutableStateOf(false) }
    var selectedProject by remember { mutableStateOf<Project?>(null) }
    
    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("项目列表") },
                actions = {
                    IconButton(onClick = onAddProject) {
                        Icon(
                            imageVector = Icons.Default.Add,
                            contentDescription = "新建项目"
                        )
                    }
                    IconButton(onClick = onNavigateToSettings) {
                        Icon(
                            imageVector = Icons.Default.Settings,
                            contentDescription = "设置"
                        )
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            SwipeRefresh(
                state = swipeRefreshState,
                onRefresh = onRefresh
            ) {
                if (state.projects.isEmpty() && !state.isLoading) {
                    EmptyProjectsView(onAddProject)
                } else {
                    ProjectList(
                        projects = state.projects,
                        uploadState = uploadState,
                        onProjectClick = onProjectClick,
                        onTakeModelPhoto = onTakeModelPhoto,
                        onOpenGallery = onOpenGallery,
                        onAddVehicle = onAddVehicle,
                        onUploadProject = { project ->
                            selectedProject = project
                            showUploadDialog = true
                            onUploadProject(project)
                        },
                        onDeleteProject = { project -> showDeleteDialog = project }
                    )
                }
            }
            
            if (state.isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.align(Alignment.Center)
                )
            }
            
            state.error?.let { errorMessage ->
                Snackbar(
                    modifier = Modifier
                        .padding(16.dp)
                        .align(Alignment.BottomCenter),
                    action = {
                        TextButton(onClick = onRefresh) {
                            Text("重试")
                        }
                    }
                ) {
                    Text(errorMessage)
                }
            }
            
            // 显示上传错误信息
            uploadState.error?.let { errorMessage ->
                Snackbar(
                    modifier = Modifier
                        .padding(16.dp)
                        .align(Alignment.BottomCenter),
                    action = {
                        TextButton(onClick = onRefresh) {
                            Text("关闭")
                        }
                    }
                ) {
                    Text(errorMessage)
                }
            }
        }
    }
    
    // 删除确认对话框
    showDeleteDialog?.let { project ->
        AlertDialog(
            onDismissRequest = { showDeleteDialog = null },
            icon = {
                Icon(
                    imageVector = Icons.Default.DeleteForever,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.error
                )
            },
            title = {
                Text(
                    text = "确认删除项目",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )
            },
            text = {
                Column {
                    Text(
                        text = "您确定要删除项目\"${project.name}\"吗？",
                        style = MaterialTheme.typography.bodyLarge
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "此操作将同时删除：",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    BulletText("所有关联的车辆信息")
                    BulletText("所有关联的轨迹数据")
                    BulletText("所有关联的照片数据")
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "此操作不可撤销！",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.error,
                        fontWeight = FontWeight.Bold
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        onDeleteProject(project)
                        showDeleteDialog = null
                    },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("确认删除")
                }
            },
            dismissButton = {
                OutlinedButton(onClick = { showDeleteDialog = null }) {
                    Text("取消")
                }
            }
        )
    }
    
    // 显示批量上传对话框
    if (showUploadDialog && selectedProject != null) {
        BatchProjectUploadDialog(
            isVisible = true,
            project = selectedProject,
            uploadState = uploadState,
            onDismissRequest = { showUploadDialog = false },
            modelTypes = modelTypes,
            processTypes = processTypes,
            onSelectUploadType = onSelectUploadType,
            onManageModelTypes = onManageModelTypes,
            onManageProcessTypes = onManageProcessTypes
        )
    }
}

@Composable
private fun BulletText(text: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.padding(vertical = 2.dp)
    ) {
        Box(
            modifier = Modifier
                .size(4.dp)
                .background(
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    shape = CircleShape
                )
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = text,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

/**
 * 项目列表界面状态
 */
data class HomeScreenState(
    val projects: List<Project> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)

/**
 * 空项目提示视图
 */
@Composable
private fun EmptyProjectsView(onAddProject: () -> Unit) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.padding(16.dp)
        ) {
            Icon(
                imageVector = Icons.Default.FolderOff,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Text(
                text = "暂无项目",
                style = MaterialTheme.typography.headlineSmall,
                color = MaterialTheme.colorScheme.onSurface
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Button(
                onClick = onAddProject,
                modifier = Modifier.padding(top = 8.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = null
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("创建新项目")
                }
            }
        }
    }
}

/**
 * 项目列表视图
 */
@Composable
private fun ProjectList(
    projects: List<Project>,
    uploadState: UploadState,
    onProjectClick: (Project) -> Unit,
    onTakeModelPhoto: (Project) -> Unit,
    onOpenGallery: (Project) -> Unit,
    onAddVehicle: (Project) -> Unit,
    onUploadProject: (Project) -> Unit,
    onDeleteProject: (Project) -> Unit
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        items(projects) { project ->
            // 确定当前项目是否正在上传或上传成功
            val isCurrentProjectUploading = uploadState.isUploading && uploadState.currentProject?.id == project.id
            val isCurrentProjectUploadSuccess = uploadState.isSuccess && uploadState.currentProject?.id == project.id
            
            ProjectItem(
                project = project,
                onProjectClick = { onProjectClick(project) },
                onTakeModelPhoto = { onTakeModelPhoto(project) },
                onOpenGallery = { onOpenGallery(project) },
                onAddVehicle = { onAddVehicle(project) },
                onUploadProject = { onUploadProject(project) },
                onDeleteProject = { onDeleteProject(project) },
                isUploading = isCurrentProjectUploading,
                uploadSuccess = isCurrentProjectUploadSuccess
            )
        }
    }
}

/**
 * 项目列表项
 */
@Composable
private fun ProjectItem(
    project: Project,
    onProjectClick: () -> Unit,
    onTakeModelPhoto: () -> Unit,
    onOpenGallery: () -> Unit,
    onAddVehicle: () -> Unit,
    onUploadProject: () -> Unit,
    onDeleteProject: () -> Unit,
    isUploading: Boolean = false,
    uploadSuccess: Boolean = false
) {
    val dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")
    
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onProjectClick),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                // 项目图标
                Icon(
                    imageVector = Icons.Default.Folder,
                    contentDescription = null,
                    modifier = Modifier.size(40.dp),
                    tint = MaterialTheme.colorScheme.primary
                )
                
                Spacer(modifier = Modifier.width(16.dp))
                
                // 项目信息
                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        text = project.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    
                    if (project.description.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = project.description,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }
                
                // 添加删除按钮
                IconButton(
                    onClick = onDeleteProject,
                    colors = IconButtonDefaults.iconButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = "删除项目"
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // 项目统计信息
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                ProjectInfoChip(
                    icon = Icons.Default.DirectionsCar,
                    label = "车辆: ${project.vehicleCount}"
                )
                
                ProjectInfoChip(
                    icon = Icons.Default.PhotoLibrary,
                    label = "照片: ${project.photoCount}"
                )
                
                ProjectInfoChip(
                    icon = Icons.Default.DateRange,
                    label = project.createdAt.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"))
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // 添加上传状态显示
            if (isUploading) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(16.dp),
                        strokeWidth = 2.dp
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "正在上传...",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            } else if (uploadSuccess) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.CheckCircle,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "上传成功",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
            
            // 项目操作按钮
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                ProjectActionButton(
                    icon = Icons.Default.PhotoCamera,
                    label = "相机",
                    onClick = onTakeModelPhoto
                )
                
                ProjectActionButton(
                    icon = Icons.Default.PhotoLibrary,
                    label = "相册",
                    onClick = onOpenGallery
                )
                
                ProjectActionButton(
                    icon = Icons.Default.DirectionsCar,
                    label = "添加车辆",
                    onClick = onAddVehicle
                )
                
                ProjectActionButton(
                    icon = Icons.Default.Upload,
                    label = "上传",
                    onClick = onUploadProject,
                    enabled = !isUploading // 上传中禁用按钮
                )
            }
        }
    }
}

/**
 * 项目信息标签
 */
@Composable
private fun ProjectInfoChip(
    icon: ImageVector,
    label: String
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.padding(end = 8.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(16.dp),
            tint = MaterialTheme.colorScheme.primary
        )
        Spacer(modifier = Modifier.width(4.dp))
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

/**
 * 项目操作按钮
 */
@Composable
private fun ProjectActionButton(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit,
    enabled: Boolean = true
) {
    IconButton(
        onClick = onClick,
        modifier = Modifier.size(48.dp),
        enabled = enabled
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = if (enabled) MaterialTheme.colorScheme.primary 
                       else MaterialTheme.colorScheme.primary.copy(alpha = 0.5f)
            )
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
                color = if (enabled) MaterialTheme.colorScheme.onSurfaceVariant 
                        else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

/**
 * 项目批量上传对话框
 * 用于显示项目照片上传的进度和状态，并支持选择上传照片的用途类型
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BatchProjectUploadDialog(
    isVisible: Boolean,
    project: Project?,
    uploadState: UploadState,
    onDismissRequest: () -> Unit,
    modelTypes: List<ModelType> = listOf(ModelType.DEFAULT), // 可选的模型类型列表
    processTypes: List<ProcessType> = listOf(ProcessType.DEFAULT), // 可选的工艺类型列表
    onSelectUploadType: (UploadPhotoType, String) -> Unit = { _, _ -> }, // 选择上传类型和ID
    onManageModelTypes: () -> Unit = {}, // 管理模型类型按钮点击事件
    onManageProcessTypes: () -> Unit = {} // 管理工艺类型按钮点击事件
) {
    if (!isVisible || project == null) return
    
    var selectedUploadType by remember { mutableStateOf<UploadPhotoType?>(null) }
    var selectedTypeId by remember { mutableStateOf<String?>(null) }
    var showTypeDialog by remember { mutableStateOf(false) }
    
    // 确定当前选择的类型列表
    val currentTypeList = when (selectedUploadType) {
        UploadPhotoType.MODEL -> modelTypes
        UploadPhotoType.PROCESS -> processTypes
        else -> emptyList()
    }
    
    // 上传按钮是否可用（必须选择一个类型才能上传）
    val isUploadEnabled = selectedUploadType != null && selectedTypeId != null
    
    // 类型选择是否可用（上传中禁止修改）
    val isTypeSelectionEnabled = !uploadState.isUploading && !uploadState.isSuccess
    
    // 对话框尺寸
    val dialogWidth = 360.dp
    val dialogHeight = 480.dp
    
    Dialog(
        onDismissRequest = {
            if (!uploadState.isUploading) {
                onDismissRequest()
            }
        },
        properties = DialogProperties(
            dismissOnBackPress = !uploadState.isUploading,
            dismissOnClickOutside = !uploadState.isUploading
        )
    ) {
        Card(
            modifier = Modifier
                .width(dialogWidth)
                .heightIn(max = dialogHeight)
                .animateContentSize(),
            shape = RoundedCornerShape(28.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surface
            ),
            elevation = CardDefaults.cardElevation(defaultElevation = 6.dp)
        ) {
            Column(
                modifier = Modifier
                    .padding(24.dp)
                    .fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // 标题和图标
                Icon(
                    imageVector = when {
                        uploadState.isSuccess -> Icons.Default.CheckCircle
                        uploadState.error != null -> Icons.Default.Error
                        uploadState.isUploading -> Icons.Default.CloudUpload
                        else -> Icons.Default.CloudUpload
                    },
                    contentDescription = null,
                    tint = when {
                        uploadState.isSuccess -> Color.Green
                        uploadState.error != null -> MaterialTheme.colorScheme.error
                        else -> MaterialTheme.colorScheme.primary
                    },
                    modifier = Modifier.size(48.dp)
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                Text(
                    text = "上传项目照片",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Text(
                    text = "项目: ${project.name}",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center
                )
                
                Spacer(modifier = Modifier.height(24.dp))
                
                // 仅在上传前显示选择部分
                if (!uploadState.isUploading && !uploadState.isSuccess && uploadState.error == null) {
                    // 上传类型选择
                    Text(
                        text = "请选择照片用途",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurface,
                        modifier = Modifier.align(Alignment.Start)
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    // 上传类型单选组
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        // 模型按钮
                        FilterChip(
                            selected = selectedUploadType == UploadPhotoType.MODEL,
                            onClick = { 
                                selectedUploadType = UploadPhotoType.MODEL
                                selectedTypeId = null
                            },
                            label = { Text("模型") },
                            leadingIcon = {
                                Icon(
                                    imageVector = Icons.Default.Category, // 假定使用Category图标表示模型
                                    contentDescription = null
                                )
                            }
                        )
                        
                        // 工艺按钮
                        FilterChip(
                            selected = selectedUploadType == UploadPhotoType.PROCESS,
                            onClick = { 
                                selectedUploadType = UploadPhotoType.PROCESS
                                selectedTypeId = null
                            },
                            label = { Text("工艺") },
                            leadingIcon = {
                                Icon(
                                    imageVector = Icons.Default.Settings, // 假定使用Settings图标表示工艺
                                    contentDescription = null
                                )
                            }
                        )
                    }
                    
                    // 只有选择了上传类型才显示类型选择
                    AnimatedVisibility(
                        visible = selectedUploadType != null,
                        enter = fadeIn() + expandVertically(),
                        exit = fadeOut() + shrinkVertically()
                    ) {
                        Column(
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Spacer(modifier = Modifier.height(16.dp))
                            
                            Text(
                                text = "请选择具体类型",
                                style = MaterialTheme.typography.bodyLarge,
                                color = MaterialTheme.colorScheme.onSurface,
                                modifier = Modifier.align(Alignment.Start)
                            )
                            
                            Spacer(modifier = Modifier.height(8.dp))
                            
                            // 类型选择下拉菜单
                            ExposedDropdownMenuBox(
                                expanded = showTypeDialog,
                                onExpandedChange = { showTypeDialog = !showTypeDialog }
                            ) {
                                TextField(
                                    value = if (selectedTypeId != null) {
                                        currentTypeList.firstOrNull { 
                                            when (it) {
                                                is ModelType -> it.id == selectedTypeId
                                                is ProcessType -> it.id == selectedTypeId
                                                else -> false
                                            }
                                        }?.let { 
                                            when (it) {
                                                is ModelType -> it.name
                                                is ProcessType -> it.name
                                                else -> "请选择"
                                            }
                                        } ?: "请选择"
                                    } else "请选择",
                                    onValueChange = {},
                                    readOnly = true,
                                    trailingIcon = {
                                        Icon(
                                            imageVector = Icons.Default.ArrowDropDown,
                                            contentDescription = "下拉菜单",
                                            modifier = Modifier.rotate(if (showTypeDialog) 180f else 0f)
                                        )
                                    },
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .menuAnchor(),
                                    colors = TextFieldDefaults.colors()
                                )
                                
                                ExposedDropdownMenu(
                                    expanded = showTypeDialog,
                                    onDismissRequest = { showTypeDialog = false }
                                ) {
                                    currentTypeList.forEach { type ->
                                        DropdownMenuItem(
                                            text = { 
                                                Text(
                                                    text = when (type) {
                                                        is ModelType -> type.name
                                                        is ProcessType -> type.name
                                                        else -> ""
                                                    }
                                                ) 
                                            },
                                            onClick = {
                                                selectedTypeId = when (type) {
                                                    is ModelType -> type.id
                                                    is ProcessType -> type.id
                                                    else -> null
                                                }
                                                showTypeDialog = false
                                            }
                                        )
                                    }
                                    
                                    // 管理类型选项
                                    Divider()
                                    DropdownMenuItem(
                                        text = { 
                                            Text(
                                                text = "管理类型...",
                                                style = MaterialTheme.typography.bodyMedium.copy(
                                                    fontWeight = FontWeight.Medium
                                                )
                                            ) 
                                        },
                                        onClick = {
                                            showTypeDialog = false
                                            if (selectedUploadType == UploadPhotoType.MODEL) {
                                                onManageModelTypes()
                                            } else {
                                                onManageProcessTypes()
                                            }
                                        },
                                        leadingIcon = {
                                            Icon(
                                                imageVector = Icons.Default.Settings,
                                                contentDescription = null
                                            )
                                        }
                                    )
                                }
                            }
                            
                            Spacer(modifier = Modifier.height(24.dp))
                        }
                    }
                    
                    // 上传按钮
                    Button(
                        onClick = {
                            // 确保已选择类型
                            if (selectedUploadType != null && selectedTypeId != null) {
                                onSelectUploadType(selectedUploadType!!, selectedTypeId!!)
                            }
                        },
                        modifier = Modifier.fillMaxWidth(),
                        enabled = isUploadEnabled
                    ) {
                        Icon(
                            imageVector = Icons.Default.CloudUpload,
                            contentDescription = null
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("开始上传")
                    }
                } else {
                    // 上传进度和状态
                    val progress = uploadState.progress
                    val progressAnimated by animateFloatAsState(
                        targetValue = progress,
                        animationSpec = tween(
                            durationMillis = 300,
                            easing = FastOutSlowInEasing
                        ),
                        label = "Progress Animation"
                    )
                    
                    // 总照片数和已上传数量
                    val totalCount = uploadState.totalCount
                    val uploadedCount = uploadState.uploadedCount
                    
                    // 上传状态文本
                    Text(
                        text = when {
                            uploadState.isSuccess -> "上传完成"
                            uploadState.error != null -> "上传失败"
                            uploadState.isUploading -> "正在上传..."
                            else -> "准备上传"
                        },
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Medium,
                        color = when {
                            uploadState.isSuccess -> Color.Green
                            uploadState.error != null -> MaterialTheme.colorScheme.error
                            else -> MaterialTheme.colorScheme.onSurface
                        }
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    // 上传进度条
                    LinearProgressIndicator(
                        progress = { progressAnimated },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(8.dp)
                            .clip(RoundedCornerShape(4.dp)),
                        color = when {
                            uploadState.isSuccess -> Color.Green
                            uploadState.error != null -> MaterialTheme.colorScheme.error
                            else -> MaterialTheme.colorScheme.primary
                        },
                        trackColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    // 上传数量
                    if (totalCount > 0) {
                        Text(
                            text = "$uploadedCount / $totalCount",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    
                    // 模块级别的上传统计
                    if (uploadState.projectPhotosCount > 0 || 
                        uploadState.vehiclePhotosCount > 0 || 
                        uploadState.trackPhotosCount > 0) {
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        Text(
                            text = "上传详情",
                            style = MaterialTheme.typography.titleSmall,
                            color = MaterialTheme.colorScheme.onSurface,
                            modifier = Modifier.align(Alignment.Start)
                        )
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        if (uploadState.projectPhotosCount > 0) {
                            ModuleProgressItem(
                                title = "项目照片",
                                progress = uploadState.projectUploadedCount.toFloat() / uploadState.projectPhotosCount,
                                uploadedCount = uploadState.projectUploadedCount,
                                totalCount = uploadState.projectPhotosCount,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                        
                        if (uploadState.vehiclePhotosCount > 0) {
                            ModuleProgressItem(
                                title = "车辆照片",
                                progress = uploadState.vehicleUploadedCount.toFloat() / uploadState.vehiclePhotosCount,
                                uploadedCount = uploadState.vehicleUploadedCount,
                                totalCount = uploadState.vehiclePhotosCount,
                                color = MaterialTheme.colorScheme.secondary
                            )
                        }
                        
                        if (uploadState.trackPhotosCount > 0) {
                            ModuleProgressItem(
                                title = "轨迹照片",
                                progress = uploadState.trackUploadedCount.toFloat() / uploadState.trackPhotosCount,
                                uploadedCount = uploadState.trackUploadedCount,
                                totalCount = uploadState.trackPhotosCount,
                                color = MaterialTheme.colorScheme.tertiary
                            )
                        }
                    }
                    
                    // 显示上传类型信息
                    if (uploadState.selectedUploadPhotoType.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        val typeText = when (uploadState.selectedUploadPhotoType) {
                            "MODEL" -> "模型: ${uploadState.selectedUploadTypeName}"
                            "PROCESS" -> "工艺: ${uploadState.selectedUploadTypeName}"
                            else -> "类型: ${uploadState.selectedUploadTypeName}"
                        }
                        
                        Text(
                            text = typeText,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                    
                    // 错误信息
                    uploadState.error?.let { error ->
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        Text(
                            text = error,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.error,
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(8.dp)
                                .background(
                                    color = MaterialTheme.colorScheme.errorContainer,
                                    shape = RoundedCornerShape(8.dp)
                                )
                                .padding(8.dp)
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(24.dp))
                
                // 底部按钮
                TextButton(
                    onClick = onDismissRequest,
                    enabled = !uploadState.isUploading
                ) {
                    Text(
                        text = if (uploadState.isSuccess || uploadState.error != null) "关闭" else "取消"
                    )
                }
            }
        }
    }
}

/**
 * 模块上传进度项
 */
@Composable
private fun ModuleProgressItem(
    title: String,
    progress: Float,
    uploadedCount: Int,
    totalCount: Int,
    color: Color
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium
            )
            Text(
                text = "${(progress * 100).toInt()}%",
                style = MaterialTheme.typography.bodySmall
            )
        }
        
        LinearProgressIndicator(
            progress = { progress },
            modifier = Modifier.fillMaxWidth(),
            color = color
        )
        
        Text(
            text = "$uploadedCount / $totalCount",
            style = MaterialTheme.typography.bodySmall,
            modifier = Modifier.align(Alignment.End)
        )
    }
} 