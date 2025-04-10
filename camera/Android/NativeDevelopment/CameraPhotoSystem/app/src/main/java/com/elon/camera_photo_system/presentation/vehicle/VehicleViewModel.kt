package com.elon.camera_photo_system.presentation.vehicle

import androidx.lifecycle.SavedStateHandle
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
    private val vehicleRepository: VehicleRepository,
    private val savedStateHandle: SavedStateHandle
) : ViewModel() {
    private val _vehiclesState = MutableStateFlow(VehiclesState())
    val vehiclesState: StateFlow<VehiclesState> = _vehiclesState.asStateFlow()

    private val _vehicleState = MutableStateFlow(VehicleState())
    val vehicleState: StateFlow<VehicleState> = _vehicleState.asStateFlow()
    
    private val _addVehicleState = MutableStateFlow(AddVehicleState())
    val addVehicleState: StateFlow<AddVehicleState> = _addVehicleState.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error = _error.asStateFlow()

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
        when (field) {
            AddVehicleField.NAME -> {
                _addVehicleState.update {
                    it.copy(
                        name = value,
                        nameError = if (value.isBlank()) "车辆名称不能为空" else null
                    )
                }
            }
            AddVehicleField.BRAND -> {
                _addVehicleState.update {
                    it.copy(brand = value)
                }
            }
            AddVehicleField.MODEL -> {
                _addVehicleState.update {
                    it.copy(model = value)
                }
            }
        }
    }
    
    fun validateAddVehicleForm(): Boolean {
        val state = _addVehicleState.value
        
        // 验证表单
        val nameValid = state.name.isNotBlank()
        
        // 更新字段错误状态
        _addVehicleState.update {
            it.copy(
                nameError = if (nameValid) null else "请输入车辆名称"
            )
        }
        
        return nameValid
    }
    
    fun addVehicle(projectId: Long) {
        val currentState = _addVehicleState.value
        
        // 验证
        if (currentState.name.isBlank()) {
            _addVehicleState.update {
                it.copy(nameError = "车辆名称不能为空")
            }
            return
        }
        
        _addVehicleState.update {
            it.copy(
                isSubmitting = true,
                error = null
            )
        }
        
        viewModelScope.launch {
            try {
                // 创建车辆对象
                val vehicle = Vehicle(
                    id = 0,
                    projectId = projectId,
                    name = currentState.name,
                    plateNumber = "", // 车牌号字段设为空
                    brand = currentState.brand,
                    model = currentState.model,
                    createdAt = LocalDateTime.now()
                )
                
                // 调用仓库添加车辆
                val vehicleId = vehicleRepository.addVehicle(vehicle)
                
                // 更新状态为成功
                _addVehicleState.update {
                    it.copy(
                        isSubmitting = false,
                        isSuccess = true,
                        createdVehicleId = vehicleId
                    )
                }
                
                // 重新加载车辆列表
                loadVehiclesByProject(projectId)
            } catch (e: Exception) {
                _addVehicleState.update {
                    it.copy(
                        isSubmitting = false,
                        error = "添加车辆失败: ${e.message}"
                    )
                }
            }
        }
    }
    
    fun resetAddVehicleState() {
        _addVehicleState.update {
            AddVehicleState()
        }
    }

    fun deleteVehicle(vehicle: Vehicle) {
        viewModelScope.launch {
            try {
                _isLoading.value = true
                vehicleRepository.deleteVehicle(vehicle.id)
                // 删除成功后刷新列表
                loadVehiclesByProject(vehicle.projectId)
            } catch (e: Exception) {
                _error.value = "删除车辆失败：${e.message}"
            } finally {
                _isLoading.value = false
            }
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

data class AddVehicleState(
    val name: String = "",
    val nameError: String? = null,
    val brand: String = "",
    val model: String = "",
    val isSubmitting: Boolean = false,
    val isSuccess: Boolean = false,
    val error: String? = null,
    val createdVehicleId: Long = -1L
)

enum class AddVehicleField {
    NAME, BRAND, MODEL
} 