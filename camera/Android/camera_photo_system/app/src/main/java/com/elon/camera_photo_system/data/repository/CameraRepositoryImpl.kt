package com.elon.camera_photo_system.data.repository

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
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.elon.camera_photo_system.domain.model.CameraState
import com.elon.camera_photo_system.domain.model.FlashMode
import com.elon.camera_photo_system.domain.model.LensFacing
import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.model.PhotoType
import com.elon.camera_photo_system.domain.repository.CameraRepository
import com.elon.camera_photo_system.domain.repository.PhotoRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.concurrent.Executor
import javax.inject.Inject
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

private const val TAG = "CameraRepositoryImpl"
private const val FILENAME_FORMAT = "yyyy-MM-dd-HH-mm-ss-SSS"

class CameraRepositoryImpl @Inject constructor(
    private val context: Context,
    private val photoRepository: PhotoRepository
) : CameraRepository {
    
    private val cameraExecutor: Executor by lazy { ContextCompat.getMainExecutor(context) }
    private var imageCapture: ImageCapture? = null
    private var cameraProvider: ProcessCameraProvider? = null
    
    private val _cameraState = MutableStateFlow(CameraState())
    
    override fun getCameraState(): Flow<CameraState> = _cameraState.asStateFlow()
    
    override suspend fun initCamera(context: Context, previewView: PreviewView): Boolean = withContext(Dispatchers.Main) {
        return@withContext try {
            val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
            cameraProvider = suspendCoroutine { continuation ->
                cameraProviderFuture.addListener({
                    try {
                        val provider = cameraProviderFuture.get()
                        continuation.resume(provider)
                    } catch (e: Exception) {
                        Log.e(TAG, "相机初始化失败: ${e.message}")
                        continuation.resumeWithException(e)
                    }
                }, cameraExecutor)
            }
            
            // 设置分辨率选择器，使用最高质量
            val resolutionSelector = ResolutionSelector.Builder()
                .setResolutionStrategy(ResolutionStrategy.HIGHEST_AVAILABLE_STRATEGY)
                .build()
            
            // 创建预览用例
            val preview = Preview.Builder()
                .setResolutionSelector(resolutionSelector)
                .build()
                .also {
                    it.setSurfaceProvider(previewView.surfaceProvider)
                }
            
            // 创建拍照用例
            imageCapture = ImageCapture.Builder()
                .setResolutionSelector(resolutionSelector)
                .setCaptureMode(ImageCapture.CAPTURE_MODE_MAXIMIZE_QUALITY)
                .build()
            
            // 选择后置摄像头
            val cameraSelector = when (_cameraState.value.lensFacing) {
                LensFacing.BACK -> CameraSelector.DEFAULT_BACK_CAMERA
                LensFacing.FRONT -> CameraSelector.DEFAULT_FRONT_CAMERA
            }
            
            // 绑定用例到相机
            cameraProvider?.unbindAll()
            val camera = cameraProvider?.bindToLifecycle(
                context as LifecycleOwner,
                cameraSelector,
                preview,
                imageCapture
            )
            
            // 检查是否有闪光灯
            val hasFlashUnit = camera?.cameraInfo?.hasFlashUnit() ?: false
            _cameraState.value = _cameraState.value.copy(
                hasFlashUnit = hasFlashUnit,
                isInitialized = true
            )
            
            true
        } catch (e: Exception) {
            Log.e(TAG, "相机绑定失败: ${e.message}")
            false
        }
    }
    
    override suspend fun setFlashMode(flashMode: FlashMode) {
        if (!_cameraState.value.hasFlashUnit) return
        
        val imageCaptureFlashMode = when (flashMode) {
            FlashMode.AUTO -> ImageCapture.FLASH_MODE_AUTO
            FlashMode.ON -> ImageCapture.FLASH_MODE_ON
            FlashMode.OFF -> ImageCapture.FLASH_MODE_OFF
        }
        
        imageCapture?.flashMode = imageCaptureFlashMode
        _cameraState.value = _cameraState.value.copy(flashMode = flashMode)
    }
    
    override suspend fun switchCamera(lensFacing: LensFacing) {
        _cameraState.value = _cameraState.value.copy(lensFacing = lensFacing)
        // 需要重新初始化相机
        // 这里简化处理，实际应用中需要保存previewView重新初始化
    }
    
    override suspend fun takePhoto(
        type: PhotoType,
        projectId: Long?,
        vehicleId: Long?,
        routeId: Long?
    ): Photo? = withContext(Dispatchers.IO) {
        val imageCapture = imageCapture ?: return@withContext null
        
        _cameraState.value = _cameraState.value.copy(isCapturing = true)
        
        try {
            // 获取下一个序号
            val sequence = photoRepository.getNextSequence(type, projectId, vehicleId, routeId)
            val name = PhotoType.generateFileName(type, sequence)
            
            // 创建MediaStore条目
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, name)
                put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/CameraPhotoSystem")
                }
            }
            
            val outputOptions = ImageCapture.OutputFileOptions.Builder(
                context.contentResolver,
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                contentValues
            ).build()
            
            val photoUri = suspendCoroutine { continuation ->
                imageCapture.takePicture(
                    outputOptions,
                    cameraExecutor,
                    object : ImageCapture.OnImageSavedCallback {
                        override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
                            outputFileResults.savedUri?.let {
                                Log.d(TAG, "照片保存成功: $it")
                                continuation.resume(it)
                            } ?: continuation.resumeWithException(Exception("未能获取保存的图片URI"))
                        }
                        
                        override fun onError(exception: ImageCaptureException) {
                            Log.e(TAG, "照片保存失败: ${exception.message}", exception)
                            continuation.resumeWithException(exception)
                        }
                    }
                )
            }
            
            // 保存照片元数据到数据库
            val photo = photoRepository.savePhoto(photoUri, type, projectId, vehicleId, routeId)
            _cameraState.value = _cameraState.value.copy(isCapturing = false)
            return@withContext photo
            
        } catch (e: Exception) {
            Log.e(TAG, "拍照失败: ${e.message}")
            _cameraState.value = _cameraState.value.copy(isCapturing = false)
            return@withContext null
        }
    }
    
    override suspend fun setZoomRatio(zoomRatio: Float) {
        _cameraState.value = _cameraState.value.copy(zoomRatio = zoomRatio)
        // 实际应用中需要调用camera.cameraControl.setZoomRatio(zoomRatio)
    }
    
    override suspend fun releaseCamera() {
        cameraProvider?.unbindAll()
        imageCapture = null
        _cameraState.value = _cameraState.value.copy(isInitialized = false)
    }
} 