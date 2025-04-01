package com.elon.camera_photo_system.presentation.camera

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.PhotoType
import com.elon.camera_photo_system.domain.usecase.photo.SavePhotoUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 相机ViewModel
 */
@HiltViewModel
class CameraViewModel @Inject constructor(
    private val savePhotoUseCase: SavePhotoUseCase
) : ViewModel() {
    
    private val _cameraUIState = MutableStateFlow(CameraUIState())
    val cameraUIState: StateFlow<CameraUIState> = _cameraUIState.asStateFlow()
    
    /**
     * 保存照片
     *
     * @param moduleId 模块ID
     * @param moduleType 模块类型
     * @param photoType 照片类型
     * @param filePath 文件路径
     * @param fileName 文件名
     */
    fun savePhoto(
        moduleId: Long,
        moduleType: ModuleType,
        photoType: PhotoType,
        filePath: String,
        fileName: String
    ) {
        viewModelScope.launch {
            try {
                _cameraUIState.value = _cameraUIState.value.copy(isSaving = true)
                
                val photoId = savePhotoUseCase(
                    moduleId = moduleId,
                    moduleType = moduleType,
                    photoType = photoType,
                    filePath = filePath,
                    fileName = fileName
                )
                
                _cameraUIState.value = _cameraUIState.value.copy(
                    isSaving = false,
                    lastSavedPhotoId = photoId,
                    error = null
                )
            } catch (e: Exception) {
                _cameraUIState.value = _cameraUIState.value.copy(
                    isSaving = false,
                    error = e.message ?: "保存照片失败"
                )
            }
        }
    }
    
    /**
     * 清除错误
     */
    fun clearError() {
        _cameraUIState.value = _cameraUIState.value.copy(error = null)
    }
}

/**
 * 相机UI状态
 */
data class CameraUIState(
    val isSaving: Boolean = false,
    val lastSavedPhotoId: Long? = null,
    val error: String? = null
) 