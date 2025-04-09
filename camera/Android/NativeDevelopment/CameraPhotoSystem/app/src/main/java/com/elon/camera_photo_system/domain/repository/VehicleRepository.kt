package com.elon.camera_photo_system.domain.repository

import com.elon.camera_photo_system.domain.model.Vehicle
import kotlinx.coroutines.flow.Flow

/**
 * 车辆仓库接口
 */
interface VehicleRepository {
    /**
     * 获取指定项目下的所有车辆
     */
    fun getVehiclesByProject(projectId: Long): Flow<List<Vehicle>>

    /**
     * 根据ID获取车辆
     */
    fun getVehicleById(vehicleId: Long): Flow<Vehicle?>

    /**
     * 添加车辆
     */
    suspend fun addVehicle(vehicle: Vehicle): Long

    /**
     * 更新车辆
     */
    suspend fun updateVehicle(vehicle: Vehicle)

    /**
     * 删除车辆
     */
    suspend fun deleteVehicle(vehicle: Vehicle)

    suspend fun deleteVehicle(vehicleId: Long)
} 