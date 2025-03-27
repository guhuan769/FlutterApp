package com.elon.camera_photo_system.presentation.vehicle

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.elon.camera_photo_system.domain.model.Vehicle
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class VehicleViewModel @Inject constructor() : ViewModel() {
    private val _vehiclesState = MutableStateFlow(VehiclesState())
    val vehiclesState: StateFlow<VehiclesState> = _vehiclesState.asStateFlow()

    private val _vehicleState = MutableStateFlow(VehicleState())
    val vehicleState: StateFlow<VehicleState> = _vehicleState.asStateFlow()

    fun loadVehiclesByProject(projectId: Long) {
        viewModelScope.launch {
            // TODO: 实现车辆列表加载逻辑
        }
    }

    fun loadVehicle(vehicleId: Long) {
        viewModelScope.launch {
            // TODO: 实现单个车辆加载逻辑
        }
    }
}

data class VehiclesState(
    val vehicles: List<Vehicle> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)

data class VehicleState(
    val vehicle: Vehicle? = null,
    val isLoading: Boolean = false,
    val error: String? = null
) 