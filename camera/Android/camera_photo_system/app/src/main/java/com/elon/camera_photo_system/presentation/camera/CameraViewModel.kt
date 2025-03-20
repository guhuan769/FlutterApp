package com.elon.camera_photo_system.presentation.camera

import android.content.Context
import androidx.camera.view.PreviewView
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.elon.camera_photo_system.domain.model.FlashMode
import com.elon.camera_photo_system.domain.model.LensFacing
import com.elon.camera_photo_system.domain.model.PhotoType
import com.elon.camera_photo_system.domain.repository.CameraRepository
import com.elon.camera_photo_system.domain.usecase.GetCameraStateUseCase
import com.elon.camera_photo_system.domain.usecase.TakePhotoUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 相机界面状态
 */
data class CameraUiState(
    val isInitialized: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null,
    val flashMode: FlashMode = FlashMode.OFF,
    val lensFacing: LensFacing = LensFacing.BACK,
    val hasFlashUnit: Boolean = false,
    val isCapturing: Boolean = false,
    val zoomRatio: Float = 1.0f,
    val photoType: PhotoType = PhotoType.START_POINT,
    val projectId: Long? = null,
    val vehicleId: Long? = null,
    val routeId: Long? = null,
    val lastCapturedPhotoUri: String? = null
)

/**
 * 相机ViewModel，处理相机相关的业务逻辑
 */
@HiltViewModel
class CameraViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    private val getCameraStateUseCase: GetCameraStateUseCase,
    private val takePhotoUseCase: TakePhotoUseCase,
    private val cameraRepository: CameraRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(CameraUiState())
    val uiState: StateFlow<CameraUiState> = _uiState.asStateFlow()
    
    init {
        observeCameraState()
    }
    
    /**
     * 观察相机状态变化
     */
    private fun observeCameraState() {
        viewModelScope.launch {
            getCameraStateUseCase().collect { cameraState ->
                _uiState.update { currentState ->
                    currentState.copy(
                        isInitialized = cameraState.isInitialized,
                        flashMode = cameraState.flashMode,
                        lensFacing = cameraState.lensFacing,
                        hasFlashUnit = cameraState.hasFlashUnit,
                        isCapturing = cameraState.isCapturing,
                        zoomRatio = cameraState.zoomRatio
                    )
                }
            }
        }
    }
    
    /**
     * 初始化相机
     * @param previewView 预览视图
     */
    fun initCamera(previewView: PreviewView) {
        _uiState.update { it.copy(isLoading = true, error = null) }
        
        viewModelScope.launch {
            try {
                // 调用相机仓库进行实际初始化
                val isInitialized = cameraRepository.initCamera(context, previewView)
                
                _uiState.update { 
                    it.copy(
                        isLoading = false,
                        error = if (!isInitialized) "相机初始化失败" else null
                    )
                }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(
                        isLoading = false,
                        error = "相机初始化异常: ${e.message}"
                    )
                }
            }
        }
    }
    
    /**
     * 切换闪光灯模式
     */
    fun toggleFlashMode() {
        if (!_uiState.value.hasFlashUnit) return
        
        val currentMode = _uiState.value.flashMode
        val nextMode = when (currentMode) {
            FlashMode.AUTO -> FlashMode.ON
            FlashMode.ON -> FlashMode.OFF
            FlashMode.OFF -> FlashMode.AUTO
        }
        
        viewModelScope.launch {
            try {
                cameraRepository.setFlashMode(nextMode)
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(error = "切换闪光灯失败: ${e.message}")
                }
            }
        }
    }
    
    /**
     * 切换相机镜头
     */
    fun toggleCamera() {
        val currentFacing = _uiState.value.lensFacing
        val nextFacing = when (currentFacing) {
            LensFacing.BACK -> LensFacing.FRONT
            LensFacing.FRONT -> LensFacing.BACK
        }
        
        viewModelScope.launch {
            try {
                cameraRepository.switchCamera(nextFacing)
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(error = "切换相机失败: ${e.message}")
                }
            }
        }
    }
    
    /**
     * 拍照
     */
    fun takePhoto() {
        if (_uiState.value.isCapturing) return
        
        viewModelScope.launch {
            try {
                _uiState.update { it.copy(isCapturing = true, error = null) }
                
                val result = takePhotoUseCase(
                    type = _uiState.value.photoType,
                    projectId = _uiState.value.projectId,
                    vehicleId = _uiState.value.vehicleId,
                    routeId = _uiState.value.routeId
                )
                
                result.fold(
                    onSuccess = { photo ->
                        _uiState.update { 
                            it.copy(
                                isCapturing = false,
                                lastCapturedPhotoUri = photo.uri.toString()
                            )
                        }
                    },
                    onFailure = { error ->
                        _uiState.update { 
                            it.copy(
                                isCapturing = false,
                                error = "拍照失败: ${error.message}"
                            )
                        }
                    }
                )
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(
                        isCapturing = false,
                        error = "拍照异常: ${e.message}"
                    )
                }
            }
        }
    }
    
    /**
     * 设置照片类型
     * @param type 照片类型
     */
    fun setPhotoType(type: PhotoType) {
        _uiState.update { it.copy(photoType = type) }
    }
    
    /**
     * 设置项目ID
     * @param projectId 项目ID
     */
    fun setProjectId(projectId: Long?) {
        _uiState.update { it.copy(projectId = projectId) }
    }
    
    /**
     * 设置车辆ID
     * @param vehicleId 车辆ID
     */
    fun setVehicleId(vehicleId: Long?) {
        _uiState.update { it.copy(vehicleId = vehicleId) }
    }
    
    /**
     * 设置轨迹ID
     * @param routeId 轨迹ID
     */
    fun setRouteId(routeId: Long?) {
        _uiState.update { it.copy(routeId = routeId) }
    }
    
    /**
     * 缩放相机
     * @param scale 缩放比例
     */
    fun setZoomRatio(scale: Float) {
        viewModelScope.launch {
            try {
                cameraRepository.setZoomRatio(scale)
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(error = "设置缩放比例失败: ${e.message}")
                }
            }
        }
    }
    
    /**
     * 清除错误
     */
    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
    
    /**
     * 释放相机资源
     */
    fun releaseCamera() {
        viewModelScope.launch {
            try {
                cameraRepository.releaseCamera()
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "释放相机资源失败: ${e.message}") }
            }
        }
    }
    
    override fun onCleared() {
        super.onCleared()
        viewModelScope.launch {
            try {
                cameraRepository.releaseCamera()
            } catch (e: Exception) {
                // 无需处理，ViewModel已销毁
            }
        }
    }
} 