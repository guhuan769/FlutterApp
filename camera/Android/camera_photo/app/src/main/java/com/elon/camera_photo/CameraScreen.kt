package com.elon.camera_photo

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.Executor
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

@Composable
fun CameraScreen(
    onPhotoTaken: (Uri) -> Unit,
    onGalleryClick: () -> Unit
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    
    // 添加日志
    Log.d("CameraScreen", "初始化相机界面")
    
    val preview = remember { Preview.Builder().build() }
    val previewView = remember { PreviewView(context) }
    val imageCapture = remember { 
        ImageCapture.Builder()
            .setCaptureMode(ImageCapture.CAPTURE_MODE_MAXIMIZE_QUALITY) // 使用最高质量
            .build() 
    }
    val cameraSelector = remember { CameraSelector.DEFAULT_BACK_CAMERA }
    
    LaunchedEffect(Unit) {
        Log.d("CameraScreen", "开始绑定相机")
        try {
            val cameraProvider = context.getCameraProvider()
            cameraProvider.unbindAll()
            cameraProvider.bindToLifecycle(
                lifecycleOwner,
                cameraSelector,
                preview,
                imageCapture
            )
            
            preview.setSurfaceProvider(previewView.surfaceProvider)
            Log.d("CameraScreen", "相机绑定成功")
        } catch (e: Exception) {
            Log.e("CameraScreen", "相机绑定失败: ${e.message}", e)
            Toast.makeText(context, "相机初始化失败: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }
    
    Box(modifier = Modifier.fillMaxSize()) {
        AndroidView(
            factory = { previewView },
            modifier = Modifier.fillMaxSize()
        )
        
        // 中心点图标
        Icon(
            painter = painterResource(id = R.drawable.center_point),
            contentDescription = "Center Point",
            modifier = Modifier
                .size(48.dp)
                .align(Alignment.Center)
        )
        
        // 照片库按钮
        IconButton(
            onClick = onGalleryClick,
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(16.dp)
        ) {
            Icon(
                imageVector = Icons.Default.Menu,
                contentDescription = stringResource(R.string.gallery),
                modifier = Modifier.size(32.dp)
            )
        }
        
        // 拍照按钮
        Row(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 32.dp)
        ) {
            // 方法1：使用CameraX拍照
            Button(
                onClick = {
                    Log.d("CameraScreen", "点击CameraX拍照按钮")
                    takePhotoWithCameraX(
                        context = context,
                        imageCapture = imageCapture,
                        onPhotoTaken = onPhotoTaken
                    )
                }
            ) {
                Text(text = stringResource(R.string.take_photo))
            }
            
            Spacer(modifier = Modifier.width(16.dp))
            
            // 方法2：使用系统相机
            Button(
                onClick = {
                    Log.d("CameraScreen", "点击系统相机按钮")
                    takePhotoWithSystemCamera(context)
                }
            ) {
                Text(text = "系统相机")
            }
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Button(onClick = onGalleryClick) {
                Text(text = stringResource(R.string.view_gallery))
            }
        }
    }
}

// 方法1：使用CameraX拍照
private fun takePhotoWithCameraX(
    context: Context,
    imageCapture: ImageCapture,
    onPhotoTaken: (Uri) -> Unit
) {
    Log.d("CameraScreen", "开始使用CameraX拍照")
    try {
        // 创建ContentValues对象，用于MediaStore
        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, "IMG_${System.currentTimeMillis()}.jpg")
            put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
            // 对于Android 10及以上版本，指定保存到Pictures目录
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.MediaColumns.RELATIVE_PATH, "Pictures/CameraPhoto")
            }
        }
        
        // 创建输出选项，直接使用MediaStore
        val outputOptions = ImageCapture.OutputFileOptions.Builder(
            context.contentResolver,
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            contentValues
        ).build()
        
        // 拍照
        imageCapture.takePicture(
            outputOptions,
            ContextCompat.getMainExecutor(context),
            object : ImageCapture.OnImageSavedCallback {
                override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
                    Log.d("CameraScreen", "CameraX拍照成功")
                    
                    // 获取URI
                    val savedUri = outputFileResults.savedUri
                    if (savedUri != null) {
                        Log.d("CameraScreen", "保存的URI: $savedUri")
                        
                        // 通知系统图库更新
                        context.sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE).apply {
                            data = savedUri
                        })
                        
                        // 显示成功消息
                        Toast.makeText(
                            context,
                            "照片已保存到相册",
                            Toast.LENGTH_SHORT
                        ).show()
                        
                        // 回调
                        onPhotoTaken(savedUri)
                    } else {
                        Log.e("CameraScreen", "保存的URI为空")
                        Toast.makeText(
                            context,
                            "保存照片失败: URI为空",
                            Toast.LENGTH_LONG
                        ).show()
                    }
                }
                
                override fun onError(exception: ImageCaptureException) {
                    Log.e("CameraScreen", "CameraX拍照失败: ${exception.message}", exception)
                    Toast.makeText(
                        context,
                        "拍照失败: ${exception.message}",
                        Toast.LENGTH_LONG
                    ).show()
                }
            }
        )
    } catch (e: Exception) {
        Log.e("CameraScreen", "CameraX拍照过程中发生错误: ${e.message}", e)
        Toast.makeText(
            context,
            "拍照过程中发生错误: ${e.message}",
            Toast.LENGTH_LONG
        ).show()
    }
}

// 方法2：使用系统相机
private fun takePhotoWithSystemCamera(context: Context) {
    Log.d("CameraScreen", "开始使用系统相机拍照")
    try {
        val takePictureIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        if (takePictureIntent.resolveActivity(context.packageManager) != null) {
            context as ComponentActivity
            context.startActivityForResult(takePictureIntent, 1)
            Log.d("CameraScreen", "启动系统相机")
        } else {
            Log.e("CameraScreen", "没有可用的相机应用")
            Toast.makeText(context, "没有可用的相机应用", Toast.LENGTH_SHORT).show()
        }
    } catch (e: Exception) {
        Log.e("CameraScreen", "启动系统相机失败: ${e.message}", e)
        Toast.makeText(context, "启动系统相机失败: ${e.message}", Toast.LENGTH_SHORT).show()
    }
}

// 创建图片文件
private fun createImageFile(context: Context): File {
    // 创建图片文件名
    val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
    val imageFileName = "JPEG_${timeStamp}_"
    val storageDir = context.getExternalFilesDir(android.os.Environment.DIRECTORY_PICTURES)
    return File.createTempFile(
        imageFileName,
        ".jpg",
        storageDir
    )
}

suspend fun Context.getCameraProvider(): ProcessCameraProvider = suspendCoroutine { continuation ->
    ProcessCameraProvider.getInstance(this).also { future ->
        future.addListener(
            {
                continuation.resume(future.get())
            },
            ContextCompat.getMainExecutor(this)
        )
    }
} 