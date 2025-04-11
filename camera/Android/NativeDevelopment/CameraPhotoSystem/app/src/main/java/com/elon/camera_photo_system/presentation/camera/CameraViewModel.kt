package com.elon.camera_photo_system.presentation.camera

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.PhotoType
import com.elon.camera_photo_system.domain.repository.PhotoRepository
import com.elon.camera_photo_system.domain.repository.ProjectRepository
import com.elon.camera_photo_system.domain.repository.TrackRepository
import com.elon.camera_photo_system.domain.repository.VehicleRepository
import com.elon.camera_photo_system.domain.usecase.photo.SavePhotoUseCase
import com.elon.camera_photo_system.domain.usecase.photo.UploadPhotoUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 相机ViewModel
 */
@HiltViewModel
class CameraViewModel @Inject constructor(
    private val savePhotoUseCase: SavePhotoUseCase,
    private val uploadPhotoUseCase: UploadPhotoUseCase,
    private val photoRepository: PhotoRepository,
    private val projectRepository: ProjectRepository,
    private val vehicleRepository: VehicleRepository,
    private val trackRepository: TrackRepository
) : ViewModel() {
    
    private val _cameraUIState = MutableStateFlow(CameraUIState())
    val cameraUIState: StateFlow<CameraUIState> = _cameraUIState.asStateFlow()
    
    // 模块信息
    private val _moduleInfo = MutableStateFlow(ModuleInfo())
    val moduleInfo: StateFlow<ModuleInfo> = _moduleInfo.asStateFlow()
    
    /**
     * 加载模块信息
     */
    fun loadModuleInfo(moduleId: Long, moduleType: ModuleType) {
        viewModelScope.launch {
            try {
                when (moduleType) {
                    ModuleType.PROJECT -> {
                        // 对于项目，只需加载项目名称
                        val project = projectRepository.getProjectById(moduleId)
                        project?.let {
                            _moduleInfo.update { info ->
                                info.copy(
                                    projectName = project.name,
                                    projectId = project.id
                                )
                            }
                        }
                    }
                    ModuleType.VEHICLE -> {
                        // 对于车辆，需要加载车辆名称和所属项目名称
                        val vehicle = vehicleRepository.getVehicleById(moduleId).firstOrNull()
                        vehicle?.let {
                            val project = projectRepository.getProjectById(vehicle.projectId)
                            _moduleInfo.update { info ->
                                info.copy(
                                    projectName = project?.name ?: "",
                                    projectId = project?.id ?: 0,
                                    vehicleName = vehicle.name,
                                    vehicleId = vehicle.id
                                )
                            }
                        }
                    }
                    ModuleType.TRACK -> {
                        // 对于轨迹，需要加载轨迹名称、所属车辆名称和所属项目名称
                        val track = trackRepository.getTrackById(moduleId).firstOrNull()
                        track?.let {
                            val vehicle = vehicleRepository.getVehicleById(track.vehicleId).firstOrNull()
                            vehicle?.let {
                                val project = projectRepository.getProjectById(vehicle.projectId)
                                _moduleInfo.update { info ->
                                    info.copy(
                                        projectName = project?.name ?: "",
                                        projectId = project?.id ?: 0,
                                        vehicleName = vehicle.name,
                                        vehicleId = vehicle.id,
                                        trackName = track.name,
                                        trackId = track.id
                                    )
                                }
                            }
                        }
                    }
                }
                
                // 加载照片计数
                loadPhotoCount(moduleId, moduleType)
                
            } catch (e: Exception) {
                // 处理错误
                _cameraUIState.update { it.copy(error = "加载模块信息失败: ${e.message}") }
            }
        }
    }
    
    /**
     * 加载照片计数
     */
    private fun loadPhotoCount(moduleId: Long, moduleType: ModuleType) {
        viewModelScope.launch {
            try {
                val photos = photoRepository.getPhotosByModule(moduleId, moduleType).first()
                
                // 根据照片类型更新计数
                val startPointCount = photos.count { it.photoType == PhotoType.START_POINT }
                val middlePointCount = photos.count { it.photoType == PhotoType.MIDDLE_POINT }
                val modelPointCount = photos.count { it.photoType == PhotoType.MODEL_POINT }
                val endPointCount = photos.count { it.photoType == PhotoType.END_POINT }
                
                _moduleInfo.update { info ->
                    info.copy(
                        startPointPhotoCount = startPointCount,
                        middlePointPhotoCount = middlePointCount,
                        modelPointPhotoCount = modelPointCount,
                        endPointPhotoCount = endPointCount
                    )
                }
            } catch (e: Exception) {
                _cameraUIState.update { it.copy(error = "加载照片计数失败: ${e.message}") }
            }
        }
    }
    
    /**
     * 获取照片序号
     */
    fun getNextPhotoNumber(photoType: PhotoType): Int {
        return when (photoType) {
            PhotoType.START_POINT -> _moduleInfo.value.startPointPhotoCount + 1
            PhotoType.MIDDLE_POINT -> _moduleInfo.value.middlePointPhotoCount + 1
            PhotoType.MODEL_POINT -> _moduleInfo.value.modelPointPhotoCount + 1
            PhotoType.END_POINT -> _moduleInfo.value.endPointPhotoCount + 1
        }
    }
    
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
                
                // 更新照片计数
                loadPhotoCount(moduleId, moduleType)
                
                // 不再自动上传
                // uploadPhoto(photoId)
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
    fun uploadPhoto(photoId: Long) {
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

/**
 * 模块信息
 */
data class ModuleInfo(
    val projectName: String = "",
    val projectId: Long = 0,
    val vehicleName: String = "",
    val vehicleId: Long = 0,
    val trackName: String = "",
    val trackId: Long = 0,
    val startPointPhotoCount: Int = 0,
    val middlePointPhotoCount: Int = 0,
    val modelPointPhotoCount: Int = 0,
    val endPointPhotoCount: Int = 0
) 