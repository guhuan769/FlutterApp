package com.elon.camera_photo_system.presentation.camera

import android.Manifest
import android.content.Context
import android.graphics.Color
import android.view.ViewGroup
import androidx.camera.view.PreviewView
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Snackbar
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color as ComposeColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.elon.camera_photo_system.R
import com.elon.camera_photo_system.domain.model.FlashMode
import com.elon.camera_photo_system.domain.model.LensFacing
import com.elon.camera_photo_system.domain.model.PhotoType
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.rememberPermissionState

/**
 * 相机界面
 */
@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun CameraScreen(
    viewModel: CameraViewModel
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    
    // 相机权限
    val cameraPermissionState = rememberPermissionState(Manifest.permission.CAMERA)
    
    // 请求相机权限
    LaunchedEffect(key1 = Unit) {
        if (!cameraPermissionState.status.isGranted) {
            cameraPermissionState.launchPermissionRequest()
        }
    }
    
    // 生命周期观察
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                // 相机权限已获取，初始化相机
                if (cameraPermissionState.status.isGranted && !uiState.isInitialized) {
                    // 相机初始化逻辑会在预览视图创建时触发
                }
            }
            
            if (event == Lifecycle.Event.ON_STOP) {
                // 释放相机资源
                viewModel.releaseCamera()
            }
        }
        
        lifecycleOwner.lifecycle.addObserver(observer)
        
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    }
    
    Box(modifier = Modifier.fillMaxSize()) {
        // 如果没有相机权限，显示错误信息
        if (!cameraPermissionState.status.isGranted) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    text = stringResource(R.string.camera_permission_required),
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Bold
                )
                
                IconButton(
                    onClick = { cameraPermissionState.launchPermissionRequest() },
                    modifier = Modifier.padding(top = 16.dp)
                ) {
                    Text(text = stringResource(R.string.grant_permission))
                }
            }
        } else {
            // 相机预览
            CameraPreview(
                context = context,
                onViewCreated = { previewView ->
                    // 当预览视图创建完成后，初始化相机
                    viewModel.initCamera(previewView)
                }
            )
            
            // 中心十字标记
            Box(
                modifier = Modifier
                    .size(30.dp)
                    .align(Alignment.Center)
            ) {
                // 垂直线
                Box(
                    modifier = Modifier
                        .size(1.dp, 30.dp)
                        .background(ComposeColor.White)
                        .align(Alignment.Center)
                )
                
                // 水平线
                Box(
                    modifier = Modifier
                        .size(30.dp, 1.dp)
                        .background(ComposeColor.White)
                        .align(Alignment.Center)
                )
            }
            
            // 相机控制UI
            CameraControls(
                uiState = uiState,
                onFlashModeToggle = { viewModel.toggleFlashMode() },
                onCameraToggle = { viewModel.toggleCamera() },
                onPhotoTypeSelected = { viewModel.setPhotoType(it) },
                onCaptureClick = { viewModel.takePhoto() }
            )
            
            // 加载中指示器
            if (uiState.isLoading || uiState.isCapturing) {
                CircularProgressIndicator(
                    modifier = Modifier.align(Alignment.Center)
                )
            }
            
            // 错误信息
            uiState.error?.let { error ->
                Snackbar(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(16.dp),
                    action = {
                        Text(
                            text = stringResource(R.string.close),
                            modifier = Modifier.clickable { viewModel.clearError() }
                        )
                    }
                ) {
                    Text(text = error)
                }
            }
        }
    }
}

/**
 * 相机预览组件
 */
@Composable
fun CameraPreview(
    context: Context,
    onViewCreated: (PreviewView) -> Unit
) {
    // 使用AndroidView包装Camera2的PreviewView
    AndroidView(
        factory = { ctx ->
            PreviewView(ctx).apply {
                this.scaleType = PreviewView.ScaleType.FILL_CENTER
                
                // 设置半透明黑色作为背景色
                setBackgroundColor(Color.parseColor("#99000000"))
                
                // 保持纵横比
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
                
                // 此时预览视图已创建完成，可以初始化相机
                onViewCreated(this)
            }
        },
        modifier = Modifier.fillMaxSize()
    )
}

/**
 * 相机控制UI
 */
@Composable
fun CameraControls(
    uiState: CameraUiState,
    onFlashModeToggle: () -> Unit,
    onCameraToggle: () -> Unit,
    onPhotoTypeSelected: (PhotoType) -> Unit,
    onCaptureClick: () -> Unit
) {
    Box(modifier = Modifier.fillMaxSize()) {
        // 顶部控制栏
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
                .align(Alignment.TopCenter),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // 闪光灯控制
            if (uiState.hasFlashUnit) {
                IconButton(
                    onClick = onFlashModeToggle,
                    modifier = Modifier
                        .size(48.dp)
                        .background(ComposeColor.Black.copy(alpha = 0.3f), CircleShape)
                ) {
                    Icon(
                        painter = painterResource(
                            id = when (uiState.flashMode) {
                                FlashMode.AUTO -> R.drawable.ic_flash_auto
                                FlashMode.ON -> R.drawable.ic_flash_on
                                FlashMode.OFF -> R.drawable.ic_flash_off
                            }
                        ),
                        contentDescription = stringResource(R.string.flash_mode),
                        tint = ComposeColor.White
                    )
                }
            } else {
                // 占位符
                Box(modifier = Modifier.size(48.dp))
            }
            
            // 相机切换按钮
            IconButton(
                onClick = onCameraToggle,
                modifier = Modifier
                    .size(48.dp)
                    .background(ComposeColor.Black.copy(alpha = 0.3f), CircleShape)
            ) {
                Icon(
                    painter = painterResource(id = R.drawable.ic_camera_switch),
                    contentDescription = stringResource(R.string.switch_camera),
                    tint = ComposeColor.White
                )
            }
        }
        
        // 底部控制栏
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 32.dp)
                .align(Alignment.BottomCenter),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // 照片类型选择
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp)
                    .background(ComposeColor.Black.copy(alpha = 0.3f), MaterialTheme.shapes.medium),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                PhotoTypeButton(
                    type = PhotoType.START_POINT,
                    isSelected = uiState.photoType == PhotoType.START_POINT,
                    onClick = { onPhotoTypeSelected(PhotoType.START_POINT) }
                )
                
                PhotoTypeButton(
                    type = PhotoType.MIDDLE_POINT,
                    isSelected = uiState.photoType == PhotoType.MIDDLE_POINT,
                    onClick = { onPhotoTypeSelected(PhotoType.MIDDLE_POINT) }
                )
                
                PhotoTypeButton(
                    type = PhotoType.MODEL_POINT,
                    isSelected = uiState.photoType == PhotoType.MODEL_POINT,
                    onClick = { onPhotoTypeSelected(PhotoType.MODEL_POINT) }
                )
                
                PhotoTypeButton(
                    type = PhotoType.END_POINT,
                    isSelected = uiState.photoType == PhotoType.END_POINT,
                    onClick = { onPhotoTypeSelected(PhotoType.END_POINT) }
                )
            }
            
            // 拍照按钮
            Box(
                modifier = Modifier
                    .padding(top = 20.dp)
                    .size(72.dp)
                    .clip(CircleShape)
                    .background(ComposeColor.White.copy(alpha = 0.8f))
                    .border(
                        width = 4.dp,
                        color = ComposeColor.White,
                        shape = CircleShape
                    )
                    .clickable(enabled = !uiState.isCapturing) { onCaptureClick() }
            ) {
                // 拍照按钮内部添加视觉反馈
                if (uiState.isCapturing) {
                    CircularProgressIndicator(
                        modifier = Modifier
                            .size(36.dp)
                            .align(Alignment.Center),
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
        }
    }
} 