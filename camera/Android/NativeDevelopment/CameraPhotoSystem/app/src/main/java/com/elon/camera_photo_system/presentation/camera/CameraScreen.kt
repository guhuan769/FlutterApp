package com.elon.camera_photo_system.presentation.camera

import android.content.Context
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
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.CloudUpload
import androidx.compose.material.icons.filled.Collections
import androidx.compose.material.icons.filled.Error
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.compose.collectAsStateWithLifecycle
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
    onPhotoTaken: (filePath: String, fileName: String, photoType: PhotoType) -> Unit,
    viewModel: CameraViewModel
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val coroutineScope = rememberCoroutineScope()
    val cameraUiState by viewModel.cameraUIState.collectAsStateWithLifecycle()
    val moduleInfo by viewModel.moduleInfo.collectAsStateWithLifecycle()
    
    var imageCapture: ImageCapture? by remember { mutableStateOf(null) }
    var selectedPhotoType by remember { mutableStateOf(getDefaultPhotoType(moduleType)) }
    
    // 添加角度输入状态
    var angleValue by remember { mutableStateOf("0") }
    
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
    
    // 加载模块信息
    LaunchedEffect(moduleId, moduleType) {
        viewModel.loadModuleInfo(moduleId, moduleType)
    }
    
    // 处理上传状态
    val snackbarHostState = remember { SnackbarHostState() }
    
    LaunchedEffect(cameraUiState.uploadError) {
        cameraUiState.uploadError?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }
    
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
        snackbarHost = { SnackbarHost(hostState = snackbarHostState) },
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
            
            // 将角度输入框移到顶部
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 8.dp, start = 16.dp, end = 16.dp)
                    .align(Alignment.TopCenter)
            ) {
                // 添加角度输入框
                Card(
                    modifier = Modifier
                        .fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.8f)
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(8.dp),
                    ) {
                        Text(
                            text = "拍摄角度",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        OutlinedTextField(
                            value = angleValue,
                            onValueChange = { 
                                // 仅允许输入数字
                                if (it.isEmpty() || it.all { char -> char.isDigit() }) {
                                    angleValue = it
                                }
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(top = 4.dp),
                            keyboardOptions = KeyboardOptions(
                                keyboardType = KeyboardType.Number
                            ),
                            singleLine = true,
                            placeholder = { Text("输入拍摄角度（0-360）") },
                            trailingIcon = {
                                Text(
                                    text = "°",
                                    style = MaterialTheme.typography.bodyMedium,
                                    modifier = Modifier.padding(end = 8.dp)
                                )
                            },
                            colors = TextFieldDefaults.outlinedTextFieldColors(
                                containerColor = MaterialTheme.colorScheme.surface,
                                focusedTextColor = MaterialTheme.colorScheme.onSurface
                            )
                        )
                    }
                }
            }
            
            // 底部拍照按钮
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // 照片类型选择器
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
                            // 获取下一个照片序号
                            val photoNumber = viewModel.getNextPhotoNumber(selectedPhotoType)
                            
                            takePhoto(
                                imageCapture = imageCapture,
                                context = context,
                                photoType = selectedPhotoType,
                                angle = angleValue.toIntOrNull() ?: 0,
                                moduleType = moduleType,
                                moduleId = moduleId,
                                moduleInfo = moduleInfo,
                                photoNumber = photoNumber,
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
            
            // 上传状态指示器
            if (cameraUiState.isUploading) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp),
                    contentAlignment = Alignment.TopCenter
                ) {
                    Card(
                        shape = RoundedCornerShape(8.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.9f)
                        ),
                        elevation = CardDefaults.cardElevation(
                            defaultElevation = 4.dp
                        )
                    ) {
//                        Row(
//                            modifier = Modifier
//                                .padding(horizontal = 16.dp, vertical = 8.dp),
//                            verticalAlignment = Alignment.CenterVertically
//                        ) {
//                            CircularProgressIndicator(
//                                modifier = Modifier.size(24.dp),
//                                strokeWidth = 2.dp
//                            )
//                            Spacer(modifier = Modifier.width(16.dp))
//                            Text(
//                                text = "正在上传照片...",
//                                style = MaterialTheme.typography.bodyMedium
//                            )
//                        }
                    }
                }
            } else if (cameraUiState.isUploadSuccess) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp),
                    contentAlignment = Alignment.TopCenter
                ) {
                    Card(
                        shape = RoundedCornerShape(8.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.9f)
                        ),
                        elevation = CardDefaults.cardElevation(
                            defaultElevation = 4.dp
                        )
                    ) {
                        Row(
                            modifier = Modifier
                                .padding(horizontal = 16.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Default.CloudUpload,
                                contentDescription = "上传成功",
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(24.dp)
                            )
                            Spacer(modifier = Modifier.width(16.dp))
                            Text(
                                text = "照片上传成功",
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
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
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // 设置每种模块类型可用的按钮
        when (moduleType) {
            ModuleType.PROJECT, ModuleType.VEHICLE -> {
                // 项目和车辆只能选择模型点
                Button(
                    onClick = { onPhotoTypeSelected(PhotoType.MODEL_POINT) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.primary,
                        contentColor = MaterialTheme.colorScheme.onPrimary
                    )
                ) {
                    Text(
                        text = "模型点拍照", 
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
            ModuleType.TRACK -> {
                // 轨迹模式下显示网格按钮布局
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // 第一列：起始点和中间点
                    Column(
                        modifier = Modifier.weight(1f),
                        verticalArrangement = Arrangement.Center
                    ) {
                        TrackPhotoTypeButton(
                            text = "起始点",
                            isSelected = selectedPhotoType == PhotoType.START_POINT,
                            color = MaterialTheme.colorScheme.primary,
                            onClick = { onPhotoTypeSelected(PhotoType.START_POINT) }
                        )
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        TrackPhotoTypeButton(
                            text = "中间点",
                            isSelected = selectedPhotoType == PhotoType.MIDDLE_POINT,
                            color = MaterialTheme.colorScheme.secondary,
                            onClick = { onPhotoTypeSelected(PhotoType.MIDDLE_POINT) }
                        )
                    }
                    
                    // 第二列：过渡点和结束点 (移除了模型点)
                    Column(
                        modifier = Modifier.weight(1f),
                        verticalArrangement = Arrangement.Center
                    ) {
                        TrackPhotoTypeButton(
                            text = "过渡点",
                            isSelected = selectedPhotoType == PhotoType.TRANSITION_POINT,
                            color = MaterialTheme.colorScheme.surfaceTint,
                            onClick = { onPhotoTypeSelected(PhotoType.TRANSITION_POINT) }
                        )
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        TrackPhotoTypeButton(
                            text = "结束点",
                            isSelected = selectedPhotoType == PhotoType.END_POINT,
                            color = MaterialTheme.colorScheme.error,
                            onClick = { onPhotoTypeSelected(PhotoType.END_POINT) }
                        )
                    }
                }
            }
        }
    }
}

/**
 * 轨迹照片类型按钮
 */
@Composable
fun TrackPhotoTypeButton(
    text: String,
    isSelected: Boolean,
    color: Color,
    onClick: () -> Unit
) {
    Button(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .height(50.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = if (isSelected) color else color.copy(alpha = 0.6f),
            contentColor = MaterialTheme.colorScheme.onPrimary
        ),
        shape = RoundedCornerShape(8.dp)
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
        )
    }
}

/**
 * 拍照
 */
private fun takePhoto(
    imageCapture: ImageCapture?,
    context: Context,
    photoType: PhotoType,
    angle: Int,
    moduleType: ModuleType,
    moduleId: Long,
    moduleInfo: ModuleInfo,
    photoNumber: Int,
    onSuccess: (String, String) -> Unit
) {
    imageCapture ?: return
    
    try {
        // 创建照片文件，确保角度值非负
        val safeAngle = if (angle < 0) 0 else angle
        val photoFile = createPhotoFile(context, photoType, safeAngle, moduleType, moduleInfo, photoNumber)
        
        // 打印日志确认角度值
        android.util.Log.d("CameraScreen", "拍照 - 类型: ${photoType.label}, 序号: $photoNumber, 角度: $safeAngle")
        android.util.Log.d("CameraScreen", "生成的文件名: ${photoFile.name}")
        
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
private fun createPhotoFile(
    context: Context, 
    photoType: PhotoType, 
    angle: Int, 
    moduleType: ModuleType, 
    moduleInfo: ModuleInfo,
    photoNumber: Int
): File {
    // 确保角度值是整数
    val safeAngle = if (angle < 0) 0 else angle
    
    // 照片名称根据不同模块类型构建
    val photoFileName = when (moduleType) {
        ModuleType.PROJECT -> {
            // 格式：项目名称_照片类型_序号_角度.jpg
            "${moduleInfo.projectName}_${getPhotoTypeCode(photoType)}_${photoNumber}_${safeAngle}°.jpg"
        }
        ModuleType.VEHICLE -> {
            // 格式：父项目名称_车辆名称_照片类型_序号_角度.jpg
            "${moduleInfo.projectName}_${moduleInfo.vehicleName}_${getPhotoTypeCode(photoType)}_${photoNumber}_${safeAngle}°.jpg"
        }
        ModuleType.TRACK -> {
            // 格式：父项目名称_父车辆名称_当前轨迹名称_照片类型_序号_角度.jpg
            "${moduleInfo.projectName}_${moduleInfo.vehicleName}_${moduleInfo.trackName}_${getPhotoTypeCode(photoType)}_${photoNumber}_${safeAngle}°.jpg"
        }
    }
    
    // 打印调试信息
    android.util.Log.d("CameraScreen", "创建文件: $photoFileName, 角度: $safeAngle")
    
    // 创建照片文件
    val storageDir = context.getExternalFilesDir("Photos")
    // 确保目录存在
    storageDir?.mkdirs()
    return File(storageDir, photoFileName)
}

/**
 * 获取照片类型代码
 */
private fun getPhotoTypeCode(photoType: PhotoType): String {
    return when (photoType) {
        PhotoType.START_POINT -> "起始点"
        PhotoType.MIDDLE_POINT -> "中间点"
        PhotoType.MODEL_POINT -> "模型点" 
        PhotoType.TRANSITION_POINT -> "过渡点"
        PhotoType.END_POINT -> "结束点"
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
        PhotoType.TRANSITION_POINT -> "过渡点照片"
        PhotoType.END_POINT -> "结束点照片"
    }
}

/**
 * 获取默认照片类型
 */
private fun getDefaultPhotoType(moduleType: ModuleType): PhotoType {
    return when (moduleType) {
        ModuleType.TRACK -> PhotoType.START_POINT
        ModuleType.PROJECT, ModuleType.VEHICLE -> PhotoType.MODEL_POINT
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