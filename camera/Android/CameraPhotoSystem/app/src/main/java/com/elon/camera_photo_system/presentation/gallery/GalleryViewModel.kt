package com.elon.camera_photo_system.presentation.gallery

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.usecase.photo.DeletePhotoUseCase
import com.elon.camera_photo_system.domain.usecase.photo.GetPhotosByModuleUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 相册ViewModel
 */
@HiltViewModel
class GalleryViewModel @Inject constructor(
    private val getPhotosByModuleUseCase: GetPhotosByModuleUseCase,
    private val deletePhotoUseCase: DeletePhotoUseCase
) : ViewModel() {
    
    private val _galleryUIState = MutableStateFlow(GalleryUIState())
    val galleryUIState: StateFlow<GalleryUIState> = _galleryUIState.asStateFlow()
    
    /**
     * 加载模块照片
     *
     * @param moduleId 模块ID
     * @param moduleType 模块类型
     */
    fun loadModulePhotos(moduleId: Long, moduleType: ModuleType) {
        viewModelScope.launch {
            try {
                _galleryUIState.update { it.copy(isLoading = true, error = null) }
                
                getPhotosByModuleUseCase(moduleId, moduleType).collect { photos ->
                    _galleryUIState.update { 
                        it.copy(
                            isLoading = false,
                            photos = photos
                        )
                    }
                }
            } catch (e: Exception) {
                _galleryUIState.update { 
                    it.copy(
                        isLoading = false,
                        error = e.message ?: "加载照片失败"
                    )
                }
            }
        }
    }
    
    /**
     * 删除照片
     *
     * @param photo 要删除的照片
     */
    fun deletePhoto(photo: Photo) {
        viewModelScope.launch {
            try {
                _galleryUIState.update { it.copy(isDeleting = true, error = null) }
                
                deletePhotoUseCase(photo)
                
                _galleryUIState.update { 
                    it.copy(
                        isDeleting = false,
                        photos = it.photos.filter { p -> p.id != photo.id }
                    )
                }
            } catch (e: Exception) {
                _galleryUIState.update { 
                    it.copy(
                        isDeleting = false,
                        error = e.message ?: "删除照片失败"
                    )
                }
            }
        }
    }
    
    /**
     * 清除错误
     */
    fun clearError() {
        _galleryUIState.update { it.copy(error = null) }
    }
}

/**
 * 相册UI状态
 */
data class GalleryUIState(
    val isLoading: Boolean = false,
    val isDeleting: Boolean = false,
    val photos: List<Photo> = emptyList(),
    val error: String? = null
)