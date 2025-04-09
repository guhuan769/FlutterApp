package com.elon.camera_photo_system.data.repository

import com.elon.camera_photo_system.data.local.dao.VehicleDao
import com.elon.camera_photo_system.data.mapper.VehicleMapper.toDomain
import com.elon.camera_photo_system.data.mapper.VehicleMapper.toEntity
import com.elon.camera_photo_system.domain.model.Vehicle
import com.elon.camera_photo_system.domain.repository.VehicleRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import javax.inject.Inject

/**
 * 车辆仓库实现类
 */
class VehicleRepositoryImpl @Inject constructor(
    private val vehicleDao: VehicleDao
) : VehicleRepository {
    
    override fun getVehiclesByProject(projectId: Long): Flow<List<Vehicle>> {
        return vehicleDao.getVehiclesByProject(projectId)
            .map { vehicles -> vehicles.map { it.toDomain() } }
    }
    
    override fun getVehicleById(vehicleId: Long): Flow<Vehicle?> {
        return vehicleDao.getVehicleById(vehicleId)
            .map { it?.toDomain() }
    }
    
    override suspend fun addVehicle(vehicle: Vehicle): Long {
        return vehicleDao.insert(vehicle.toEntity())
    }
    
    override suspend fun updateVehicle(vehicle: Vehicle) {
        vehicleDao.update(vehicle.toEntity())
    }
    
    override suspend fun deleteVehicle(vehicle: Vehicle) {
        vehicleDao.delete(vehicle.toEntity())
    }
    
    override suspend fun deleteVehicle(vehicleId: Long) {
        val vehicle = getVehicleById(vehicleId).first()
        vehicle?.let { deleteVehicle(it) }
    }
} 