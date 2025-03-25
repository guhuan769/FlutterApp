package com.camera.photo.system.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.camera.photo.system.domain.repository.TrackRepository
import com.camera.photo.system.presentation.state.TrackListState
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
 * 轨迹列表ViewModel
 */
@HiltViewModel
class TrackListViewModel @Inject constructor(
    private val trackRepository: TrackRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(TrackListState())
    val uiState: StateFlow<TrackListState> = _uiState.asStateFlow()
    
    /**
     * 加载车辆的轨迹列表
     */
    fun loadTracks(vehicleId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null, vehicleId = vehicleId) }
            
            trackRepository.getTracksByVehicleId(vehicleId)
                .catch { e ->
                    _uiState.update { 
                        it.copy(
                            isLoading = false,
                            error = e.message ?: "加载轨迹失败"
                        )
                    }
                }
                .collectLatest { tracks ->
                    _uiState.update { 
                        it.copy(
                            tracks = tracks,
                            isLoading = false,
                            error = null
                        )
                    }
                }
        }
    }
    
    /**
     * 刷新轨迹列表
     */
    fun refreshTracks() {
        val vehicleId = _uiState.value.vehicleId
        if (vehicleId.isNotEmpty()) {
            loadTracks(vehicleId)
        }
    }
} 