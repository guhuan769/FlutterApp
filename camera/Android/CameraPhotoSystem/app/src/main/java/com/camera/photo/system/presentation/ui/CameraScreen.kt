package com.camera.photo.system.presentation.ui

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.view.PreviewView
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FlashOff
import androidx.compose.material.icons.filled.FlashOn
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.livedata.observeAsState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import com.camera.photo.system.domain.model.PhotoType
import com.camera.photo.system.presentation.viewmodel.CameraEvent
import com.camera.photo.system.presentation.viewmodel.CameraViewModel

/**
 * 相机界面
 */
@Composable
fun CameraScreen(
    viewModel: CameraViewModel = hiltViewModel(),
    navigateToGallery: () -> Unit = {}
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val uiState by viewModel.uiState.collectAsState()
    val event by viewModel.events.observeAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    
    // 权限相关状态
    var hasCameraPermission by remember { mutableStateOf(
        ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == 
        PackageManager.PERMISSION_GRANTED
    )}
    var hasStoragePermission by remember { mutableStateOf(false) }
    
    // 判断存储权限
    LaunchedEffect(Unit) {
        hasStoragePermission = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            ContextCompat.checkSelfPermission(context, Manifest.permission.READ_MEDIA_IMAGES) == 
            PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(context, Manifest.permission.READ_EXTERNAL_STORAGE) == 
            PackageManager.PERMISSION_GRANTED
        }
    }
    
    // 权限请求Launcher
    val requestPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        hasCameraPermission = permissions[Manifest.permission.CAMERA] ?: hasCameraPermission
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            hasStoragePermission = permissions[Manifest.permission.READ_MEDIA_IMAGES] ?: hasStoragePermission
        } else {
            hasStoragePermission = permissions[Manifest.permission.READ_EXTERNAL_STORAGE] ?: hasStoragePermission
        }
        
        // 如果权限都已获取，则初始化相机
        if (hasCameraPermission && hasStoragePermission) {
            viewModel.initCamera(context)
        }
    }
    
    // 处理事件
    LaunchedEffect(event) {
        event?.let {
            when (it) {
                is CameraEvent.ShowMessage -> {
                    snackbarHostState.showSnackbar(it.message)
                }
                is CameraEvent.Error -> {
                    snackbarHostState.showSnackbar(it.message)
                }
                is CameraEvent.PhotoCaptured -> {
                    snackbarHostState.showSnackbar("照片已保存: ${it.photo.path}")
                }
                is CameraEvent.CameraInitialized -> {
                    snackbarHostState.showSnackbar("相机初始化成功")
                }
            }
        }
    }
    
    // 界面构建
    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        if (!hasCameraPermission || !hasStoragePermission) {
            // 显示权限请求界面
            PermissionRequestScreen(
                paddingValues = paddingValues,
                onRequestPermission = {
                    // 请求所需权限
                    val permissions = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                        arrayOf(Manifest.permission.CAMERA, Manifest.permission.READ_MEDIA_IMAGES)
                    } else {
                        arrayOf(
                            Manifest.permission.CAMERA,
                            Manifest.permission.READ_EXTERNAL_STORAGE,
                            Manifest.permission.WRITE_EXTERNAL_STORAGE
                        )
                    }
                    requestPermissionLauncher.launch(permissions)
                }
            )
        } else {
            // 显示相机界面
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
            ) {
                // 相机预览
                CameraPreview(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                )
                
                // 相机控制界面
                CameraControls(
                    isLoading = uiState.isLoading,
                    flashMode = uiState.flashMode,
                    onCaptureClick = { viewModel.takePhoto(uiState.photoType) },
                    onFlashToggle = { viewModel.toggleFlashMode() },
                    onGalleryClick = navigateToGallery
                )
            }
        }
    }
    
    // 确保在有权限后初始化相机
    LaunchedEffect(hasCameraPermission, hasStoragePermission) {
        if (hasCameraPermission && hasStoragePermission) {
            viewModel.initCamera(context)
        }
    }
}

/**
 * 权限请求界面
 */
@Composable
fun PermissionRequestScreen(
    paddingValues: PaddingValues,
    onRequestPermission: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(paddingValues),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "需要相机和存储权限",
                style = MaterialTheme.typography.headlineSmall
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "为了使用拍照功能，我们需要相机和存储权限",
                style = MaterialTheme.typography.bodyMedium
            )
            Spacer(modifier = Modifier.height(32.dp))
            Button(onClick = onRequestPermission) {
                Text("授予权限")
            }
        }
    }
}

/**
 * 相机预览组件
 */
@Composable
fun CameraPreview(
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier) {
        // 使用AndroidView嵌入CameraX预览
        AndroidView(
            factory = { context ->
                PreviewView(context).apply {
                    // 设置预览比例
                    scaleType = PreviewView.ScaleType.FILL_CENTER
                }
            },
            modifier = Modifier.fillMaxSize()
        )
        
        // 添加中心十字标记
        Box(
            modifier = Modifier
                .size(40.dp)
                .align(Alignment.Center)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .border(1.dp, Color.White)
            )
            
            Box(
                modifier = Modifier
                    .size(1.dp, 40.dp)
                    .align(Alignment.Center)
                    .border(1.dp, Color.White)
            )
            
            Box(
                modifier = Modifier
                    .size(40.dp, 1.dp)
                    .align(Alignment.Center)
                    .border(1.dp, Color.White)
            )
        }
    }
}

/**
 * 相机控制组件
 */
@Composable
fun CameraControls(
    isLoading: Boolean,
    flashMode: Int,
    onCaptureClick: () -> Unit,
    onFlashToggle: () -> Unit,
    onGalleryClick: () -> Unit
) {
    Surface(
        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.9f),
        modifier = Modifier.fillMaxWidth()
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            contentAlignment = Alignment.Center
        ) {
            // 闪光灯按钮
            IconButton(
                onClick = onFlashToggle,
                modifier = Modifier.align(Alignment.CenterStart)
            ) {
                Icon(
                    imageVector = if (flashMode == 0) Icons.Filled.FlashOff else Icons.Filled.FlashOn,
                    contentDescription = "闪光灯"
                )
            }
            
            // 拍照按钮
            FloatingActionButton(
                onClick = onCaptureClick,
                modifier = Modifier
                    .size(72.dp)
                    .clip(CircleShape)
                    .align(Alignment.Center),
                containerColor = MaterialTheme.colorScheme.primary
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        color = MaterialTheme.colorScheme.onPrimary,
                        modifier = Modifier.size(36.dp)
                    )
                } else {
                    Icon(
                        imageVector = Icons.Filled.PhotoCamera,
                        contentDescription = "拍照",
                        modifier = Modifier.size(36.dp),
                        tint = MaterialTheme.colorScheme.onPrimary
                    )
                }
            }
            
            // 相册按钮
            IconButton(
                onClick = onGalleryClick,
                modifier = Modifier.align(Alignment.CenterEnd)
            ) {
                Icon(
                    imageVector = Icons.Filled.PhotoCamera, // 应该使用相册图标，这里临时使用相机图标
                    contentDescription = "相册"
                )
            }
        }
    }
} 