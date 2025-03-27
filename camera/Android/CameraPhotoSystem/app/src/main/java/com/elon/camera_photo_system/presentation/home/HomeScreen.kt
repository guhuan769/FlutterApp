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
    onAddProject: () -> Unit,
    onProjectClick: (Project) -> Unit,
    onTakeModelPhoto: (Project) -> Unit,
    onOpenGallery: (Project) -> Unit,
    onAddVehicle: (Project) -> Unit,
    onUploadProject: (Project) -> Unit,
    onRefresh: () -> Unit
) {
    val swipeRefreshState = rememberSwipeRefreshState(state.isLoading)
    
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
                        onProjectClick = onProjectClick,
                        onTakeModelPhoto = onTakeModelPhoto,
                        onOpenGallery = onOpenGallery,
                        onAddVehicle = onAddVehicle,
                        onUploadProject = onUploadProject
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
        }
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
    onProjectClick: (Project) -> Unit,
    onTakeModelPhoto: (Project) -> Unit,
    onOpenGallery: (Project) -> Unit,
    onAddVehicle: (Project) -> Unit,
    onUploadProject: (Project) -> Unit
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        items(projects) { project ->
            ProjectItem(
                project = project,
                onProjectClick = { onProjectClick(project) },
                onTakeModelPhoto = { onTakeModelPhoto(project) },
                onOpenGallery = { onOpenGallery(project) },
                onAddVehicle = { onAddVehicle(project) },
                onUploadProject = { onUploadProject(project) }
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
    onUploadProject: () -> Unit
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
                verticalAlignment = Alignment.CenterVertically
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
                    label = project.creationDate.format(dateFormatter)
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
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
                    onClick = onUploadProject
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
    onClick: () -> Unit
) {
    IconButton(
        onClick = onClick,
        modifier = Modifier.size(48.dp)
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = MaterialTheme.colorScheme.primary
            )
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
} 