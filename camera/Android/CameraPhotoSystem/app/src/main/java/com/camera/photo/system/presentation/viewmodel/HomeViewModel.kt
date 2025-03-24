package com.camera.photo.system.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.camera.photo.system.domain.model.PhotoType
import com.camera.photo.system.domain.usecase.GetRecentPhotosUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 首页事件
 */
sealed class HomeEvent {
    data class NavigateToCamera(val photoType: PhotoType) : HomeEvent()
    object NavigateToGallery : HomeEvent()
    object NavigateToSettings : HomeEvent()
    data class ShowMessage(val message: String) : HomeEvent()
}

/**
 * 首页UI状态
 */
data class HomeUiState(
    val isLoading: Boolean = false,
    val recentPhotos: List<String> = emptyList(),
    val selectedPhotoType: PhotoType = PhotoType.PROJECT_MODEL
)

/**
 * 首页ViewModel
 */
@HiltViewModel
class HomeViewModel @Inject constructor(
    private val getRecentPhotosUseCase: GetRecentPhotosUseCase
) : ViewModel() {
    
    // UI状态
    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()
    
    // 事件流
    private val _events = MutableStateFlow<HomeEvent?>(null)
    val events: StateFlow<HomeEvent?> = _events.asStateFlow()
    
    init {
        // 初始化操作，例如加载最近照片
        loadRecentPhotos()
    }
    
    /**
     * 加载最近的照片
     */
    private fun loadRecentPhotos() {
        _uiState.value = _uiState.value.copy(isLoading = true)
        
        viewModelScope.launch {
            try {
                // 调用用例获取最近照片
                getRecentPhotosUseCase.execute(5).collect { photos ->
                    // 提取照片路径列表
                    val photoPaths = photos.map { it.path }
                    
                    // 更新UI状态
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        recentPhotos = photoPaths
                    )
                }
            } catch (e: Exception) {
                // 更新UI状态，显示错误
                _uiState.value = _uiState.value.copy(isLoading = false)
                _events.value = HomeEvent.ShowMessage("加载照片失败: ${e.message}")
            }
        }
    }
    
    /**
     * 设置选择的照片类型
     */
    fun setPhotoType(photoType: PhotoType) {
        _uiState.value = _uiState.value.copy(selectedPhotoType = photoType)
    }
    
    /**
     * 导航到相机
     */
    fun navigateToCamera(photoType: PhotoType = _uiState.value.selectedPhotoType) {
        _events.value = HomeEvent.NavigateToCamera(photoType)
    }
    
    /**
     * 导航到相册
     */
    fun navigateToGallery() {
        _events.value = HomeEvent.NavigateToGallery
    }
    
    /**
     * 导航到设置
     */
    fun navigateToSettings() {
        _events.value = HomeEvent.NavigateToSettings
    }
    
    /**
     * 清除事件
     */
    fun clearEvent() {
        _events.value = null
    }
} 