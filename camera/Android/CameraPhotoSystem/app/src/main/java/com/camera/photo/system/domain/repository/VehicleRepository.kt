package com.camera.photo.system.domain.repository

import com.camera.photo.system.domain.entity.Track
import com.camera.photo.system.domain.entity.Vehicle
import kotlinx.coroutines.flow.Flow

/**
 * 车辆仓库接口
 * 定义车辆相关的数据操作
 */
interface VehicleRepository {
    /**
     * 创建新车辆
     * @param vehicle 车辆信息
     * @return 创建的车辆
     */
    suspend fun createVehicle(vehicle: Vehicle): Vehicle
    
    /**
     * 更新车辆信息
     * @param vehicle 更新后的车辆信息
     * @return 更新后的车辆
     */
    suspend fun updateVehicle(vehicle: Vehicle): Vehicle
    
    /**
     * 删除车辆
     * @param id 车辆ID
     * @return 是否删除成功
     */
    suspend fun deleteVehicle(id: String): Boolean
    
    /**
     * 根据项目ID获取车辆列表
     * @param projectId 项目ID
     * @return 车辆列表流
     */
    fun getVehiclesByProjectId(projectId: String): Flow<List<Vehicle>>
    
    /**
     * 根据ID获取车辆
     * @param id 车辆ID
     * @return 车辆信息，如不存在返回null
     */
    suspend fun getVehicleById(id: String): Vehicle?
    
    /**
     * 获取车辆下的所有轨迹
     * @param vehicleId 车辆ID
     * @return 轨迹列表流
     */
    fun getTracksByVehicleId(vehicleId: String): Flow<List<Track>>
} 