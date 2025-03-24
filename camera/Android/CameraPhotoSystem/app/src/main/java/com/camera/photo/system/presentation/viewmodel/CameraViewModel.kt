package com.camera.photo.system.presentation.viewmodel

import android.content.Context
import androidx.camera.core.CameraSelector
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.camera.photo.system.domain.model.Photo
import com.camera.photo.system.domain.model.PhotoType
import com.camera.photo.system.domain.usecase.InitCameraUseCase
import com.camera.photo.system.domain.usecase.TakePhotoUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 相机事件
 */
sealed class CameraEvent {
    data class ShowMessage(val message: String) : CameraEvent()
    data class PhotoCaptured(val photo: Photo) : CameraEvent()
    data class Error(val message: String) : CameraEvent()
    object CameraInitialized : CameraEvent()
}

/**
 * 相机UI状态
 */
data class CameraUiState(
    val isLoading: Boolean = false,
    val flashMode: Int = 0,
    val photoType: PhotoType = PhotoType.PROJECT_MODEL,
    val photos: List<Photo> = emptyList()
)

/**
 * 相机ViewModel
 */
@HiltViewModel
class CameraViewModel @Inject constructor(
    private val takePhotoUseCase: TakePhotoUseCase,
    private val initCameraUseCase: InitCameraUseCase
) : ViewModel() {
    
    // UI状态
    private val _uiState = MutableStateFlow(CameraUiState())
    val uiState: StateFlow<CameraUiState> = _uiState
    
    // 事件
    private val _events = MutableLiveData<CameraEvent>()
    val events: LiveData<CameraEvent> = _events
    
    /**
     * 初始化相机
     */
    fun initCamera(context: Context, cameraSelector: CameraSelector = CameraSelector.DEFAULT_BACK_CAMERA) {
        _uiState.value = _uiState.value.copy(isLoading = true)
        viewModelScope.launch {
            try {
                // 调用初始化相机用例
                val result = initCameraUseCase.execute(context, cameraSelector)
                result.fold(
                    onSuccess = {
                        // 发送初始化成功事件
                        _events.value = CameraEvent.CameraInitialized
                    },
                    onFailure = { error ->
                        // 发送错误事件
                        _events.value = CameraEvent.Error("相机初始化失败: ${error.message}")
                    }
                )
            } catch (e: Exception) {
                _events.value = CameraEvent.Error("相机初始化失败: ${e.message}")
            } finally {
                _uiState.value = _uiState.value.copy(isLoading = false)
            }
        }
    }
    
    /**
     * 拍照
     */
    fun takePhoto(photoType: PhotoType = PhotoType.PROJECT_MODEL) {
        _uiState.value = _uiState.value.copy(isLoading = true)
        viewModelScope.launch {
            try {
                // 调用用例执行拍照
                val result = takePhotoUseCase.execute(photoType)
                result.fold(
                    onSuccess = { photo ->
                        // 更新状态，添加新照片
                        val updatedPhotos = _uiState.value.photos + photo
                        _uiState.value = _uiState.value.copy(
                            photos = updatedPhotos,
                            isLoading = false
                        )
                        // 发送拍照成功事件
                        _events.value = CameraEvent.PhotoCaptured(photo)
                    },
                    onFailure = { error ->
                        // 发送错误事件
                        _events.value = CameraEvent.Error("拍照失败: ${error.message}")
                        _uiState.value = _uiState.value.copy(isLoading = false)
                    }
                )
            } catch (e: Exception) {
                // 发送错误事件
                _events.value = CameraEvent.Error("拍照失败: ${e.message}")
                _uiState.value = _uiState.value.copy(isLoading = false)
            }
        }
    }
    
    /**
     * 切换闪光灯模式
     */
    fun toggleFlashMode() {
        // 这里实现闪光灯模式切换逻辑
        // 暂时只是在几种模式间循环
        val currentMode = _uiState.value.flashMode
        val newMode = (currentMode + 1) % 3 // 假设有三种模式：0, 1, 2
        _uiState.value = _uiState.value.copy(flashMode = newMode)
        // 这里需要调用仓库方法设置实际闪光灯模式
    }
    
    /**
     * 设置照片类型
     */
    fun setPhotoType(photoType: PhotoType) {
        _uiState.value = _uiState.value.copy(photoType = photoType)
    }
} 