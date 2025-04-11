package com.elon.camera_photo_system.presentation.gallery

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.model.PhotoType
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
    
    // 当前查看的模块类型
    private val _currentModuleType = MutableStateFlow(ModuleType.PROJECT)
    val currentModuleType: StateFlow<ModuleType> = _currentModuleType.asStateFlow()
    
    /**
     * 加载模块照片
     *
     * @param moduleId 模块ID
     * @param moduleType 模块类型
     */
    fun loadModulePhotos(moduleId: Long, moduleType: ModuleType) {
        viewModelScope.launch {
            try {
                _currentModuleType.value = moduleType
                _galleryUIState.update { it.copy(isLoading = true, error = null) }
                
                getPhotosByModuleUseCase(moduleId, moduleType).collect { photos ->
                    // 根据照片类型和序号排序
                    val sortedPhotos = when (moduleType) {
                        ModuleType.PROJECT, ModuleType.VEHICLE -> {
                            // 项目和车辆照片按照序号排序
                            photos.sortedWith(compareBy(
                                { it.photoType }, // 先按照照片类型排序
                                { extractPhotoNumber(it.fileName) } // 再按照序号排序
                            ))
                        }
                        ModuleType.TRACK -> {
                            // 轨迹照片按照类型和序号排序
                            photos.sortedWith(compareBy(
                                { getPhotoTypeOrder(it.photoType) }, // 先按照照片类型的顺序排序（起始点->中间点->过渡点->结束点）
                                { extractPhotoNumber(it.fileName) } // 再按照序号排序
                            ))
                        }
                    }
                    
                    // 按照照片类型分组
                    val photosByType = sortedPhotos.groupBy { it.photoType }
                    
                    _galleryUIState.update { 
                        it.copy(
                            isLoading = false,
                            photos = sortedPhotos,
                            photosByType = photosByType
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
     * 从文件名中提取照片序号
     */
    private fun extractPhotoNumber(fileName: String): Int {
        // 文件名格式: 项目名称_照片类型_序号_角度.jpg 或 
        // 项目名称_车辆名称_照片类型_序号_角度.jpg 或
        // 项目名称_车辆名称_轨迹名称_照片类型_序号_角度.jpg
        try {
            // 尝试从文件名中提取序号
            val parts = fileName.split("_")
            // 序号部分可能在不同位置，需要寻找数字部分
            for (i in 2 until parts.size) {
                if (parts[i].all { it.isDigit() }) {
                    return parts[i].toIntOrNull() ?: 0
                }
            }
            return 0
        } catch (e: Exception) {
            return 0
        }
    }
    
    /**
     * 获取照片类型的排序顺序
     */
    private fun getPhotoTypeOrder(photoType: PhotoType): Int {
        return when (photoType) {
            PhotoType.START_POINT -> 0
            PhotoType.MIDDLE_POINT -> 1
            PhotoType.MODEL_POINT -> 2
            PhotoType.END_POINT -> 3
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
                        photos = it.photos.filter { p -> p.id != photo.id },
                        photosByType = it.photosByType.mapValues { entry -> 
                            entry.value.filter { p -> p.id != photo.id } 
                        }
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
    val photosByType: Map<PhotoType, List<Photo>> = emptyMap(),
    val error: String? = null
)