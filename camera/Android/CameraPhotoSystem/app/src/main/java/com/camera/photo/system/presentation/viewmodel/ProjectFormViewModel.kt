package com.camera.photo.system.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.camera.photo.system.domain.entity.Project
import com.camera.photo.system.domain.usecase.project.CreateProjectUseCase
import com.camera.photo.system.presentation.state.ProjectFormState
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 项目表单ViewModel
 */
@HiltViewModel
class ProjectFormViewModel @Inject constructor(
    private val createProjectUseCase: CreateProjectUseCase
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(ProjectFormState())
    val uiState: StateFlow<ProjectFormState> = _uiState.asStateFlow()
    
    /**
     * 更新项目名称
     */
    fun updateName(name: String) {
        _uiState.update { it.copy(name = name, nameError = null) }
    }
    
    /**
     * 更新项目描述
     */
    fun updateDescription(description: String) {
        _uiState.update { it.copy(description = description, descriptionError = null) }
    }
    
    /**
     * 验证表单
     * @return 是否验证通过
     */
    private fun validateForm(): Boolean {
        var isValid = true
        
        if (_uiState.value.name.isBlank()) {
            _uiState.update { it.copy(nameError = "项目名称不能为空") }
            isValid = false
        }
        
        if (_uiState.value.description.isBlank()) {
            _uiState.update { it.copy(descriptionError = "项目描述不能为空") }
            isValid = false
        }
        
        return isValid
    }
    
    /**
     * 创建项目
     */
    fun createProject() {
        if (!validateForm()) {
            return
        }
        
        viewModelScope.launch {
            _uiState.update { it.copy(isSubmitting = true, generalError = null) }
            
            try {
                val project = createProjectUseCase.execute(
                    name = _uiState.value.name,
                    description = _uiState.value.description
                )
                _uiState.update { 
                    it.copy(
                        isSubmitting = false,
                        isSuccess = true
                    )
                }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(
                        isSubmitting = false,
                        generalError = e.message ?: "创建项目失败"
                    )
                }
            }
        }
    }
    
    /**
     * 重置表单
     */
    fun resetForm() {
        _uiState.update { ProjectFormState() }
    }
} 