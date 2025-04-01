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
import coil.compose.AsyncImage
import coil.request.ImageRequest
import com.elon.camera_photo_system.R
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.Photo
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
                LazyVerticalGrid(
                    columns = GridCells.Fixed(2),
                    contentPadding = PaddingValues(8.dp),
                    modifier = Modifier.fillMaxSize()
                ) {
                    items(photos) { photo ->
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
                
                // 照片类型标签
                Surface(
                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.8f),
                    shape = RoundedCornerShape(topEnd = 8.dp, bottomEnd = 8.dp),
                    modifier = Modifier
                        .align(Alignment.BottomStart)
                        .padding(bottom = 8.dp)
                ) {
                    Text(
                        text = photo.photoType.label,
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onPrimary,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PhotoDetailDialog(
    photo: Photo,
    onDismiss: () -> Unit,
    onDelete: () -> Unit
) {
    val context = LocalContext.current
    
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
                    .pointerInput(Unit) {
                        detectTapGestures(
                            onDoubleTap = {
                                coroutineScope.launch {
                                    if (scale > 1f) {
                                        // 如果已经放大，则重置为原始大小
                                        scale = 1f
                                        offset = Offset.Zero
                                    } else {
                                        // 如果是原始大小，则放大到2倍
                                        scale = 2f
                                    }
                                }
                            },
                            onTap = {
                                showDetails = !showDetails
                            }
                        )
                    }
            )
            
            // 顶部工具栏
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 24.dp)
                    .background(Color.Black.copy(alpha = 0.5f))
                    .padding(horizontal = 8.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = onDismiss) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "关闭",
                        tint = Color.White
                    )
                }
                
                IconButton(
                    onClick = { showDetails = !showDetails }
                ) {
                    Icon(
                        imageVector = Icons.Default.Info,
                        contentDescription = "信息",
                        tint = Color.White
                    )
                }
                
                IconButton(onClick = onDelete) {
                    Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = "删除",
                        tint = Color.White
                    )
                }
            }
            
            // 底部信息栏
            if (showDetails) {
                Surface(
                    modifier = Modifier
                        .fillMaxWidth()
                        .align(Alignment.BottomCenter)
                        .padding(16.dp)
                        .clip(RoundedCornerShape(12.dp)),
                    color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.9f)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Text(
                            text = "照片信息",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = "类型",
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = photo.photoType.label,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(4.dp))
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = "分辨率",
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = resolution,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(4.dp))
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = "文件大小",
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = fileSize,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(4.dp))
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = "创建时间",
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
//                                text = photo.creationDate,
                                text = "",
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                fontWeight = FontWeight.Bold,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }
                    }
                }
            }
            
            // 提示信息
            if (scale == 1f) {
                Text(
                    text = "双击放大图片",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.White.copy(alpha = 0.7f),
                    modifier = Modifier
                        .align(Alignment.Center)
                        .offset(y = 150.dp)
                        .alpha(0.7f)
                )
            }
        }
    }
}

