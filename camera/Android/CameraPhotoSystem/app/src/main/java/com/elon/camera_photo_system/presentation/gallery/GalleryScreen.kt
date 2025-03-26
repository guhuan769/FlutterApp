package com.elon.camera_photo_system.presentation.gallery

import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import coil.compose.rememberAsyncImagePainter
import coil.request.ImageRequest
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.model.PhotoType
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
    onDeletePhoto: (Photo) -> Unit
) {
    var selectedPhoto by remember { mutableStateOf<Photo?>(null) }
    var showDeleteDialog by remember { mutableStateOf(false) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(getGalleryTitle(moduleType)) },
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
            if (photos.isEmpty()) {
                // 空状态
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text("暂无照片")
                }
            } else {
                // 照片网格
                LazyVerticalGrid(
                    columns = GridCells.Fixed(3),
                    contentPadding = PaddingValues(4.dp)
                ) {
                    items(photos) { photo ->
                        PhotoGridItem(
                            photo = photo,
                            onClick = { onPhotoClick(photo) },
                            onLongClick = {
                                selectedPhoto = photo
                                showDeleteDialog = true
                            }
                        )
                    }
                }
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
    
    Card(
        modifier = Modifier
            .padding(4.dp)
            .fillMaxWidth()
            .aspectRatio(1f)
            .clickable { onClick() },
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
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
                            onLongClick = onLongClick
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
private fun getPhotoTypeColor(photoType: PhotoType): androidx.compose.ui.graphics.Color {
    return when (photoType) {
        PhotoType.START_POINT -> MaterialTheme.colorScheme.primary
        PhotoType.MIDDLE_POINT -> MaterialTheme.colorScheme.secondary
        PhotoType.MODEL_POINT -> MaterialTheme.colorScheme.tertiary
        PhotoType.END_POINT -> MaterialTheme.colorScheme.error
    }
} 