package com.elon.camera_photo_system.presentation.camera

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.core.content.ContextCompat
import com.elon.camera_photo_system.presentation.camera.bluetooth.BluetoothSelfieStickManager
import com.elon.camera_photo_system.presentation.camera.components.*
import com.elon.camera_photo_system.presentation.camera.settings.CameraSettings
import kotlinx.coroutines.launch
import java.io.File
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.Executor

@Composable
fun CameraScreen(
    onImageCaptured: (File) -> Unit,
    onError: (String) -> Unit
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val scope = rememberCoroutineScope()
    val cameraSettings = remember { CameraSettings(context) }

    var showResolutionDialog by remember { mutableStateOf(false) }
    var showBluetoothDialog by remember { mutableStateOf(false) }
    var currentResolution by remember { mutableStateOf("1080p (1920x1080)") }

    // 从设置中读取配置
    val defaultResolution by cameraSettings.defaultResolution.collectAsState(initial = "1080p (1920x1080)")
    val enableBluetooth by cameraSettings.enableBluetooth.collectAsState(initial = true)
    val enableAutoFocus by cameraSettings.enableAutoFocus.collectAsState(initial = true)
    val enableGridLines by cameraSettings.enableGridLines.collectAsState(initial = true)

    // 蓝牙管理器
    val bluetoothManager = remember { BluetoothSelfieStickManager(context) }
    val isBluetoothConnected by bluetoothManager.isConnected.collectAsState()
    var isBluetoothScanning by remember { mutableStateOf(false) }
    var bluetoothDevices by remember { mutableStateOf(listOf<android.bluetooth.BluetoothDevice>()) }

    // 相机权限
    var hasCameraPermission by remember { mutableStateOf(false) }
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        hasCameraPermission = granted
    }

    // 检查相机权限
    LaunchedEffect(Unit) {
        hasCameraPermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED

        if (!hasCameraPermission) {
            permissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    // 相机预览
    var preview by remember { mutableStateOf<Preview?>(null) }
    var imageCapture by remember { mutableStateOf<ImageCapture?>(null) }

    // 初始化相机
    LaunchedEffect(hasCameraPermission, currentResolution) {
        if (hasCameraPermission) {
            val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
            cameraProviderFuture.addListener({
                val cameraProvider = cameraProviderFuture.get()
                preview = Preview.Builder()
                    .setResolutionSelector(cameraSettings.getResolutionSelector(currentResolution))
                    .build()
                imageCapture = cameraSettings.getImageCaptureBuilder(currentResolution).build()

                try {
                    cameraProvider.unbindAll()
                    cameraProvider.bindToLifecycle(
                        lifecycleOwner,
                        CameraSelector.DEFAULT_BACK_CAMERA,
                        preview,
                        imageCapture
                    )
                } catch (e: Exception) {
                    onError("相机初始化失败: ${e.message}")
                }
            }, ContextCompat.getMainExecutor(context))
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        // 相机预览
        preview?.let { 
            CameraPreview(
                preview = it,
                modifier = Modifier.fillMaxSize()
            )
        }

        // 十字准心
        if (enableGridLines) {
            CrosshairOverlay(
                modifier = Modifier.fillMaxSize()
            )
        }

        // 对焦覆盖层
        if (enableAutoFocus) {
            FocusOverlay(
                onFocusRequest = { /* TODO: 实现对焦功能 */ },
                modifier = Modifier.fillMaxSize()
            )
        }

        // 相机控制
        CameraControls(
            onCaptureClick = {
                scope.launch {
                    captureImage(
                        imageCapture = imageCapture,
                        context = context,
                        onImageCaptured = onImageCaptured,
                        onError = onError
                    )
                }
            },
            onResolutionClick = { showResolutionDialog = true },
            onBluetoothClick = { 
                if (enableBluetooth) {
                    showBluetoothDialog = true
                }
            },
            isBluetoothConnected = isBluetoothConnected && enableBluetooth,
            modifier = Modifier.fillMaxWidth()
        )

        // 分辨率选择对话框
        if (showResolutionDialog) {
            ResolutionDialog(
                onDismiss = { showResolutionDialog = false },
                onResolutionSelected = { resolution ->
                    scope.launch {
                        currentResolution = resolution
                        cameraSettings.setDefaultResolution(resolution)
                    }
                },
                currentResolution = currentResolution
            )
        }

        // 蓝牙设备选择对话框
        if (showBluetoothDialog && enableBluetooth) {
            BluetoothDeviceDialog(
                devices = bluetoothDevices,
                onDeviceSelected = { device ->
                    scope.launch {
                        bluetoothManager.connectToDevice(device)
                        showBluetoothDialog = false
                    }
                },
                onDismiss = { showBluetoothDialog = false },
                isScanning = isBluetoothScanning
            )
        }
    }
}

private suspend fun captureImage(
    imageCapture: ImageCapture?,
    context: android.content.Context,
    onImageCaptured: (File) -> Unit,
    onError: (String) -> Unit
) {
    imageCapture?.let { capture ->
        val photoFile = createImageFile(context)
        val outputOptions = ImageCapture.OutputFileOptions.Builder(photoFile).build()
        
        try {
            capture.takePicture(
                outputOptions,
                ContextCompat.getMainExecutor(context),
                object : ImageCapture.OnImageSavedCallback {
                    override fun onImageSaved(output: ImageCapture.OutputFileResults) {
                        onImageCaptured(photoFile)
                    }

                    override fun onError(exception: ImageCaptureException) {
                        onError("拍照失败: ${exception.message}")
                    }
                }
            )
        } catch (e: Exception) {
            onError("拍照失败: ${e.message}")
        }
    }
}

private fun createImageFile(context: android.content.Context): File {
    val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
    val storageDir = context.getExternalFilesDir(null)
    return File.createTempFile(
        "IMG_${timeStamp}_",
        ".jpg",
        storageDir
    )
} 