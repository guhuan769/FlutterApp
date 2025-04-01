package com.elon.camera_photo_system.presentation.camera.components

import android.content.Context
import android.view.ViewGroup
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.gestures.*
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import kotlin.math.max
import kotlin.math.min

@Composable
fun CameraPreviewWithGestures(
    context: Context,
    lifecycleOwner: LifecycleOwner,
    onImageCaptureCreated: (ImageCapture) -> Unit,
    onCameraCreated: (Camera) -> Unit,
    onZoomChanged: (Float) -> Unit
) {
    val density = LocalDensity.current
    var camera: Camera? by remember { mutableStateOf(null) }
    var minZoom by remember { mutableStateOf(1f) }
    var maxZoom by remember { mutableStateOf(1f) }
    var currentZoom by remember { mutableStateOf(1f) }
    
    val cameraProviderFuture = remember { ProcessCameraProvider.getInstance(context) }
    
    AndroidView(
        factory = { ctx ->
            PreviewView(ctx).apply {
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
                implementationMode = PreviewView.ImplementationMode.PERFORMANCE
                scaleType = PreviewView.ScaleType.FILL_CENTER
            }.also { previewView ->
                cameraProviderFuture.addListener({
                    val cameraProvider = cameraProviderFuture.get()
                    val preview = Preview.Builder()
                        .build()
                        .also {
                            it.setSurfaceProvider(previewView.surfaceProvider)
                        }
                    
                    val imageCapture = ImageCapture.Builder()
                        .setCaptureMode(ImageCapture.CAPTURE_MODE_MAXIMIZE_QUALITY)
                        .build()
                    
                    val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
                    
                    try {
                        cameraProvider.unbindAll()
                        camera = cameraProvider.bindToLifecycle(
                            lifecycleOwner,
                            cameraSelector,
                            preview,
                            imageCapture
                        )
                        
                        // 获取相机缩放范围
                        camera?.let {
                            val zoomState = it.cameraInfo.zoomState.value
                            minZoom = zoomState?.minZoomRatio ?: 1f
                            maxZoom = zoomState?.maxZoomRatio ?: 1f
                            currentZoom = zoomState?.zoomRatio ?: 1f
                            onZoomChanged(currentZoom)
                        }
                        
                        onImageCaptureCreated(imageCapture)
                        onCameraCreated(camera!!)
                    } catch (ex: Exception) {
                        ex.printStackTrace()
                    }
                }, ContextCompat.getMainExecutor(ctx))
            }
        },
        modifier = Modifier
            .fillMaxSize()
            .pointerInput(Unit) {
                // 双指缩放手势
                detectTransformGestures { _, _, zoom, _ ->
                    currentZoom = (currentZoom * zoom).coerceIn(minZoom, maxZoom)
                    camera?.cameraControl?.setZoomRatio(currentZoom)
                    onZoomChanged(currentZoom)
                }
            }
    )
} 