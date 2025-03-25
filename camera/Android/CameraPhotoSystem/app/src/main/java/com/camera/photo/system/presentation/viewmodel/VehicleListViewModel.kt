package com.camera.photo.system.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.camera.photo.system.domain.repository.VehicleRepository
import com.camera.photo.system.presentation.state.VehicleListState
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
 * 车辆列表ViewModel
 */
@HiltViewModel
class VehicleListViewModel @Inject constructor(
    private val vehicleRepository: VehicleRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(VehicleListState())
    val uiState: StateFlow<VehicleListState> = _uiState.asStateFlow()
    
    /**
     * 加载项目的车辆列表
     */
    fun loadVehicles(projectId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null, projectId = projectId) }
            
            vehicleRepository.getVehiclesByProjectId(projectId)
                .catch { e ->
                    _uiState.update { 
                        it.copy(
                            isLoading = false,
                            error = e.message ?: "加载车辆失败"
                        )
                    }
                }
                .collectLatest { vehicles ->
                    _uiState.update { 
                        it.copy(
                            vehicles = vehicles,
                            isLoading = false,
                            error = null
                        )
                    }
                }
        }
    }
    
    /**
     * 刷新车辆列表
     */
    fun refreshVehicles() {
        val projectId = _uiState.value.projectId
        if (projectId.isNotEmpty()) {
            loadVehicles(projectId)
        }
    }
} 