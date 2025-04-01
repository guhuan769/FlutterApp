package com.elon.camera_photo_system.presentation.camera

import android.content.Context
import android.graphics.Color
import android.view.ViewGroup
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Collections
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.PhotoType
import java.io.File
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.Executor
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

/**
 * 相机界面
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CameraScreen(
    moduleType: ModuleType,
    moduleId: Long,
    onNavigateBack: () -> Unit,
    onNavigateToGallery: () -> Unit,
    onPhotoTaken: (filePath: String, fileName: String, photoType: PhotoType) -> Unit
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val coroutineScope = rememberCoroutineScope()
    
    var imageCapture: ImageCapture? by remember { mutableStateOf(null) }
    var selectedPhotoType by remember { mutableStateOf(getDefaultPhotoType(moduleType)) }
    
    // 拍照成功提示状态
    var showCaptureSuccess by remember { mutableStateOf(false) }
    val successAlpha by animateFloatAsState(
        targetValue = if (showCaptureSuccess) 1f else 0f,
        animationSpec = tween(durationMillis = 300),
        label = "successAlpha"
    )
    val successScale by animateFloatAsState(
        targetValue = if (showCaptureSuccess) 1f else 0.3f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        ),
        label = "successScale"
    )
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("拍照") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "返回")
                    }
                },
                actions = {
                    IconButton(onClick = onNavigateToGallery) {
                        Icon(Icons.Default.Collections, contentDescription = "相册")
                    }
                }
            )
        },
        containerColor = MaterialTheme.colorScheme.background
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // 相机预览
            CameraPreview(
                context = context,
                lifecycleOwner = lifecycleOwner,
                onImageCaptureCreated = { imageCapture = it }
            )
            
            // 十字标记
            Canvas(modifier = Modifier.fillMaxSize()) {
                val canvasWidth = size.width
                val canvasHeight = size.height
                val centerX = canvasWidth / 2
                val centerY = canvasHeight / 2
                val lineLength = 40.dp.toPx()
                
                drawLine(
                    color = androidx.compose.ui.graphics.Color.White,
                    start = androidx.compose.ui.geometry.Offset(centerX - lineLength / 2, centerY),
                    end = androidx.compose.ui.geometry.Offset(centerX + lineLength / 2, centerY),
                    strokeWidth = 3f
                )
                
                drawLine(
                    color = androidx.compose.ui.graphics.Color.White,
                    start = androidx.compose.ui.geometry.Offset(centerX, centerY - lineLength / 2),
                    end = androidx.compose.ui.geometry.Offset(centerX, centerY + lineLength / 2),
                    strokeWidth = 3f
                )
                
                // 绘制圆圈
                drawCircle(
                    color = androidx.compose.ui.graphics.Color.White,
                    center = androidx.compose.ui.geometry.Offset(centerX, centerY),
                    radius = 30.dp.toPx(),
                    style = Stroke(width = 2.dp.toPx())
                )
            }
            
            // 底部拍照按钮
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // 照片类型选择器 - 所有模块都显示，但根据模块类型启用或禁用按钮
                PhotoTypeSelector(
                    selectedPhotoType = selectedPhotoType,
                    onPhotoTypeSelected = { selectedPhotoType = it },
                    moduleType = moduleType
                )
                Spacer(modifier = Modifier.height(16.dp))
                
                // 拍照按钮
                Box(
                    modifier = Modifier
                        .size(80.dp)
                        .clip(CircleShape)
                        .border(4.dp, MaterialTheme.colorScheme.primary, CircleShape)
                        .padding(4.dp)
                ) {
                    Button(
                        onClick = {
                            takePhoto(
                                imageCapture = imageCapture,
                                context = context,
                                photoType = selectedPhotoType,
                                onSuccess = { filePath, fileName ->
                                    // 显示成功提示
                                    coroutineScope.launch {
                                        showCaptureSuccess = true
                                        
                                        // 调用回调
                                        onPhotoTaken(filePath, fileName, selectedPhotoType)
                                        
                                        // 延迟后隐藏提示
                                        delay(1500)
                                        showCaptureSuccess = false
                                    }
                                }
                            )
                        },
                        modifier = Modifier
                            .fillMaxSize()
                            .clip(CircleShape),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.primary
                        )
                    ) {}
                }
            }
            
            // 拍照成功提示
            AnimatedVisibility(
                visible = showCaptureSuccess,
                enter = fadeIn() + scaleIn(),
                exit = fadeOut() + scaleOut(),
                modifier = Modifier.align(Alignment.Center)
            ) {
                Card(
                    modifier = Modifier
                        .padding(16.dp)
                        .scale(successScale)
                        .alpha(successAlpha),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.9f)
                    ),
                    elevation = CardDefaults.cardElevation(
                        defaultElevation = 8.dp
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = "拍照成功",
                            modifier = Modifier.size(48.dp),
                            tint = MaterialTheme.colorScheme.primary
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "拍照成功",
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = getPhotoTypeDisplayName(selectedPhotoType),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                        )
                    }
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
    lifecycleOwner: LifecycleOwner,
    onImageCaptureCreated: (ImageCapture) -> Unit
) {
    val cameraProviderFuture = remember { ProcessCameraProvider.getInstance(context) }
    
    AndroidView(
        factory = { ctx ->
            val previewView = PreviewView(ctx).apply {
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
                implementationMode = PreviewView.ImplementationMode.COMPATIBLE
                scaleType = PreviewView.ScaleType.FILL_CENTER
            }
            
            cameraProviderFuture.addListener({
                val cameraProvider = cameraProviderFuture.get()
                val preview = Preview.Builder().build().also {
                    it.setSurfaceProvider(previewView.surfaceProvider)
                }
                
                val imageCapture = ImageCapture.Builder()
                    .setCaptureMode(ImageCapture.CAPTURE_MODE_MAXIMIZE_QUALITY)
                    .build()
                
                val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
                
                try {
                    cameraProvider.unbindAll()
                    cameraProvider.bindToLifecycle(
                        lifecycleOwner,
                        cameraSelector,
                        preview,
                        imageCapture
                    )
                    onImageCaptureCreated(imageCapture)
                } catch (ex: Exception) {
                    ex.printStackTrace()
                }
            }, ContextCompat.getMainExecutor(ctx))
            
            previewView
        },
        modifier = Modifier.fillMaxSize()
    )
}

/**
 * 照片类型选择器
 */
@Composable
fun PhotoTypeSelector(
    selectedPhotoType: PhotoType,
    onPhotoTypeSelected: (PhotoType) -> Unit,
    moduleType: ModuleType
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        // 根据模块类型确定每个按钮是否可用
        val startPointEnabled = moduleType == ModuleType.TRACK
        val middlePointEnabled = moduleType == ModuleType.TRACK
        val modelPointEnabled = true // 所有模块都可用
        val endPointEnabled = moduleType == ModuleType.TRACK
        
        PhotoTypeButton(
            text = "起始点",
            isSelected = selectedPhotoType == PhotoType.START_POINT && startPointEnabled,
            enabled = startPointEnabled,
            onClick = { 
                if (startPointEnabled) {
                    onPhotoTypeSelected(PhotoType.START_POINT)
                }
            }
        )
        
        PhotoTypeButton(
            text = "中间点",
            isSelected = selectedPhotoType == PhotoType.MIDDLE_POINT && middlePointEnabled,
            enabled = middlePointEnabled,
            onClick = { 
                if (middlePointEnabled) {
                    onPhotoTypeSelected(PhotoType.MIDDLE_POINT)
                }
            }
        )
        
        PhotoTypeButton(
            text = "模型点",
            isSelected = selectedPhotoType == PhotoType.MODEL_POINT,
            enabled = modelPointEnabled,
            onClick = { onPhotoTypeSelected(PhotoType.MODEL_POINT) }
        )
        
        PhotoTypeButton(
            text = "结束点",
            isSelected = selectedPhotoType == PhotoType.END_POINT && endPointEnabled,
            enabled = endPointEnabled,
            onClick = { 
                if (endPointEnabled) {
                    onPhotoTypeSelected(PhotoType.END_POINT)
                }
            }
        )
    }
}

@Composable
fun PhotoTypeButton(
    text: String,
    isSelected: Boolean,
    enabled: Boolean = true,
    onClick: () -> Unit
) {
    Button(
        onClick = onClick,
        modifier = Modifier
            .height(36.dp)
            .widthIn(min = 60.dp)
            .padding(horizontal = 2.dp),
        contentPadding = PaddingValues(horizontal = 4.dp, vertical = 4.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = when {
                !enabled -> MaterialTheme.colorScheme.surfaceVariant
                isSelected -> MaterialTheme.colorScheme.primary
                else -> MaterialTheme.colorScheme.secondary
            },
            contentColor = when {
                !enabled -> MaterialTheme.colorScheme.onSurfaceVariant
                else -> MaterialTheme.colorScheme.onPrimary
            }
        ),
        enabled = enabled
    ) {
        Text(
            text = text, 
            style = MaterialTheme.typography.labelSmall,
            fontSize = 11.sp,
            maxLines = 1,
            overflow = TextOverflow.Visible
        )
    }
}

/**
 * 拍照方法
 */
private fun takePhoto(
    imageCapture: ImageCapture?,
    context: Context,
    photoType: PhotoType,
    onSuccess: (filePath: String, fileName: String) -> Unit
) {
    imageCapture ?: return
    
    try {
        // 创建照片文件
        val photoFile = createPhotoFile(context, photoType)
        
        // 确保目录存在
        photoFile.parentFile?.mkdirs()
        
        // 照片输出选项
        val outputOptions = ImageCapture.OutputFileOptions.Builder(photoFile).build()
        
        // 拍照
        imageCapture.takePicture(
            outputOptions,
            ContextCompat.getMainExecutor(context),
            object : ImageCapture.OnImageSavedCallback {
                override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
                    onSuccess(photoFile.absolutePath, photoFile.name)
                }
                
                override fun onError(exception: ImageCaptureException) {
                    exception.printStackTrace()
                }
            }
        )
    } catch (e: Exception) {
        e.printStackTrace()
    }
}

/**
 * 创建照片文件
 */
private fun createPhotoFile(context: Context, photoType: PhotoType): File {
    // 生成照片名称
    val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
    val photoFileName = when (photoType) {
        PhotoType.START_POINT -> "起始点拍照_$timeStamp.jpg"
        PhotoType.MIDDLE_POINT -> "中间点拍照_$timeStamp.jpg"
        PhotoType.MODEL_POINT -> "模型点拍照_$timeStamp.jpg"
        PhotoType.END_POINT -> "结束点拍照_$timeStamp.jpg"
    }
    
    // 创建照片文件
    val storageDir = context.getExternalFilesDir("Photos")
    // 确保目录存在
    storageDir?.mkdirs()
    return File(storageDir, photoFileName)
}

/**
 * 获取默认照片类型
 */
private fun getDefaultPhotoType(moduleType: ModuleType): PhotoType {
    return when (moduleType) {
        ModuleType.PROJECT -> PhotoType.MODEL_POINT
        ModuleType.VEHICLE -> PhotoType.MODEL_POINT
        ModuleType.TRACK -> PhotoType.START_POINT
    }
}

/**
 * 获取照片类型显示名称
 */
private fun getPhotoTypeDisplayName(photoType: PhotoType): String {
    return when (photoType) {
        PhotoType.START_POINT -> "起始点照片"
        PhotoType.MIDDLE_POINT -> "中间点照片"
        PhotoType.MODEL_POINT -> "模型点照片" 
        PhotoType.END_POINT -> "结束点照片"
    }
}

/**
 * 获取相机提供者
 */
private suspend fun getCameraProvider(context: Context): ProcessCameraProvider {
    return suspendCoroutine { continuation ->
        ProcessCameraProvider.getInstance(context).also { cameraProvider ->
            cameraProvider.addListener(
                {
                    continuation.resume(cameraProvider.get())
                },
                ContextCompat.getMainExecutor(context)
            )
        }
    }
} 