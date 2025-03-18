package com.example.cameraapp.data

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.example.cameraapp.domain.repository.CameraRepository
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.suspendCancellableCoroutine
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.Executor
import javax.inject.Inject
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class CameraRepositoryImpl @Inject constructor(
    private val context: Context
) : CameraRepository {
    
    private var lensFacing = CameraSelector.LENS_FACING_BACK
    private var imageCapture: ImageCapture? = null
    private lateinit var cameraExecutor: Executor
    
    override fun initCamera(
        lifecycleOwner: LifecycleOwner,
        previewView: PreviewView,
        lensFacing: Int
    ): Flow<ProcessCameraProvider?> = callbackFlow {
        this@CameraRepositoryImpl.lensFacing = lensFacing
        
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        cameraExecutor = ContextCompat.getMainExecutor(context)
        
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()
            
            // 预览用例
            val preview = Preview.Builder().build()
            preview.setSurfaceProvider(previewView.surfaceProvider)
            
            // 图片捕获用例
            imageCapture = ImageCapture.Builder()
                .setCaptureMode(ImageCapture.CAPTURE_MODE_MAXIMIZE_QUALITY)
                .build()
            
            try {
                // 解绑所有用例
                cameraProvider.unbindAll()
                
                // 绑定用例到相机
                val cameraSelector = CameraSelector.Builder()
                    .requireLensFacing(this@CameraRepositoryImpl.lensFacing)
                    .build()
                
                cameraProvider.bindToLifecycle(
                    lifecycleOwner,
                    cameraSelector,
                    preview,
                    imageCapture
                )
                
                trySend(cameraProvider)
            } catch (e: Exception) {
                Log.e(TAG, "相机绑定失败", e)
                trySend(null)
            }
        }, cameraExecutor)
        
        awaitClose {
            cameraExecutor.run {  }
        }
    }
    
    override suspend fun takePhoto(context: Context): Flow<Uri?> = callbackFlow {
        val imageCapture = imageCapture ?: run {
            trySend(null)
            close()
            return@callbackFlow
        }
        
        // 创建用于存储图像的MediaStore内容
        val name = SimpleDateFormat(FILENAME_FORMAT, Locale.getDefault())
            .format(System.currentTimeMillis())
        
        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
            if (Build.VERSION.SDK_INT > Build.VERSION_CODES.P) {
                put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/CameraApp")
            }
        }
        
        // 创建输出选项对象
        val outputOptions = ImageCapture.OutputFileOptions
            .Builder(context.contentResolver,
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                contentValues)
            .build()
        
        // 设置图像捕获监听器
        imageCapture.takePicture(
            outputOptions,
            cameraExecutor,
            object : ImageCapture.OnImageSavedCallback {
                override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
                    val savedUri = outputFileResults.savedUri
                    trySend(savedUri)
                    close()
                }
                
                override fun onError(exception: ImageCaptureException) {
                    Log.e(TAG, "照片捕获失败: ${exception.message}", exception)
                    trySend(null)
                    close()
                }
            }
        )
        
        awaitClose {  }
    }
    
    override fun toggleCamera(preview: Preview) {
        lensFacing = if (lensFacing == CameraSelector.LENS_FACING_BACK) {
            CameraSelector.LENS_FACING_FRONT
        } else {
            CameraSelector.LENS_FACING_BACK
        }
    }
    
    override fun getCurrentLensFacing(): Int {
        return lensFacing
    }
    
    companion object {
        private const val TAG = "CameraRepositoryImpl"
        private const val FILENAME_FORMAT = "yyyy-MM-dd-HH-mm-ss-SSS"
    }
} 