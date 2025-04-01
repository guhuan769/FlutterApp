package com.elon.camera_photo_system.presentation.camera

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.PhotoType
import com.elon.camera_photo_system.domain.usecase.photo.SavePhotoUseCase
import com.elon.camera_photo_system.domain.usecase.photo.UploadPhotoUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 相机ViewModel
 */
@HiltViewModel
class CameraViewModel @Inject constructor(
    private val savePhotoUseCase: SavePhotoUseCase,
    private val uploadPhotoUseCase: UploadPhotoUseCase
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
                _cameraUIState.update { it.copy(isSaving = true) }
                
                val photoId = savePhotoUseCase(
                    moduleId = moduleId,
                    moduleType = moduleType,
                    photoType = photoType,
                    filePath = filePath,
                    fileName = fileName
                )
                
                _cameraUIState.update { it.copy(
                    isSaving = false,
                    lastSavedPhotoId = photoId,
                    error = null
                )}
                
                // 保存成功后尝试上传
                uploadPhoto(photoId)
            } catch (e: Exception) {
                _cameraUIState.update { it.copy(
                    isSaving = false,
                    error = e.message ?: "保存照片失败"
                )}
            }
        }
    }
    
    /**
     * 上传照片
     *
     * @param photoId 照片ID
     */
    private fun uploadPhoto(photoId: Long) {
        viewModelScope.launch {
            try {
                _cameraUIState.update { it.copy(isUploading = true) }
                
                uploadPhotoUseCase(photoId).fold(
                    onSuccess = { success ->
                        _cameraUIState.update { it.copy(
                            isUploading = false,
                            isUploadSuccess = success,
                            uploadError = null
                        )}
                    },
                    onFailure = { exception ->
                        _cameraUIState.update { it.copy(
                            isUploading = false,
                            isUploadSuccess = false,
                            uploadError = exception.message ?: "上传照片失败"
                        )}
                    }
                )
            } catch (e: Exception) {
                _cameraUIState.update { it.copy(
                    isUploading = false,
                    isUploadSuccess = false,
                    uploadError = e.message ?: "上传照片失败"
                )}
            }
        }
    }
    
    /**
     * 清除错误
     */
    fun clearError() {
        _cameraUIState.update { it.copy(
            error = null,
            uploadError = null
        )}
    }
}

/**
 * 相机UI状态
 */
data class CameraUIState(
    val isSaving: Boolean = false,
    val lastSavedPhotoId: Long? = null,
    val error: String? = null,
    val isUploading: Boolean = false,
    val isUploadSuccess: Boolean = false,
    val uploadError: String? = null
) 