package com.elon.camera_photo_system.presentation.vehicle

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.elon.camera_photo_system.domain.model.Vehicle
import com.elon.camera_photo_system.domain.repository.VehicleRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import javax.inject.Inject

@HiltViewModel
class VehicleViewModel @Inject constructor(
    private val vehicleRepository: VehicleRepository
) : ViewModel() {
    private val _vehiclesState = MutableStateFlow(VehiclesState())
    val vehiclesState: StateFlow<VehiclesState> = _vehiclesState.asStateFlow()

    private val _vehicleState = MutableStateFlow(VehicleState())
    val vehicleState: StateFlow<VehicleState> = _vehicleState.asStateFlow()
    
    private val _addVehicleState = MutableStateFlow(AddVehicleState())
    val addVehicleState: StateFlow<AddVehicleState> = _addVehicleState.asStateFlow()

    fun loadVehiclesByProject(projectId: Long) {
        vehicleRepository.getVehiclesByProject(projectId)
            .onStart { 
                _vehiclesState.update { it.copy(isLoading = true, error = null) }
            }
            .onEach { vehicles ->
                _vehiclesState.update { 
                    it.copy(vehicles = vehicles, isLoading = false) 
                }
            }
            .catch { e ->
                _vehiclesState.update { 
                    it.copy(error = e.message ?: "加载车辆失败", isLoading = false) 
                }
            }
            .launchIn(viewModelScope)
    }

    fun loadVehicle(vehicleId: Long) {
        vehicleRepository.getVehicleById(vehicleId)
            .onStart { 
                _vehicleState.update { it.copy(isLoading = true, error = null) }
            }
            .onEach { vehicle ->
                _vehicleState.update { 
                    it.copy(vehicle = vehicle, isLoading = false) 
                }
            }
            .catch { e ->
                _vehicleState.update { 
                    it.copy(error = e.message ?: "加载车辆详情失败", isLoading = false) 
                }
            }
            .launchIn(viewModelScope)
    }
    
    fun updateAddVehicleField(field: AddVehicleField, value: String) {
        _addVehicleState.update { state ->
            when (field) {
                AddVehicleField.NAME -> state.copy(name = value)
                AddVehicleField.PLATE_NUMBER -> state.copy(plateNumber = value)
                AddVehicleField.BRAND -> state.copy(brand = value)
                AddVehicleField.MODEL -> state.copy(model = value)
            }
        }
    }
    
    fun validateAddVehicleForm(): Boolean {
        val state = _addVehicleState.value
        
        // 验证表单
        val nameValid = state.name.isNotBlank()
        val plateNumberValid = state.plateNumber.isNotBlank()
        
        // 更新字段错误状态
        _addVehicleState.update {
            it.copy(
                nameError = if (nameValid) null else "请输入车辆名称",
                plateNumberError = if (plateNumberValid) null else "请输入车牌号"
            )
        }
        
        return nameValid && plateNumberValid
    }
    
    fun addVehicle(projectId: Long) {
        if (!validateAddVehicleForm()) {
            return
        }
        
        val state = _addVehicleState.value
        
        _addVehicleState.update { it.copy(isSubmitting = true) }
        
        viewModelScope.launch {
            try {
                val vehicle = Vehicle(
                    id = 0,
                    projectId = projectId,
                    name = state.name,
                    plateNumber = state.plateNumber,
                    brand = state.brand,
                    model = state.model,
                    creationDate = LocalDateTime.now()
                )
                
                val id = vehicleRepository.addVehicle(vehicle)
                
                // 重置表单状态
                _addVehicleState.update {
                    AddVehicleState(
                        isSubmitting = false,
                        isSuccess = true
                    )
                }
                
                // 重新加载车辆列表
                loadVehiclesByProject(projectId)
            } catch (e: Exception) {
                _addVehicleState.update {
                    it.copy(
                        isSubmitting = false,
                        error = e.message ?: "添加车辆失败"
                    )
                }
            }
        }
    }
    
    fun resetAddVehicleState() {
        _addVehicleState.update { AddVehicleState() }
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

data class AddVehicleState(
    val name: String = "",
    val nameError: String? = null,
    val plateNumber: String = "",
    val plateNumberError: String? = null,
    val brand: String = "",
    val model: String = "",
    val isSubmitting: Boolean = false,
    val isSuccess: Boolean = false,
    val error: String? = null
)

enum class AddVehicleField {
    NAME, PLATE_NUMBER, BRAND, MODEL
} 