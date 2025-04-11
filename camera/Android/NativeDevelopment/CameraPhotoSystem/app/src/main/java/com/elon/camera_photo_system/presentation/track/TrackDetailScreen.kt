package com.elon.camera_photo_system.presentation.track

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.elon.camera_photo_system.domain.model.PhotoType
import com.elon.camera_photo_system.domain.model.Track
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.time.format.DateTimeFormatter
import java.time.Duration

/**
 * 轨迹详情界面 - 现代化沉浸式UI
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TrackDetailScreen(
    projectId: Long,
    vehicleId: Long,
    trackState: TrackState,
    onLoadTrack: (Long) -> Unit,
    onNavigateBack: () -> Unit,
    onStartTrack: (Long) -> Unit,
    onEndTrack: (Long) -> Unit,
    onNavigateToCamera: (Long) -> Unit,
    onNavigateToGallery: (Long) -> Unit,
    trackId: Long
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val scrollState = rememberScrollState()
    
    // 自动重试机制
    val maxRetryCount = 3
    var retryCount by remember { mutableStateOf(0) }
    var isTimeout by remember { mutableStateOf(false) }
    var showErrorSnackbar by remember { mutableStateOf(false) }
    
    // 加载超时处理
    LaunchedEffect(trackId, trackState.isLoading) {
        if (trackState.isLoading) {
            delay(10000) // 10秒超时
            if (trackState.isLoading) {
                isTimeout = true
            }
        } else {
            isTimeout = false
        }
    }
    
    // 自动加载轨迹数据
    LaunchedEffect(trackId) {
        onLoadTrack(trackId)
    }
    
    // 错误自动重试
    LaunchedEffect(trackState.error, isTimeout) {
        if ((trackState.error != null || isTimeout) && retryCount < maxRetryCount) {
            delay(1000) // 延迟1秒后重试
            retryCount++
            onLoadTrack(trackId)
        } else if (trackState.error != null && retryCount >= maxRetryCount) {
            showErrorSnackbar = true
        }
    }
    
    // 缓存UI常量
    val surfaceColor = MaterialTheme.colorScheme.surface
    val primaryColor = MaterialTheme.colorScheme.primary
    val onSurfaceColor = MaterialTheme.colorScheme.onSurface
    
    // 添加进入动画效果
    val contentAlpha by animateFloatAsState(
        targetValue = if (trackState.isLoading) 0f else 1f,
        animationSpec = tween(durationMillis = 300),
        label = "Content Alpha Animation"
    )
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { 
                    Text(
                        text = "轨迹详情",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.Default.ArrowBack,
                            contentDescription = "返回",
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = surfaceColor,
                    titleContentColor = onSurfaceColor
                )
            )
        },
        containerColor = MaterialTheme.colorScheme.background
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // 使用key强制稳定内容区域
            key(trackId) {
                // 根据状态显示不同内容
                val track = trackState.track
                val isLoading = trackState.isLoading
                val error = trackState.error
                
                if (isLoading && !isTimeout) {
                    LoadingState(modifier = Modifier.align(Alignment.Center))
                } else if (isTimeout) {
                    TimeoutState(
                        modifier = Modifier.align(Alignment.Center),
                        onRetry = {
                            retryCount = 0
                            isTimeout = false
                            onLoadTrack(trackId)
                        }
                    )
                } else if (track == null && !isLoading) {
                    EmptyTrackState(
                        modifier = Modifier.align(Alignment.Center),
                        onRetry = {
                            retryCount = 0
                            onLoadTrack(trackId)
                        }
                    )
                } else if (track != null) {
                    // 注意: 当track非空时我们就显示内容，不再受isLoading影响
                    // 这样可以避免在刷新数据时闪烁
                    TrackDetailContent(
                        track = track,
                        modifier = Modifier.fillMaxSize(),
                        onStartTrack = { onStartTrack(trackId) },
                        onEndTrack = { onEndTrack(trackId) },
                        onNavigateToCamera = { onNavigateToCamera(trackId) },
                        onNavigateToGallery = { onNavigateToGallery(trackId) },
                        scrollState = scrollState
                    )
                    
                    // 如果处于加载状态但已有轨迹数据，显示刷新指示器
                    if (isLoading) {
                        LinearProgressIndicator(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(4.dp)
                        )
                    }
                }
            }
            
            // 错误提示
            AnimatedVisibility(
                visible = showErrorSnackbar,
                enter = fadeIn() + slideInVertically { it },
                exit = fadeOut() + slideOutVertically { it }
            ) {
                ErrorSnackbar(
                    error = trackState.error ?: "加载失败，请重试",
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(16.dp),
                    onDismiss = { showErrorSnackbar = false },
                    onRetry = {
                        retryCount = 0
                        showErrorSnackbar = false
                        onLoadTrack(trackId)
                    }
                )
            }
        }
    }
}

/**
 * 加载状态
 */
@Composable
private fun LoadingState(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator(
            modifier = Modifier
                .size(48.dp)
                .shadow(4.dp, CircleShape),
            color = MaterialTheme.colorScheme.primary,
            strokeWidth = 4.dp
        )
    }
}

/**
 * 超时状态
 */
@Composable
private fun TimeoutState(
    modifier: Modifier = Modifier,
    onRetry: () -> Unit
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Outlined.Timer,
            contentDescription = null,
            modifier = Modifier.size(80.dp),
            tint = MaterialTheme.colorScheme.error
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = "加载超时",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onSurface
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = "服务器响应时间过长，请检查网络连接或稍后再试",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Button(
            onClick = onRetry,
            colors = ButtonDefaults.buttonColors(
                containerColor = MaterialTheme.colorScheme.primary
            )
        ) {
            Icon(
                imageVector = Icons.Default.Refresh,
                contentDescription = null
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text("重试")
        }
    }
}

/**
 * 空轨迹状态
 */
@Composable
private fun EmptyTrackState(
    modifier: Modifier = Modifier,
    onRetry: () -> Unit
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.padding(24.dp)
        ) {
            Icon(
                imageVector = Icons.Default.Error,
                contentDescription = null,
                modifier = Modifier.size(80.dp),
                tint = MaterialTheme.colorScheme.error
            )
            
            Spacer(modifier = Modifier.height(24.dp))
            
            Text(
                text = "轨迹不存在",
                style = MaterialTheme.typography.headlineMedium,
                color = MaterialTheme.colorScheme.onBackground,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = "无法找到您请求的轨迹信息",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Spacer(modifier = Modifier.height(32.dp))
            
            Button(
                onClick = onRetry,
                modifier = Modifier
                    .height(48.dp)
                    .fillMaxWidth(0.7f),
                shape = RoundedCornerShape(24.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.primary
                )
            ) {
                Icon(
                    imageVector = Icons.Default.ArrowBack,
                    contentDescription = null
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "返回轨迹列表",
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    }
}

/**
 * 轨迹详情内容
 */
@Composable
private fun TrackDetailContent(
    track: Track,
    modifier: Modifier = Modifier,
    onStartTrack: () -> Unit,
    onEndTrack: () -> Unit,
    onNavigateToCamera: (Long) -> Unit,
    onNavigateToGallery: (Long) -> Unit,
    scrollState: ScrollState
) {
    Box(
        modifier = modifier.fillMaxSize()
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(scrollState)
                .padding(16.dp)
                .animateContentSize(
                    animationSpec = spring(
                        dampingRatio = Spring.DampingRatioMediumBouncy,
                        stiffness = Spring.StiffnessMedium
                    )
                )
        ) {
            // 轨迹信息卡片
            TrackInfoCard(track = track)
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // 照片统计
            PhotoStatisticsSection(track = track)
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // 查看照片按钮
            FilledTonalButton(
                onClick = { onNavigateToGallery(track.id) },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                colors = ButtonDefaults.filledTonalButtonColors(
                    containerColor = MaterialTheme.colorScheme.secondaryContainer
                ),
                shape = RoundedCornerShape(16.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Collections,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSecondaryContainer
                )
                
                Spacer(modifier = Modifier.width(12.dp))
                
                Text(
                    text = "查看所有照片 (${track.totalPhotoCount})",
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSecondaryContainer
                )
            }
            
            // 底部留白，确保内容完全可见
            Spacer(modifier = Modifier.height(80.dp))
        }

        // 悬浮拍照按钮
        FloatingActionButton(
            onClick = { onNavigateToCamera(track.id) },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(16.dp)
                .size(64.dp),
            containerColor = MaterialTheme.colorScheme.primary,
            contentColor = MaterialTheme.colorScheme.onPrimary,
            shape = RoundedCornerShape(16.dp)
        ) {
            Icon(
                imageVector = Icons.Default.PhotoCamera,
                contentDescription = "拍照",
                modifier = Modifier.size(32.dp)
            )
        }
    }
}

/**
 * 错误提示
 */
@Composable
private fun ErrorSnackbar(
    error: String,
    modifier: Modifier = Modifier,
    onDismiss: () -> Unit,
    onRetry: () -> Unit
) {
    Card(
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.errorContainer
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = 4.dp
        ),
        modifier = modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Error,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onErrorContainer
            )
            
            Spacer(modifier = Modifier.width(12.dp))
            
            Text(
                text = error,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onErrorContainer,
                modifier = Modifier.weight(1f)
            )
        }
    }
}

/**
 * 照片统计区域
 */
@Composable
private fun PhotoStatisticsSection(track: Track) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = 2.dp
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.PhotoLibrary,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(28.dp)
                )
                
                Spacer(modifier = Modifier.width(12.dp))
                
                Text(
                    text = "照片统计",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            PhotoTypeRow("起始点照片", track.startPointPhotoCount)
            PhotoTypeRow("中间点照片", track.middlePointPhotoCount)
            PhotoTypeRow("过渡点照片", track.transitionPointPhotoCount)
            PhotoTypeRow("结束点照片", track.endPointPhotoCount)
            
            Divider(
                modifier = Modifier
                    .padding(vertical = 12.dp)
                    .fillMaxWidth(),
                color = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f),
                thickness = 1.dp
            )
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "总计",
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                
                // 照片总量标签
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(16.dp))
                        .background(MaterialTheme.colorScheme.primary)
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                ) {
                    Text(
                        text = "${track.totalPhotoCount}张",
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                }
            }
        }
    }
}

/**
 * 照片类型统计行
 */
@Composable
private fun PhotoTypeRow(
    label: String,
    count: Int
) {
    // 计算颜色并使用记忆化避免重组
    val hasPhotos = count > 0
    val backgroundColor = if (hasPhotos) 
        MaterialTheme.colorScheme.primaryContainer
    else 
        MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
    
    val textColor = if (hasPhotos) 
        MaterialTheme.colorScheme.onPrimaryContainer
    else 
        MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
    
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        // 照片数量标签
        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(12.dp))
                .background(backgroundColor)
                .padding(horizontal = 12.dp, vertical = 6.dp)
        ) {
            Text(
                text = "${count}张",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = if (hasPhotos) FontWeight.Medium else FontWeight.Normal,
                color = textColor
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
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = 2.dp
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // 轨迹名称和状态
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = track.name,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                
                // 状态标签
                StatusChip(track)
            }
            Spacer(modifier = Modifier.height(20.dp))

        }
    }
}

/**
 * 状态标签
 */
@Composable
private fun StatusChip(track: Track) {
    val (backgroundColor, textColor, statusText) = when {
        !track.isStarted -> Triple(
            MaterialTheme.colorScheme.errorContainer,
            MaterialTheme.colorScheme.onErrorContainer,
            ""
        )
        !track.isEnded -> Triple(
            MaterialTheme.colorScheme.primaryContainer,
            MaterialTheme.colorScheme.onPrimaryContainer,
            ""
        )
        else -> Triple(
            MaterialTheme.colorScheme.tertiaryContainer,
            MaterialTheme.colorScheme.onTertiaryContainer,
            ""
        )
    }
    
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(16.dp))
            .background(backgroundColor)
            .padding(horizontal = 12.dp, vertical = 6.dp)
    ) {
        Text(
            text = statusText,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium,
            color = textColor
        )
    }
}

/**
 * 轨迹信息项
 */
@Composable
private fun TrackInfoItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    value: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(24.dp)
        )
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.weight(1f)
        )
        
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
} 