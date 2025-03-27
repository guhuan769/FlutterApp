package com.elon.camera_photo_system.presentation.track

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.elon.camera_photo_system.domain.model.PhotoType
import com.elon.camera_photo_system.domain.model.Track
import java.time.format.DateTimeFormatter

/**
 * 轨迹详情界面
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TrackDetailScreen(
    projectId: Long,
    vehicleId: Long,
    track: Track?,
    isLoading: Boolean,
    error: String?,
    onNavigateBack: () -> Unit,
    onNavigateToCamera: (PhotoType) -> Unit,
    onNavigateToGallery: () -> Unit,
    onStartTrack: () -> Unit,
    onEndTrack: () -> Unit
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(track?.name ?: "轨迹详情") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "返回")
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
            if (isLoading) {
                // 加载状态
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            } else if (track == null) {
                // 轨迹不存在
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            imageVector = Icons.Default.Error,
                            contentDescription = null,
                            modifier = Modifier.size(48.dp),
                            tint = MaterialTheme.colorScheme.error
                        )
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        Text(
                            text = "轨迹不存在",
                            style = MaterialTheme.typography.titleLarge,
                            color = MaterialTheme.colorScheme.error
                        )
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        Button(
                            onClick = onNavigateBack
                        ) {
                            Text("返回轨迹列表")
                        }
                    }
                }
            } else {
                // 轨迹详情内容
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .padding(16.dp)
                ) {
                    // 轨迹信息卡片
                    TrackInfoCard(track = track)
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    // 轨迹状态控制
                    TrackStatusSection(
                        isStarted = track.isStarted,
                        isEnded = track.isEnded,
                        onStartTrack = onStartTrack,
                        onEndTrack = onEndTrack
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    // 照片统计
                    PhotoStatisticsSection(track = track)
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    // 功能按钮
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        // 照片类型选择器
                        PhotoTypeSelector(
                            isStarted = track.isStarted,
                            isEnded = track.isEnded,
                            onSelectPhotoType = onNavigateToCamera,
                            modifier = Modifier.weight(1f)
                        )
                        
                        Spacer(modifier = Modifier.width(16.dp))
                        
                        Button(
                            onClick = onNavigateToGallery,
                            modifier = Modifier.weight(1f)
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Collections,
                                    contentDescription = null
                                )
                                
                                Spacer(modifier = Modifier.width(8.dp))
                                
                                Text("照片(${track.totalPhotoCount})")
                            }
                        }
                    }
                }
            }
            
            // 错误提示
            AnimatedVisibility(
                visible = error != null,
                enter = fadeIn(),
                exit = fadeOut(),
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(16.dp)
            ) {
                error?.let {
                    Snackbar {
                        Text(it)
                    }
                }
            }
        }
    }
}

/**
 * 轨迹状态控制区域
 */
@Composable
private fun TrackStatusSection(
    isStarted: Boolean,
    isEnded: Boolean,
    onStartTrack: () -> Unit,
    onEndTrack: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "轨迹状态",
                style = MaterialTheme.typography.titleMedium
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            when {
                !isStarted -> Button(
                    onClick = onStartTrack,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.primary
                    )
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.PlayArrow, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("开始轨迹")
                    }
                }
                !isEnded -> Button(
                    onClick = onEndTrack,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Stop, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("结束轨迹")
                    }
                }
                else -> Text(
                    text = "轨迹已完成",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.outline
                )
            }
        }
    }
}

/**
 * 照片统计区域
 */
@Composable
private fun PhotoStatisticsSection(track: Track) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "照片统计",
                style = MaterialTheme.typography.titleMedium
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            PhotoTypeRow("起始点照片", track.startPointPhotoCount)
            PhotoTypeRow("中间点照片", track.middlePointPhotoCount)
            PhotoTypeRow("模型点照片", track.modelPointPhotoCount)
            PhotoTypeRow("结束点照片", track.endPointPhotoCount)
            
            Divider(modifier = Modifier.padding(vertical = 8.dp))
            
            PhotoTypeRow("总计", track.totalPhotoCount, true)
        }
    }
}

/**
 * 照片类型统计行
 */
@Composable
private fun PhotoTypeRow(
    label: String,
    count: Int,
    isTotal: Boolean = false
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = if (isTotal) MaterialTheme.typography.bodyLarge else MaterialTheme.typography.bodyMedium,
            fontWeight = if (isTotal) FontWeight.Bold else FontWeight.Normal
        )
        
        Text(
            text = "${count}张",
            style = if (isTotal) MaterialTheme.typography.bodyLarge else MaterialTheme.typography.bodyMedium,
            fontWeight = if (isTotal) FontWeight.Bold else FontWeight.Normal,
            color = if (count > 0) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline
        )
    }
}

/**
 * 照片类型选择器
 */
@Composable
private fun PhotoTypeSelector(
    isStarted: Boolean,
    isEnded: Boolean,
    onSelectPhotoType: (PhotoType) -> Unit,
    modifier: Modifier = Modifier
) {
    var expanded by remember { mutableStateOf(false) }
    
    Box(modifier = modifier) {
        Button(
            onClick = { expanded = true },
            enabled = !isEnded // 轨迹未结束时才能拍照
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(Icons.Default.PhotoCamera, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("拍照")
                Icon(Icons.Default.ArrowDropDown, contentDescription = null)
            }
        }
        
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            // 根据轨迹状态决定可用的照片类型
            if (!isStarted) {
                // 未开始轨迹，只能拍摄起始点
                DropdownMenuItem(
                    text = { Text("起始点拍照") },
                    onClick = {
                        onSelectPhotoType(PhotoType.START_POINT)
                        expanded = false
                    },
                    leadingIcon = {
                        Icon(Icons.Default.PlayArrow, contentDescription = null)
                    }
                )
            } else if (!isEnded) {
                // 已开始但未结束，可以拍摄中间点和结束点
                DropdownMenuItem(
                    text = { Text("中间点拍照") },
                    onClick = {
                        onSelectPhotoType(PhotoType.MIDDLE_POINT)
                        expanded = false
                    },
                    leadingIcon = {
                        Icon(Icons.Default.LocationOn, contentDescription = null)
                    }
                )
                
                DropdownMenuItem(
                    text = { Text("结束点拍照") },
                    onClick = {
                        onSelectPhotoType(PhotoType.END_POINT)
                        expanded = false
                    },
                    leadingIcon = {
                        Icon(Icons.Default.Stop, contentDescription = null)
                    }
                )
            }
            
            // 模型点随时可用
            DropdownMenuItem(
                text = { Text("模型点拍照") },
                onClick = {
                    onSelectPhotoType(PhotoType.MODEL_POINT)
                    expanded = false
                },
                leadingIcon = {
                    Icon(Icons.Default.ModelTraining, contentDescription = null)
                }
            )
        }
    }
}

/**
 * 轨迹信息卡片
 */
@Composable
private fun TrackInfoCard(track: Track) {
    val dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")
    
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                text = track.name,
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // 轨迹详细信息
            InfoRow(
                label = "轨迹长度",
                value = "${track.length} 公里"
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            InfoRow(
                label = "开始时间",
                value = track.startTime.format(dateFormatter)
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            InfoRow(
                label = "结束时间",
                value = track.endTime?.format(dateFormatter) ?: "尚未结束"
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            InfoRow(
                label = "状态",
                value = when {
                    !track.isStarted -> "未开始"
                    !track.isEnded -> "进行中"
                    else -> "已完成"
                }
            )
        }
    }
}

/**
 * 信息行
 */
@Composable
private fun InfoRow(
    label: String,
    value: String
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium
        )
    }
} 