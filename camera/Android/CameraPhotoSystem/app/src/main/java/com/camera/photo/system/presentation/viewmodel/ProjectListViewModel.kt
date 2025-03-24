package com.camera.photo.system.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.camera.photo.system.domain.usecase.project.GetProjectsUseCase
import com.camera.photo.system.presentation.state.ProjectListState
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 项目列表ViewModel
 */
@HiltViewModel
class ProjectListViewModel @Inject constructor(
    private val getProjectsUseCase: GetProjectsUseCase
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(ProjectListState())
    val uiState: StateFlow<ProjectListState> = _uiState.asStateFlow()
    
    init {
        loadProjects()
    }
    
    /**
     * 加载项目列表
     */
    fun loadProjects() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            
            getProjectsUseCase.execute()
                .catch { e ->
                    _uiState.update { 
                        it.copy(
                            isLoading = false,
                            error = e.message ?: "加载项目失败"
                        )
                    }
                }
                .collectLatest { projects ->
                    _uiState.update { 
                        it.copy(
                            projects = projects,
                            isLoading = false,
                            error = null
                        )
                    }
                }
        }
    }
    
    /**
     * 刷新项目列表
     */
    fun refreshProjects() {
        loadProjects()
    }
} 