package com.elon.camera_photo_system.presentation.gallery

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import coil.compose.rememberAsyncImagePainter
import coil.request.ImageRequest
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.model.PhotoType
import com.google.accompanist.swiperefresh.SwipeRefresh
import com.google.accompanist.swiperefresh.rememberSwipeRefreshState
import java.io.File

/**
 * 相册界面
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GalleryScreen(
    photos: List<Photo>,
    moduleType: ModuleType,
    onNavigateBack: () -> Unit,
    onPhotoClick: (Photo) -> Unit,
    onDeletePhoto: (Photo) -> Unit,
    isLoading: Boolean = false,
    error: String? = null,
    onRefresh: () -> Unit = {}
) {
    var selectedPhoto by remember { mutableStateOf<Photo?>(null) }
    var showDeleteDialog by remember { mutableStateOf(false) }
    var showFilterDialog by remember { mutableStateOf(false) }
    var showPhotoDetail by remember { mutableStateOf<Photo?>(null) }
    var selectedPhotoTypes by remember { mutableStateOf<Set<PhotoType>>(PhotoType.values().toSet()) }
    
    val filteredPhotos = remember(photos, selectedPhotoTypes) {
        photos.filter { it.photoType in selectedPhotoTypes }
    }
    
    val swipeRefreshState = rememberSwipeRefreshState(isLoading)
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(getGalleryTitle(moduleType)) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "返回")
                    }
                },
                actions = {
                    // 刷新按钮
                    IconButton(onClick = onRefresh) {
                        Icon(Icons.Default.Refresh, contentDescription = "刷新")
                    }
                    
                    // 筛选按钮
                    IconButton(onClick = { showFilterDialog = true }) {
                        Icon(Icons.Default.FilterList, contentDescription = "筛选")
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
                onRefresh = onRefresh,
                modifier = Modifier.fillMaxSize()
            ) {
                if (filteredPhotos.isEmpty()) {
                    // 空状态
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center
                        ) {
                            Text("暂无照片")
                            
                            if (photos.isNotEmpty() && filteredPhotos.isEmpty()) {
                                Spacer(modifier = Modifier.height(8.dp))
                                Text(
                                    "请尝试调整筛选条件",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.secondary
                                )
                            }
                        }
                    }
                } else {
                    // 照片网格
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(3),
                        contentPadding = PaddingValues(4.dp)
                    ) {
                        items(
                            items = filteredPhotos,
                            key = { it.id }
                        ) { photo ->
                            PhotoGridItem(
                                photo = photo,
                                onClick = { 
                                    showPhotoDetail = photo 
                                },
                                onLongClick = {
                                    selectedPhoto = photo
                                    showDeleteDialog = true
                                }
                            )
                        }
                    }
                }
            }
            
            // 加载状态指示器
            AnimatedVisibility(
                visible = isLoading,
                enter = fadeIn(),
                exit = fadeOut(),
                modifier = Modifier.align(Alignment.Center)
            ) {
                CircularProgressIndicator()
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
                    Snackbar(
                        action = {
                            TextButton(onClick = onRefresh) {
                                Text("重试")
                            }
                        }
                    ) {
                        Text(it)
                    }
                }
            }
            
            // 照片详情查看
            if (showPhotoDetail != null) {
                PhotoDetailScreen(
                    photo = showPhotoDetail!!,
                    onClose = { showPhotoDetail = null },
                    onDelete = {
                        selectedPhoto = showPhotoDetail
                        showPhotoDetail = null
                        showDeleteDialog = true
                    }
                )
            }
            
            // 删除确认对话框
            if (showDeleteDialog && selectedPhoto != null) {
                AlertDialog(
                    onDismissRequest = { 
                        showDeleteDialog = false 
                        selectedPhoto = null
                    },
                    title = { Text("删除照片") },
                    text = { Text("确定要删除这张照片吗？") },
                    confirmButton = {
                        TextButton(
                            onClick = {
                                selectedPhoto?.let { onDeletePhoto(it) }
                                showDeleteDialog = false
                                selectedPhoto = null
                            }
                        ) {
                            Text("确定")
                        }
                    },
                    dismissButton = {
                        TextButton(
                            onClick = { 
                                showDeleteDialog = false 
                                selectedPhoto = null
                            }
                        ) {
                            Text("取消")
                        }
                    }
                )
            }
            
            // 照片类型筛选对话框
            if (showFilterDialog) {
                AlertDialog(
                    onDismissRequest = { showFilterDialog = false },
                    title = { Text("照片类型筛选") },
                    text = {
                        Column {
                            PhotoType.values().forEach { photoType ->
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(vertical = 4.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Checkbox(
                                        checked = photoType in selectedPhotoTypes,
                                        onCheckedChange = { checked ->
                                            selectedPhotoTypes = if (checked) {
                                                selectedPhotoTypes + photoType
                                            } else {
                                                selectedPhotoTypes - photoType
                                            }
                                        }
                                    )
                                    
                                    Spacer(modifier = Modifier.width(8.dp))
                                    
                                    Text(getPhotoTypeText(photoType))
                                    
                                    Spacer(modifier = Modifier.width(8.dp))
                                    
                                    // 显示该类型照片的数量
                                    val count = photos.count { it.photoType == photoType }
                                    Card(
                                        colors = CardDefaults.cardColors(
                                            containerColor = getPhotoTypeColor(photoType)
                                        )
                                    ) {
                                        Text(
                                            text = count.toString(),
                                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp),
                                            style = MaterialTheme.typography.bodySmall,
                                            color = Color.White
                                        )
                                    }
                                }
                            }
                        }
                    },
                    confirmButton = {
                        TextButton(onClick = { showFilterDialog = false }) {
                            Text("确定")
                        }
                    },
                    dismissButton = {
                        TextButton(
                            onClick = { 
                                selectedPhotoTypes = PhotoType.values().toSet()
                                showFilterDialog = false
                            }
                        ) {
                            Text("重置")
                        }
                    }
                )
            }
        }
    }
}

/**
 * 照片详情屏幕 - 支持缩放、平移等操作
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PhotoDetailScreen(
    photo: Photo,
    onClose: () -> Unit,
    onDelete: () -> Unit
) {
    val context = LocalContext.current
    val file = remember(photo.filePath) { File(photo.filePath) }
    val exists = remember(file) { file.exists() }
    
    // 缩放和平移状态
    var scale by remember { mutableStateOf(1f) }
    var offset by remember { mutableStateOf(Offset.Zero) }
    var rotation by remember { mutableStateOf(0f) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(photo.fileName) },
                navigationIcon = {
                    IconButton(onClick = onClose) {
                        Icon(Icons.Default.Close, contentDescription = "关闭")
                    }
                },
                actions = {
                    IconButton(onClick = onDelete) {
                        Icon(Icons.Default.Delete, contentDescription = "删除")
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentAlignment = Alignment.Center
        ) {
            if (exists) {
                Image(
                    painter = rememberAsyncImagePainter(
                        ImageRequest.Builder(context)
                            .data(file)
                            .crossfade(true)
                            .build()
                    ),
                    contentDescription = photo.fileName,
                    modifier = Modifier
                        .fillMaxSize()
                        .graphicsLayer {
                            scaleX = scale
                            scaleY = scale
                            translationX = offset.x
                            translationY = offset.y
                            rotationZ = rotation
                        }
                        .pointerInput(Unit) {
                            detectTransformGestures { _, pan, zoom, rotateChange ->
                                scale = (scale * zoom).coerceIn(0.5f, 5f)
                                
                                // 根据缩放级别限制平移范围
                                val maxX = (scale - 1) * size.width / 2
                                val maxY = (scale - 1) * size.height / 2
                                
                                offset = Offset(
                                    x = (offset.x + pan.x).coerceIn(-maxX, maxX),
                                    y = (offset.y + pan.y).coerceIn(-maxY, maxY)
                                )
                                
                                // 可选：启用旋转
                                // rotation += rotateChange
                            }
                        },
                    contentScale = ContentScale.Fit
                )
                
                // 照片类型标识
                Card(
                    modifier = Modifier
                        .align(Alignment.TopStart)
                        .padding(16.dp)
                ) {
                    Text(
                        text = getPhotoTypeText(photo.photoType),
                        modifier = Modifier.padding(8.dp),
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
                
                // 双指缩放提示
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = Color.Black.copy(alpha = 0.3f)
                    ),
                    shape = MaterialTheme.shapes.small,
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(bottom = 16.dp)
                ) {
                    Text(
                        text = "双指缩放查看细节",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.White.copy(alpha = 0.7f),
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                    )
                }
            } else {
                // 照片文件不存在
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = "文件不存在",
                        tint = MaterialTheme.colorScheme.error,
                        modifier = Modifier.size(64.dp)
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "照片文件不存在或已被删除",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.error
                    )
                }
            }
        }
    }
}

/**
 * 照片网格项
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun PhotoGridItem(
    photo: Photo,
    onClick: () -> Unit,
    onLongClick: () -> Unit
) {
    val context = LocalContext.current
    val file = remember(photo.filePath) { File(photo.filePath) }
    val exists = remember(file) { file.exists() }
    
    // 添加动画效果
    var isPressed by remember { mutableStateOf(false) }
    val elevation by animateDpAsState(
        targetValue = if (isPressed) 8.dp else 2.dp,
        animationSpec = tween(durationMillis = 200),
        label = "elevation"
    )
    val scale by animateDpAsState(
        targetValue = if (isPressed) 0.95.dp else 1.dp,
        animationSpec = tween(durationMillis = 200),
        label = "scale"
    )
    
    Card(
        modifier = Modifier
            .padding(4.dp)
            .fillMaxWidth()
            .aspectRatio(1f)
            .scale(scale.value)
            .clickable { 
                isPressed = true
                onClick() 
            },
        elevation = CardDefaults.cardElevation(defaultElevation = elevation)
    ) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            if (exists) {
                // 显示照片
                Image(
                    painter = rememberAsyncImagePainter(
                        ImageRequest.Builder(context)
                            .data(file)
                            .crossfade(true)
                            .build()
                    ),
                    contentDescription = photo.fileName,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
                
                // 长按删除提示
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .combinedClickable(
                            onClick = {},
                            onLongClick = {
                                isPressed = true
                                onLongClick()
                            }
                        )
                )
                
                // 照片类型标识
                Box(
                    modifier = Modifier
                        .align(Alignment.TopStart)
                        .padding(4.dp)
                ) {
                    Card(
                        colors = CardDefaults.cardColors(
                            containerColor = getPhotoTypeColor(photo.photoType)
                        ),
                        modifier = Modifier.padding(2.dp)
                    ) {
                        Text(
                            text = getPhotoTypeText(photo.photoType),
                            modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp),
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
                
                // 添加上传状态标识
                if (photo.isUploaded) {
                    Box(
                        modifier = Modifier
                            .align(Alignment.BottomEnd)
                            .padding(4.dp)
                    ) {
                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.primary
                            ),
                            modifier = Modifier.padding(2.dp)
                        ) {
                            Text(
                                text = "已上传",
                                modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp),
                                style = MaterialTheme.typography.bodySmall
                            )
                        }
                    }
                }
            } else {
                // 照片文件不存在
                Icon(
                    imageVector = Icons.Default.Delete,
                    contentDescription = "文件不存在",
                    tint = MaterialTheme.colorScheme.error
                )
                Text(
                    text = "文件不存在",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.padding(top = 32.dp)
                )
            }
        }
    }
}

/**
 * 获取相册标题
 */
private fun getGalleryTitle(moduleType: ModuleType): String {
    return when (moduleType) {
        ModuleType.PROJECT -> "项目照片"
        ModuleType.VEHICLE -> "车辆照片"
        ModuleType.TRACK -> "轨迹照片"
    }
}

/**
 * 获取照片类型文本
 */
private fun getPhotoTypeText(photoType: PhotoType): String {
    return when (photoType) {
        PhotoType.START_POINT -> "起始点"
        PhotoType.MIDDLE_POINT -> "中间点"
        PhotoType.MODEL_POINT -> "模型点"
        PhotoType.END_POINT -> "结束点"
    }
}

/**
 * 获取照片类型颜色
 */
@Composable
private fun getPhotoTypeColor(photoType: PhotoType): Color {
    return when (photoType) {
        PhotoType.START_POINT -> MaterialTheme.colorScheme.primary
        PhotoType.MIDDLE_POINT -> MaterialTheme.colorScheme.secondary
        PhotoType.MODEL_POINT -> MaterialTheme.colorScheme.tertiary
        PhotoType.END_POINT -> MaterialTheme.colorScheme.error
    }
} 