package com.camera.photo.system.data.repository

import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.camera.photo.system.domain.model.Photo
import com.camera.photo.system.domain.model.PhotoType
import com.camera.photo.system.domain.repository.CameraRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import java.io.File
import java.util.Date
import java.util.UUID
import java.util.concurrent.Executor
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

private const val TAG = "CameraRepositoryImpl"

/**
 * 相机仓库实现类
 */
@Singleton
class CameraRepositoryImpl @Inject constructor(
    private val executor: Executor,
    private val context: Context
) : CameraRepository {
    
    private var imageCapture: ImageCapture? = null
    private var preview: Preview? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private val previewFrameData = MutableSharedFlow<ByteArray>(replay = 0)
    
    /**
     * 初始化相机
     */
    override suspend fun initCamera(
        context: Context,
        cameraSelector: CameraSelector
    ) = withContext(Dispatchers.Main) {
        try {
            cameraProvider = suspendCancellableCoroutine { continuation ->
                val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
                cameraProviderFuture.addListener({
                    try {
                        val provider = cameraProviderFuture.get()
                        // 配置相机用例
                        imageCapture = ImageCapture.Builder()
                            .setCaptureMode(ImageCapture.CAPTURE_MODE_MAXIMIZE_QUALITY)
                            .build()
                        
                        preview = Preview.Builder().build()
                        
                        // 释放之前的绑定
                        provider.unbindAll()
                        
                        // 绑定生命周期和相机用例
                        provider.bindToLifecycle(
                            context as LifecycleOwner,
                            cameraSelector,
                            preview,
                            imageCapture
                        )
                        
                        continuation.resume(provider)
                    } catch (e: Exception) {
                        Log.e(TAG, "相机初始化失败: ${e.message}")
                        continuation.resumeWithException(e)
                    }
                }, ContextCompat.getMainExecutor(context))
            }
        } catch (e: Exception) {
            Log.e(TAG, "相机初始化失败: ${e.message}")
            throw e
        }
    }
    
    /**
     * 拍照并保存图片
     */
    override suspend fun takePhoto(fileName: String?): Photo = suspendCancellableCoroutine { continuation ->
        val imageCapture = imageCapture ?: throw IllegalStateException("相机未初始化，请先调用initCamera方法")
        
        // 创建时间戳
        val timestamp = System.currentTimeMillis()
        
        // 图片名称
        val name = fileName ?: "CPS_${timestamp}_${UUID.randomUUID().toString().substring(0, 8)}.jpg"
        
        // 创建MediaStore内容
        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.MediaColumns.RELATIVE_PATH, "Pictures/CameraPhotoSystem")
            }
        }
        
        // 输出选项
        val outputOptions = ImageCapture.OutputFileOptions.Builder(
            context.contentResolver,
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            contentValues
        ).build()
        
        // 拍照
        imageCapture.takePicture(
            outputOptions,
            executor,
            object : ImageCapture.OnImageSavedCallback {
                override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
                    val savedUri = outputFileResults.savedUri ?: throw IllegalStateException("保存图片失败：URI为空")
                    val path = savedUri.toString()
                    val photo = Photo(
                        id = UUID.randomUUID().toString(),
                        path = path,
                        timestamp = Date(timestamp),
                        type = PhotoType.PROJECT_MODEL // 默认为项目模型照片，实际使用时需要传入
                    )
                    continuation.resume(photo)
                }
                
                override fun onError(exception: ImageCaptureException) {
                    Log.e(TAG, "拍照失败: ${exception.message}", exception)
                    continuation.resumeWithException(exception)
                }
            }
        )
    }
    
    /**
     * 获取所有已保存的照片
     */
    override fun getAllPhotos(): Flow<List<Photo>> = flow {
        // 这里应该实现从本地存储或数据库获取所有照片的逻辑
        emit(emptyList()) // 暂时返回空列表，需要实现实际逻辑
    }
    
    /**
     * 根据类型获取照片
     */
    override fun getPhotosByType(type: String): Flow<List<Photo>> = flow {
        // 这里应该实现从本地存储或数据库获取指定类型照片的逻辑
        emit(emptyList()) // 暂时返回空列表，需要实现实际逻辑
    }
    
    /**
     * 删除照片
     */
    override suspend fun deletePhoto(photo: Photo): Boolean = withContext(Dispatchers.IO) {
        try {
            // 实现删除照片的逻辑
            val file = File(photo.path)
            if (file.exists()) {
                file.delete()
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "删除照片失败: ${e.message}")
            false
        }
    }
    
    /**
     * 获取相机支持的最大分辨率
     */
    override suspend fun getMaxResolution(): Pair<Int, Int> = withContext(Dispatchers.IO) {
        // 这里应该实现获取相机最大分辨率的逻辑
        Pair(3840, 2160) // 默认4K分辨率，需要实现实际逻辑
    }
    
    /**
     * 设置相机闪光灯模式
     */
    override suspend fun setFlashMode(flashMode: Int) = withContext(Dispatchers.Main) {
        imageCapture?.flashMode = flashMode
    }
    
    /**
     * 获取相机预览帧数据
     */
    override fun getPreviewFrameData(): Flow<ByteArray> = previewFrameData
} 