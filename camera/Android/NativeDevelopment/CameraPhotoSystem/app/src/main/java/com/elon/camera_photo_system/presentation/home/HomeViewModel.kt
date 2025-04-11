package com.elon.camera_photo_system.presentation.home

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.model.Project
import com.elon.camera_photo_system.domain.repository.PhotoRepository
import com.elon.camera_photo_system.domain.repository.ProjectRepository
import com.elon.camera_photo_system.domain.repository.VehicleRepository
import com.elon.camera_photo_system.domain.repository.TrackRepository
import com.elon.camera_photo_system.domain.usecase.project.UploadProgressListener
import com.elon.camera_photo_system.domain.usecase.project.UploadProjectPhotosUseCase
import com.elon.camera_photo_system.presentation.home.state.UploadState
import com.elon.camera_photo_system.presentation.navigation.NavRoute
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 首页ViewModel
 * 管理项目列表和相关操作
 */
@HiltViewModel
class HomeViewModel @Inject constructor(
    private val projectRepository: ProjectRepository,
    private val photoRepository: PhotoRepository,
    private val uploadProjectPhotosUseCase: UploadProjectPhotosUseCase,
    private val vehicleRepository: VehicleRepository,
    private val trackRepository: TrackRepository
) : ViewModel() {
    // 项目列表数据
    private val _projects = MutableStateFlow<List<Project>>(emptyList())
    val projects: StateFlow<List<Project>> = _projects.asStateFlow()
    
    // 搜索相关状态
    private val _searchText = MutableStateFlow("")
    val searchText: StateFlow<String> = _searchText.asStateFlow()
    
    private val _isSearchActive = MutableStateFlow(false)
    val isSearchActive: StateFlow<Boolean> = _isSearchActive.asStateFlow()
    
    // 当前选中的项目
    private val _selectedProject = MutableStateFlow<Project?>(null)
    val selectedProject: StateFlow<Project?> = _selectedProject.asStateFlow()
    
    // 上传状态
    private val _uploadState = MutableStateFlow(UploadState())
    val uploadState: StateFlow<UploadState> = _uploadState.asStateFlow()
    
    // 是否显示上传对话框
    private val _showUploadDialog = MutableStateFlow(false)
    val showUploadDialog: StateFlow<Boolean> = _showUploadDialog.asStateFlow()
    
    // UI状态
    private val _uiState = MutableStateFlow(HomeScreenState())
    val uiState: StateFlow<HomeScreenState> = _uiState.asStateFlow()
    
    init {
        // 初始加载项目
        refresh()
    }
    
    /**
     * 刷新项目列表
     */
    fun refresh() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                val projects = projectRepository.getProjects()
                _projects.value = projects
                _uiState.update { it.copy(isLoading = false) }
            } catch (e: Exception) {
                _uiState.update { it.copy(isLoading = false, error = "加载项目失败: ${e.message}") }
            }
        }
    }
    
    /**
     * 添加新项目
     */
    fun addProject() {
        // 这里只触发UI事件，实际创建项目的逻辑在NavGraph中处理
        // 或者这里也可以实现创建项目的逻辑
    }
    
    /**
     * 设置搜索文本
     */
    fun setSearchText(text: String) {
        _searchText.value = text
    }
    
    /**
     * 设置搜索状态
     */
    fun setSearchActive(active: Boolean) {
        _isSearchActive.value = active
    }
    
    /**
     * 选择项目
     */
    fun selectProject(project: Project) {
        _selectedProject.value = project
    }
    
    /**
     * 显示/隐藏上传对话框
     */
    fun showUploadDialog(show: Boolean) {
        _showUploadDialog.value = show
    }
    
    /**
     * 项目模型拍照
     */
    fun takeModelPhoto(project: Project) {
        // 这里只触发UI事件，实际跳转在NavGraph中处理
    }
    
    /**
     * 打开项目相册
     */
    fun openGallery(project: Project) {
        // 这里只触发UI事件，实际跳转在NavGraph中处理
    }
    
    /**
     * 添加车辆
     */
    fun addVehicle(project: Project) {
        // 这里只触发UI事件，实际跳转在NavGraph中处理
    }
    
    /**
     * 上传项目
     */
    fun uploadProject(project: Project) {
        _selectedProject.value = project
        _showUploadDialog.value = true
        
        viewModelScope.launch {
            try {
                // 初始化上传状态
                _uploadState.update { 
                    it.copy(
                        isUploading = true, 
                        currentProject = project, 
                        error = null,
                        isSuccess = false,
                        progress = 0f,
                        uploadedCount = 0,
                        totalCount = 0 // 初始化为0，后续会更新实际数量
                    ) 
                }
                
                // 1. 获取所有照片类型的总数，包括项目、车辆和轨迹的照片
                val projectPhotos = photoRepository.getPhotosByModule(project.id, ModuleType.PROJECT).first()
                
                // 获取项目下所有车辆
                val vehicles = vehicleRepository.getVehiclesByProject(project.id).first()
                var vehiclePhotos = emptyList<Photo>()
                var trackPhotos = emptyList<Photo>()
                
                // 获取车辆照片
                vehicles.forEach { vehicle ->
                    // 获取车辆照片
                    val photos = photoRepository.getPhotosByModule(vehicle.id, ModuleType.VEHICLE).first()
                    vehiclePhotos = vehiclePhotos + photos
                    
                    // 获取车辆下所有轨迹的照片
                    val tracks = trackRepository.getTracksByVehicle(vehicle.id).first()
                    tracks.forEach { track ->
                        val trackPhotoList = photoRepository.getPhotosByModule(track.id, ModuleType.TRACK).first()
                        trackPhotos = trackPhotos + trackPhotoList
                    }
                }
                
                // 计算总数量
                val allPhotos = projectPhotos + vehiclePhotos + trackPhotos
                val totalPhotos = allPhotos.size
                
                // 更新总数量
                _uploadState.update {
                    it.copy(totalCount = totalPhotos)
                }
                
                Log.d("HomeViewModel", "照片总数: 项目(${projectPhotos.size}), 车辆(${vehiclePhotos.size}), 轨迹(${trackPhotos.size})")
                
                // 如果没有照片，直接标记为上传成功
                if (totalPhotos == 0) {
                    _uploadState.update {
                        it.copy(
                            isUploading = false,
                            isSuccess = true,
                            progress = 1f
                        )
                    }
                    return@launch
                }
                
                // 创建进度监听器
                var currentUploaded = 0
                var overallSuccess = true
                
                val progressListener = object : UploadProgressListener {
                    override fun onProgress(uploaded: Int, total: Int) {
                        currentUploaded = uploaded
                        
                        // 计算总体进度 - 基于所有照片的总数
                        val progress = if (totalPhotos > 0) {
                            uploaded.toFloat() / totalPhotos
                        } else {
                            0f
                        }
                        
                        // 更新状态
                        _uploadState.update {
                            it.copy(
                                progress = progress,
                                uploadedCount = uploaded,
                                totalCount = totalPhotos // 使用总照片数
                            )
                        }
                        
                        Log.d("HomeViewModel", "上传进度: $uploaded/$totalPhotos (${(progress * 100).toInt()}%)")
                    }
                }
                
                // 2. 上传项目照片
                if (projectPhotos.isNotEmpty()) {
                    Log.d("HomeViewModel", "开始上传项目照片: ${projectPhotos.size}张")
                    
                    // 逐个上传项目照片，保持原始文件名
                    for (photo in projectPhotos) {
                        try {
                            val result = photoRepository.uploadPhoto(photo)
                            if (result) {
                                currentUploaded++
                                progressListener.onProgress(currentUploaded, totalPhotos)
                            } else {
                                Log.e("HomeViewModel", "项目照片上传失败: ${photo.fileName}")
                                overallSuccess = false
                            }
                        } catch (e: Exception) {
                            Log.e("HomeViewModel", "项目照片上传异常: ${e.message}")
                            overallSuccess = false
                        }
                    }
                }
                
                // 3. 上传车辆照片
                if (vehiclePhotos.isNotEmpty()) {
                    Log.d("HomeViewModel", "开始上传车辆照片: ${vehiclePhotos.size}张")
                    
                    // 逐个上传车辆照片，保持原始文件名
                    for (photo in vehiclePhotos) {
                        try {
                            val result = photoRepository.uploadPhoto(photo)
                            if (result) {
                                currentUploaded++
                                progressListener.onProgress(currentUploaded, totalPhotos)
                            } else {
                                Log.e("HomeViewModel", "车辆照片上传失败: ${photo.fileName}")
                                overallSuccess = false
                            }
                        } catch (e: Exception) {
                            Log.e("HomeViewModel", "车辆照片上传异常: ${e.message}")
                            overallSuccess = false
                        }
                    }
                }
                
                // 4. 上传轨迹照片
                if (trackPhotos.isNotEmpty()) {
                    Log.d("HomeViewModel", "开始上传轨迹照片: ${trackPhotos.size}张")
                    
                    // 逐个上传轨迹照片，保持原始文件名
                    for (photo in trackPhotos) {
                        try {
                            val result = photoRepository.uploadPhoto(photo)
                            if (result) {
                                currentUploaded++
                                progressListener.onProgress(currentUploaded, totalPhotos)
                            } else {
                                Log.e("HomeViewModel", "轨迹照片上传失败: ${photo.fileName}")
                                overallSuccess = false
                            }
                        } catch (e: Exception) {
                            Log.e("HomeViewModel", "轨迹照片上传异常: ${e.message}")
                            overallSuccess = false
                        }
                    }
                }
                
                // 5. 更新最终状态
                _uploadState.update { 
                    it.copy(
                        isUploading = false,
                        isSuccess = overallSuccess,
                        error = if (!overallSuccess) "部分照片上传失败" else null,
                        progress = 1f,
                        uploadedCount = currentUploaded
                    )
                }
                
                // 刷新项目列表
                refresh()
                
            } catch (e: Exception) {
                Log.e("HomeViewModel", "上传过程中发生异常: ${e.message}", e)
                _uploadState.update { 
                    it.copy(
                        isUploading = false,
                        isSuccess = false,
                        error = "上传失败: ${e.message}"
                    )
                }
            }
        }
    }
    
    /**
     * 删除项目
     */
    fun deleteProject(project: Project) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            try {
                projectRepository.deleteProject(project)
                refresh() // 刷新项目列表
            } catch (e: Exception) {
                _uiState.update { it.copy(
                    isLoading = false,
                    error = "删除项目失败: ${e.message}"
                ) }
            }
        }
    }
    
    /**
     * 跳转到设置页面
     */
    fun navigateToSettings() {
        // 这里只触发UI事件，实际跳转在NavGraph中处理
    }
} 