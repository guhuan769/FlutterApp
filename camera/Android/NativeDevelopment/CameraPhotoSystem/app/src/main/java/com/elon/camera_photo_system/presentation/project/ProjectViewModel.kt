package com.elon.camera_photo_system.presentation.project

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.elon.camera_photo_system.domain.model.Project
import com.elon.camera_photo_system.domain.repository.ProjectRepository
import com.elon.camera_photo_system.domain.usecase.project.UploadProjectPhotosUseCase
import com.elon.camera_photo_system.domain.usecase.project.UploadStatus
import com.elon.camera_photo_system.presentation.home.UploadState
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class ProjectViewModel @Inject constructor(
    private val projectRepository: ProjectRepository,
    private val uploadProjectPhotosUseCase: UploadProjectPhotosUseCase
) : ViewModel() {
    private val _projectsState = MutableStateFlow(ProjectsState())
    val projectsState: StateFlow<ProjectsState> = _projectsState.asStateFlow()

    private val _projectState = MutableStateFlow(ProjectState())
    val projectState: StateFlow<ProjectState> = _projectState.asStateFlow()
    
    private val _uploadState = MutableStateFlow(UploadState())
    val uploadState: StateFlow<UploadState> = _uploadState.asStateFlow()

    init {
        // 初始加载项目
        loadProjects()
    }

    fun loadProjects() {
        viewModelScope.launch {
            _projectsState.update { it.copy(isLoading = true, error = null) }
            try {
                // 从数据库加载项目列表
                val projects = projectRepository.getProjects()
                _projectsState.update { it.copy(isLoading = false, projects = projects) }
            } catch (e: Exception) {
                _projectsState.update { it.copy(isLoading = false, error = e.message) }
            }
        }
    }

    fun loadProject(projectId: Long) {
        viewModelScope.launch {
            _projectState.update { it.copy(isLoading = true, error = null) }
            try {
                // 从数据库加载单个项目
                val projects = projectRepository.getProjects()
                val project = projects.find { it.id == projectId }
                _projectState.update { it.copy(isLoading = false, project = project) }
            } catch (e: Exception) {
                _projectState.update { it.copy(isLoading = false, error = e.message) }
            }
        }
    }
    
    /**
     * 创建新项目
     */
    fun createProject(name: String, description: String = "") {
        viewModelScope.launch {
            _projectsState.update { it.copy(isLoading = true, error = null) }
            try {
                // 创建新项目对象
                val newProject = Project(
                    id = 0, // 自动生成ID
                    name = name,
                    description = description,
                    vehicleCount = 0,
                    photoCount = 0,
                    creationDate = LocalDateTime.now()
                )
                
                // 保存到数据库
                val projectId = projectRepository.addProject(newProject)
                
                // 重新加载项目列表以获取最新数据
                loadProjects()
                
            } catch (e: Exception) {
                _projectsState.update { it.copy(
                    isLoading = false, 
                    error = "创建项目失败: ${e.message}"
                ) }
            }
        }
    }
    
    /**
     * 上传项目照片
     */
    fun uploadProjectPhotos(project: Project) {
        viewModelScope.launch {
            try {
                // 清除之前的状态
                clearUploadState()
                
                _uploadState.update { 
                    it.copy(
                        isUploading = true, 
                        currentProject = project, 
                        error = null,
                        isSuccess = false
                    ) 
                }
                
                Log.d("ProjectViewModel", "开始上传项目照片: ${project.name}, ID: ${project.id}")
                
                // 强制重新上传所有照片，每次点击都会实际执行上传
                uploadProjectPhotosUseCase(project.id, forceReupload = true).fold(
                    onSuccess = { result ->
                        // 根据上传结果设置不同的提示信息
                        val (message, isSuccess) = when (result.status) {
                            UploadStatus.SUCCESS -> {
                                Pair(null, true) // 成功上传，无错误信息
                            }
                            UploadStatus.PARTIAL_SUCCESS -> {
                                Pair("部分照片上传失败", false)
                            }
                            UploadStatus.NO_PHOTOS -> {
                                Pair("此项目没有照片需要上传", false)
                            }
                            UploadStatus.ALREADY_UPLOADED -> {
                                Pair("此项目的照片已全部上传", true)
                            }
                        }
                        
                        _uploadState.update {
                            it.copy(
                                isUploading = false,
                                isSuccess = isSuccess,
                                error = message
                            )
                        }
                        
                        // 如果有实际上传操作，刷新项目数据
                        if (result.hasActualUploads) {
                            Log.d("ProjectViewModel", "上传操作完成，开始刷新项目数据")
                            refreshProject(project.id)
                        }
                        
                        // 设置自动清除消息的定时器
                        viewModelScope.launch {
                            kotlinx.coroutines.delay(3000) // 3秒后自动清除消息
                            clearUploadState()
                        }
                    },
                    onFailure = { ex ->
                        Log.e("ProjectViewModel", "上传项目照片失败", ex)
                        
                        // 网络错误处理
                        val errorMessage = when {
                            ex.message?.contains("无法连接到服务器") == true -> "无法连接到服务器，请检查网络设置"
                            ex.message?.contains("找不到服务器") == true -> "服务器地址错误，请检查设置"
                            ex.message?.contains("连接服务器超时") == true -> "连接服务器超时，请稍后重试"
                            ex.message?.contains("网络连接失败") == true -> "网络连接失败，请检查网络设置"
                            else -> "上传失败: ${ex.message}"
                        }
                        
                        _uploadState.update {
                            it.copy(
                                isUploading = false,
                                isSuccess = false,
                                error = errorMessage
                            )
                        }
                        
                        // 设置自动清除错误消息的定时器
                        viewModelScope.launch {
                            kotlinx.coroutines.delay(3000) // 3秒后自动清除错误消息
                            clearUploadState()
                        }
                    }
                )
            } catch (e: Exception) {
                Log.e("ProjectViewModel", "上传项目照片异常", e)
                _uploadState.update {
                    it.copy(
                        isUploading = false,
                        isSuccess = false,
                        error = "上传失败: ${e.message}"
                    )
                }
                
                // 设置自动清除错误消息的定时器
                viewModelScope.launch {
                    kotlinx.coroutines.delay(3000) // 3秒后自动清除错误消息
                    clearUploadState()
                }
            }
        }
    }
    
    /**
     * 刷新单个项目数据
     */
    private fun refreshProject(projectId: Long) {
        viewModelScope.launch {
            try {
                _projectState.update { it.copy(isLoading = true, error = null) }
                
                // 从数据库获取最新的项目信息
                val project = projectRepository.getProjectById(projectId)
                
                Log.d("ProjectViewModel", "刷新项目数据: ${project?.name}, 照片数: ${project?.photoCount}")
                
                project?.let {
                    _projectState.update {
                        it.copy(
                            project = project,
                            isLoading = false
                        )
                    }
                }
                
                // 同时刷新项目列表
                loadProjects()
            } catch (e: Exception) {
                Log.e("ProjectViewModel", "刷新项目数据失败", e)
                _projectState.update {
                    it.copy(
                        isLoading = false,
                        error = "加载项目详情失败: ${e.message}"
                    )
                }
            }
        }
    }
    
    /**
     * 清除上传状态
     */
    fun clearUploadState() {
        _uploadState.update { UploadState() }
    }

    fun deleteProject(project: Project) {
        viewModelScope.launch {
            try {
                projectRepository.deleteProject(project)
                loadProjects()
                Log.d("ProjectViewModel", "项目删除成功: ${project.name}")
            } catch (e: Exception) {
                Log.e("ProjectViewModel", "删除项目失败", e)
                _projectsState.update { 
                    it.copy(error = "删除项目失败: ${e.message}") 
                }
            }
        }
    }
}

data class ProjectsState(
    val projects: List<Project> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)

data class ProjectState(
    val project: Project? = null,
    val isLoading: Boolean = false,
    val error: String? = null
) 