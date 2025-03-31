package com.elon.camera_photo_system.presentation.project

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.elon.camera_photo_system.domain.model.Project
import com.elon.camera_photo_system.domain.repository.ProjectRepository
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
    private val projectRepository: ProjectRepository
) : ViewModel() {
    private val _projectsState = MutableStateFlow(ProjectsState())
    val projectsState: StateFlow<ProjectsState> = _projectsState.asStateFlow()

    private val _projectState = MutableStateFlow(ProjectState())
    val projectState: StateFlow<ProjectState> = _projectState.asStateFlow()

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