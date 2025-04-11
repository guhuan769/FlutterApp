package com.elon.camera_photo_system.presentation.home

import android.util.Log
import androidx.compose.runtime.State
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.elon.camera_photo_system.data.util.UploadService
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.model.Project
import com.elon.camera_photo_system.domain.model.upload.ModelType
import com.elon.camera_photo_system.domain.model.upload.ProcessType
import com.elon.camera_photo_system.domain.model.upload.UploadPhotoType
import com.elon.camera_photo_system.domain.repository.ModelTypeRepository
import com.elon.camera_photo_system.domain.repository.PhotoRepository
import com.elon.camera_photo_system.domain.repository.ProcessTypeRepository
import com.elon.camera_photo_system.domain.repository.ProjectRepository
import com.elon.camera_photo_system.domain.repository.VehicleRepository
import com.elon.camera_photo_system.domain.repository.TrackRepository
import com.elon.camera_photo_system.domain.usecase.project.UploadProgressListener
import com.elon.camera_photo_system.domain.usecase.project.UploadProjectPhotosUseCase
import com.elon.camera_photo_system.presentation.home.state.UploadState
import com.elon.camera_photo_system.presentation.navigation.NavRoute
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.stateIn
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
    private val uploadService: UploadService,
    private val modelTypeRepository: ModelTypeRepository,
    private val processTypeRepository: ProcessTypeRepository,
    private val uploadProjectPhotosUseCase: UploadProjectPhotosUseCase,
    private val vehicleRepository: VehicleRepository,
    private val trackRepository: TrackRepository
) : ViewModel() {
    // 项目列表数据
    private val _projectsState = MutableStateFlow(ProjectsState())
    val projectsState: StateFlow<ProjectsState> = _projectsState.asStateFlow()
    
    // 搜索相关状态
    private val _searchText = MutableStateFlow("")
    val searchText: StateFlow<String> = _searchText.asStateFlow()
    
    private val _isSearchActive = MutableStateFlow(false)
    val isSearchActive: StateFlow<Boolean> = _isSearchActive.asStateFlow()
    
    // 当前选中的项目
    private val _selectedProject = mutableStateOf<Project?>(null)
    val selectedProject: State<Project?> = _selectedProject
    
    // 上传状态
    private val _uploadState = MutableStateFlow(UploadState())
    val uploadState: StateFlow<UploadState> = _uploadState.asStateFlow()
    
    // 是否显示上传对话框
    private val _showUploadDialog = mutableStateOf(false)
    val showUploadDialog: State<Boolean> = _showUploadDialog
    
    // UI状态
    private val _uiState = MutableStateFlow(HomeScreenState())
    val uiState: StateFlow<HomeScreenState> = _uiState.asStateFlow()
    
    // 缓存模型类型和工艺类型
    private val _modelTypes = MutableStateFlow<List<ModelType>>(emptyList())
    val modelTypes: StateFlow<List<ModelType>> = _modelTypes.asStateFlow()
    
    private val _processTypes = MutableStateFlow<List<ProcessType>>(emptyList())
    val processTypes: StateFlow<List<ProcessType>> = _processTypes.asStateFlow()
    
    init {
        loadProjects()
        loadTypes()
    }
    
    /**
     * 加载所有项目
     */
    fun loadProjects() {
        viewModelScope.launch {
            _projectsState.update { it.copy(isLoading = true) }
            
            try {
                val projects = projectRepository.getAllProjects().first()
                _projectsState.update { 
                    it.copy(
                        projects = projects,
                        isLoading = false,
                        error = null
                    )
                }
            } catch (e: Exception) {
                _projectsState.update { 
                    it.copy(
                        isLoading = false,
                        error = "加载项目失败: ${e.message}"
                    )
                }
            }
        }
    }
    
    /**
     * 加载模型和工艺类型
     */
    private fun loadTypes() {
        viewModelScope.launch {
            try {
                // 确保默认类型存在
                modelTypeRepository.ensureDefaultModelTypeExists()
                processTypeRepository.ensureDefaultProcessTypeExists()
                
                // 加载模型类型
                modelTypeRepository.getAllModelTypes().collect { types ->
                    _modelTypes.value = types
                }
            } catch (e: Exception) {
                Log.e("HomeViewModel", "加载模型类型失败", e)
            }
        }
        
        viewModelScope.launch {
            try {
                // 加载工艺类型
                processTypeRepository.getAllProcessTypes().collect { types ->
                    _processTypes.value = types
                }
            } catch (e: Exception) {
                Log.e("HomeViewModel", "加载工艺类型失败", e)
            }
        }
    }
    
    /**
     * 设置上传照片类型和类型ID
     */
    fun setUploadPhotoType(uploadPhotoType: UploadPhotoType, uploadTypeId: String) {
        viewModelScope.launch {
            // 获取类型名称
            val typeName = try {
                when (uploadPhotoType) {
                    UploadPhotoType.MODEL -> {
                        modelTypeRepository.getModelTypeById(uploadTypeId)?.name ?: ""
                    }
                    UploadPhotoType.PROCESS -> {
                        processTypeRepository.getProcessTypeById(uploadTypeId)?.name ?: ""
                    }
                }
            } catch (e: Exception) {
                Log.e("HomeViewModel", "获取类型名称失败", e)
                ""
            }
            
            _uploadState.update { state ->
                state.copy(
                    selectedUploadPhotoType = uploadPhotoType.name,
                    selectedUploadTypeId = uploadTypeId,
                    selectedUploadTypeName = typeName
                )
            }
        }
    }
    
    /**
     * 创建新项目
     */
    fun createProject(name: String, description: String) {
        viewModelScope.launch {
            try {
                projectRepository.createProject(name, description)
                loadProjects() // 重新加载项目列表
            } catch (e: Exception) {
                _projectsState.update { 
                    it.copy(error = "创建项目失败: ${e.message}")
                }
            }
        }
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
     * 上传项目照片
     */
    fun uploadProjectPhotos(project: Project) {
        _selectedProject.value = project
        _showUploadDialog.value = true
        
        viewModelScope.launch {
            try {
                // 检查是否已选择上传类型
                val currentState = _uploadState.value
                if (currentState.selectedUploadPhotoType.isEmpty() || currentState.selectedUploadTypeId.isEmpty()) {
                    return@launch
                }
                
                // 初始化上传状态
                _uploadState.update { 
                    it.copy(
                        isUploading = true, 
                        currentProject = project, 
                        error = null,
                        isSuccess = false,
                        progress = 0f,
                        uploadedCount = 0,
                        totalCount = 0, // 初始化为0，后续会更新实际数量
                        currentModuleType = "",
                        currentModuleName = "",
                        projectPhotosCount = 0,
                        vehiclePhotosCount = 0,
                        trackPhotosCount = 0,
                        projectUploadedCount = 0,
                        vehicleUploadedCount = 0,
                        trackUploadedCount = 0
                    ) 
                }
                
                // 1. 获取项目照片
                val projectPhotos = photoRepository.getPhotosByModule(project.id, ModuleType.PROJECT).first()
                val uploadInfo = currentState.selectedUploadPhotoType to currentState.selectedUploadTypeId
                
                // 2. 使用上传服务上传照片，同时监听上传状态
                uploadService.uploadProjectPhotos(project.id, projectPhotos, uploadInfo)
                    .collect { state ->
                        _uploadState.value = state
                    }
                
            } catch (e: Exception) {
                _uploadState.update { 
                    it.copy(
                        isUploading = false,
                        error = "上传照片失败: ${e.message}"
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
                loadProjects() // 重新加载项目列表
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

data class ProjectsState(
    val projects: List<Project> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
) 