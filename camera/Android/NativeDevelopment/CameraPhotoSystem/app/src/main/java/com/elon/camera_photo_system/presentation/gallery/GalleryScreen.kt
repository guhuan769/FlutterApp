package com.elon.camera_photo_system.presentation.gallery

import android.graphics.BitmapFactory
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.clickable
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.*
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import coil.compose.AsyncImage
import coil.request.ImageRequest
import com.elon.camera_photo_system.R
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.model.PhotoType
import com.google.accompanist.swiperefresh.SwipeRefresh
import com.google.accompanist.swiperefresh.rememberSwipeRefreshState
import kotlinx.coroutines.launch
import java.io.File

/**
 * 相册屏幕
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GalleryScreen(
    photos: List<Photo>,
    moduleType: ModuleType,
    onNavigateBack: () -> Unit,
    onPhotoClick: (Photo) -> Unit,
    onDeletePhoto: (Photo) -> Unit,
    isLoading: Boolean,
    error: String?,
    onRefresh: () -> Unit
) {
    val swipeRefreshState = rememberSwipeRefreshState(isLoading)
    var selectedPhoto by remember { mutableStateOf<Photo?>(null) }
    
    // 按照类型分组照片
    val photosByType = remember(photos) {
        photos.groupBy { it.photoType }
    }
    
    // 选项卡状态
    var selectedTab by remember { mutableStateOf(0) }
    val tabs = remember(photosByType) {
        photosByType.keys.toList().sortedBy { 
            when (it) {
                PhotoType.START_POINT -> 0
                PhotoType.MIDDLE_POINT -> 1
                PhotoType.MODEL_POINT -> 2
                PhotoType.END_POINT -> 3
                else -> 4 // 添加else分支以防枚举扩展
            }
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { 
                    Text(
                        when (moduleType) {
                            ModuleType.PROJECT -> "项目相册"
                            ModuleType.VEHICLE -> "车辆相册"
                            ModuleType.TRACK -> "轨迹相册"
                        }
                    ) 
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                    }
                }
            )
        }
    ) { paddingValues ->
        SwipeRefresh(
            state = swipeRefreshState,
            onRefresh = onRefresh,
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            if (photos.isEmpty() && !isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text("暂无照片")
                }
            } else {
                Column(modifier = Modifier.fillMaxSize()) {
                    // 如果是轨迹模块且存在多种类型的照片，显示选项卡
                    if (moduleType == ModuleType.TRACK && photosByType.size > 1) {
                        ScrollableTabRow(
                            selectedTabIndex = selectedTab,
                            contentColor = MaterialTheme.colorScheme.primary,
                            containerColor = MaterialTheme.colorScheme.surfaceVariant,
                            edgePadding = 0.dp
                        ) {
                            tabs.forEachIndexed { index, photoType ->
                                val count = photosByType[photoType]?.size ?: 0
                                Tab(
                                    selected = selectedTab == index,
                                    onClick = { selectedTab = index },
                                    text = {
                                        Text(
                                            text = "${photoType.label}($count)",
                                            style = MaterialTheme.typography.bodyMedium
                                        )
                                    },
                                    selectedContentColor = MaterialTheme.colorScheme.primary,
                                    unselectedContentColor = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                    
                    // 根据选择的选项卡或者照片类型显示对应的照片
                    val displayPhotos = if (moduleType == ModuleType.TRACK && photosByType.size > 1 && tabs.isNotEmpty()) {
                        photosByType[tabs[selectedTab]] ?: emptyList()
                    } else {
                        photos
                    }
                    
                    // 照片网格
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(2),
                        contentPadding = PaddingValues(8.dp),
                        modifier = Modifier.fillMaxSize()
                    ) {
                        items(displayPhotos) { photo ->
                            PhotoCard(
                                photo = photo,
                                onClick = { 
                                    selectedPhoto = photo
                                    onPhotoClick(photo)
                                },
                                onDelete = { onDeletePhoto(photo) }
                            )
                        }
                    }
                }
            }
            
            if (error != null) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = error,
                        color = MaterialTheme.colorScheme.error
                    )
                }
            }
        }
    }
    
    // 显示照片详情对话框
    if (selectedPhoto != null) {
        PhotoDetailDialog(
            photo = selectedPhoto!!,
            onDismiss = { selectedPhoto = null },
            onDelete = { 
                onDeletePhoto(selectedPhoto!!)
                selectedPhoto = null
            }
        )
    }
}

@Composable
fun PhotoCard(
    photo: Photo,
    onClick: () -> Unit,
    onDelete: () -> Unit
) {
    // 从文件名中提取序号
    val photoNumber = remember(photo.fileName) {
        extractPhotoNumber(photo.fileName)
    }
    
    Box(
        modifier = Modifier
            .padding(4.dp)
            .aspectRatio(1f)
    ) {
        Card(
            modifier = Modifier
                .fillMaxSize(),
            elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
        ) {
            Box(
                modifier = Modifier.fillMaxSize()
            ) {
                // 图片
                AsyncImage(
                    model = ImageRequest.Builder(LocalContext.current)
                        .data(photo.filePath)
                        .crossfade(true)
                        .build(),
                    contentDescription = "照片",
                    contentScale = ContentScale.Crop,
                    modifier = Modifier
                        .fillMaxSize()
                        .clickable { onClick() }
                )
                
                // 删除按钮
                IconButton(
                    onClick = onDelete,
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .size(32.dp)
                        .padding(4.dp)
                        .background(
                            color = MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.7f),
                            shape = CircleShape
                        )
                ) {
                    Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = "删除",
                        tint = MaterialTheme.colorScheme.onErrorContainer,
                        modifier = Modifier.size(16.dp)
                    )
                }
                
                // 显示照片类型和序号
                Surface(
                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.8f),
                    shape = RoundedCornerShape(topEnd = 8.dp, bottomEnd = 8.dp),
                    modifier = Modifier
                        .align(Alignment.BottomStart)
                        .padding(bottom = 8.dp)
                ) {
                    Text(
                        text = "${photo.photoType.label}-$photoNumber",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onPrimary,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun PhotoDetailDialog(
    photo: Photo,
    onDismiss: () -> Unit,
    onDelete: () -> Unit
) {
    val context = LocalContext.current
    
    // 获取照片文件名的简化版用于显示
    val displayName = remember(photo.fileName) {
        photo.fileName.substringBeforeLast(".")
    }
    
    // 计算图片分辨率
    val resolution = remember {
        try {
            val options = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            BitmapFactory.decodeFile(photo.filePath, options)
            "${options.outWidth} × ${options.outHeight}"
        } catch (e: Exception) {
            "未知分辨率"
        }
    }
    
    // 图片文件大小
    val fileSize = remember {
        try {
            val file = File(photo.filePath)
            val size = file.length()
            when {
                size < 1024 -> "$size B"
                size < 1024 * 1024 -> "${size / 1024} KB"
                else -> "${size / (1024 * 1024)} MB"
            }
        } catch (e: Exception) {
            "未知大小"
        }
    }
    
    // 状态变量，用于控制缩放和平移
    var scale by remember { mutableStateOf(1f) }
    var offset by remember { mutableStateOf(Offset.Zero) }
    var showDetails by remember { mutableStateOf(false) }
    
    // 处理缩放和平移的协程作用域
    val coroutineScope = rememberCoroutineScope()
    
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            dismissOnBackPress = true,
            dismissOnClickOutside = true,
            usePlatformDefaultWidth = false
        )
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black.copy(alpha = 0.9f))
        ) {
            // 图片展示区域
            AsyncImage(
                model = ImageRequest.Builder(context)
                    .data(photo.filePath)
                    .crossfade(true)
                    .build(),
                contentDescription = "照片详情",
                contentScale = ContentScale.Fit,
                modifier = Modifier
                    .fillMaxSize()
                    .graphicsLayer(
                        scaleX = scale,
                        scaleY = scale,
                        translationX = offset.x,
                        translationY = offset.y
                    )
                    .pointerInput(Unit) {
                        detectTransformGestures { _, pan, zoom, _ ->
                            // 更新缩放
                            scale = (scale * zoom).coerceIn(1f, 3f)
                            
                            // 根据缩放比例调整平移范围
                            val maxX = (size.width * (scale - 1)) / 2
                            val maxY = (size.height * (scale - 1)) / 2
                            
                            // 更新平移
                            if (scale > 1f) {
                                offset = Offset(
                                    x = (offset.x + pan.x).coerceIn(-maxX, maxX),
                                    y = (offset.y + pan.y).coerceIn(-maxY, maxY)
                                )
                            } else {
                                offset = Offset.Zero
                            }
                        }
                    }
                    .combinedClickable(
                        onClick = { showDetails = !showDetails },
                        onDoubleClick = {
                            coroutineScope.launch {
                                if (scale > 1f) {
                                    // 双击恢复正常大小
                                    scale = 1f
                                    offset = Offset.Zero
                                } else {
                                    // 双击放大
                                    scale = 2f
                                }
                            }
                        }
                    )
            )
            
            // 顶部信息栏
            AnimatedVisibility(
                visible = showDetails,
                enter = fadeIn() + slideInVertically { fullHeight -> -fullHeight },
                exit = fadeOut() + slideOutVertically { fullHeight -> -fullHeight },
                modifier = Modifier.align(Alignment.TopCenter)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.8f))
                        .padding(16.dp)
                ) {
                    Text(
                        text = displayName,
                        style = MaterialTheme.typography.titleSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    Text(
                        text = "分辨率: $resolution",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    
                    Text(
                        text = "大小: $fileSize",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    
                    Text(
                        text = "照片类型: ${photo.photoType.label}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.End
                    ) {
                        OutlinedButton(
                            onClick = onDelete,
                            colors = ButtonDefaults.outlinedButtonColors(
                                contentColor = MaterialTheme.colorScheme.error
                            )
                        ) {
                            Icon(
                                imageVector = Icons.Default.Delete,
                                contentDescription = "删除",
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("删除")
                        }
                    }
                }
            }
            
            // 底部关闭按钮
            IconButton(
                onClick = onDismiss,
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(16.dp)
                    .size(48.dp)
                    .background(
                        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.8f),
                        shape = CircleShape
                    )
            ) {
                Icon(
                    imageVector = Icons.Default.Close,
                    contentDescription = "关闭",
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(24.dp)
                )
            }
        }
    }
}

/**
 * 从文件名中提取照片序号
 */
private fun extractPhotoNumber(fileName: String): Int {
    // 文件名格式: 项目名称_照片类型_序号_角度.jpg 或 
    // 项目名称_车辆名称_照片类型_序号_角度.jpg 或
    // 项目名称_车辆名称_轨迹名称_照片类型_序号_角度.jpg
    try {
        // 尝试从文件名中提取序号
        val parts = fileName.split("_")
        // 序号部分可能在不同位置，需要寻找数字部分
        for (i in 2 until parts.size) {
            if (parts[i].all { it.isDigit() }) {
                return parts[i].toIntOrNull() ?: 0
            }
        }
        return 0
    } catch (e: Exception) {
        return 0
    }
}

