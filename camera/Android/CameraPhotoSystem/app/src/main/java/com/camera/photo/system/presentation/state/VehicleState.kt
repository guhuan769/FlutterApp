package com.camera.photo.system.presentation.state

import com.camera.photo.system.domain.entity.Vehicle

/**
 * 车辆列表UI状态
 */
data class VehicleListState(
    val vehicles: List<Vehicle> = emptyList(),
    val projectId: String = "",
    val isLoading: Boolean = false,
    val error: String? = null
)

/**
 * 车辆详情UI状态
 */
data class VehicleDetailState(
    val vehicle: Vehicle? = null,
    val isLoading: Boolean = false,
    val error: String? = null
)

/**
 * 车辆创建/编辑UI状态
 */
data class VehicleFormState(
    val projectId: String = "",
    val name: String = "",
    val licensePlate: String = "",
    val model: String = "",
    val isSubmitting: Boolean = false,
    val nameError: String? = null,
    val licensePlateError: String? = null,
    val modelError: String? = null,
    val generalError: String? = null,
    val isSuccess: Boolean = false
) 