package com.elon.camera_photo_system.presentation.project

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.elon.camera_photo_system.domain.model.Project
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
class ProjectViewModel @Inject constructor() : ViewModel() {
    private val _projectsState = MutableStateFlow(ProjectsState())
    val projectsState: StateFlow<ProjectsState> = _projectsState.asStateFlow()

    private val _projectState = MutableStateFlow(ProjectState())
    val projectState: StateFlow<ProjectState> = _projectState.asStateFlow()

    // 保存项目列表
    private val projectsList = mutableListOf<Project>()

    init {
        // 初始加载项目
        loadProjects()
    }

    fun loadProjects() {
        viewModelScope.launch {
            _projectsState.update { it.copy(isLoading = true, error = null) }
            try {
                // 从内存中获取现有项目列表
                _projectsState.update { it.copy(isLoading = false, projects = projectsList) }
            } catch (e: Exception) {
                _projectsState.update { it.copy(isLoading = false, error = e.message) }
            }
        }
    }

    fun loadProject(projectId: Long) {
        viewModelScope.launch {
            _projectState.update { it.copy(isLoading = true, error = null) }
            try {
                // 从内存中查找项目
                val project = projectsList.find { it.id == projectId }
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
                    id = UUID.randomUUID().mostSignificantBits and Long.MAX_VALUE, // 生成随机ID
                    name = name,
                    description = description,
                    vehicleCount = 0,
                    photoCount = 0,
                    creationDate = LocalDateTime.now()
                )
                
                // 添加到项目列表
                projectsList.add(newProject)
                
                // 更新状态
                _projectsState.update { it.copy(
                    isLoading = false, 
                    projects = projectsList.toList()
                ) }
                
                // TODO: 实际项目中应该将项目保存到数据库
            } catch (e: Exception) {
                _projectsState.update { it.copy(
                    isLoading = false, 
                    error = "创建项目失败: ${e.message}"
                ) }
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