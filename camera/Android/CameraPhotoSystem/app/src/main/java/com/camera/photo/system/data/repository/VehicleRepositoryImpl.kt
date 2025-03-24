package com.camera.photo.system.data.repository

import android.content.Context
import com.camera.photo.system.domain.entity.Track
import com.camera.photo.system.domain.entity.Vehicle
import com.camera.photo.system.domain.repository.VehicleRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 车辆仓库实现
 * 目前使用内存存储，后续可扩展为使用Room数据库
 */
@Singleton
class VehicleRepositoryImpl @Inject constructor(
    private val context: Context,
    private val projectRepository: ProjectRepositoryImpl
) : VehicleRepository {
    
    // 内存缓存的车辆列表
    private val vehicles = MutableStateFlow<List<Vehicle>>(emptyList())
    
    // 车辆与轨迹的关联映射
    private val vehicleTracks = mutableMapOf<String, MutableStateFlow<List<Track>>>()
    
    override suspend fun createVehicle(vehicle: Vehicle): Vehicle {
        val currentVehicles = vehicles.value.toMutableList()
        currentVehicles.add(vehicle)
        vehicles.value = currentVehicles
        
        // 初始化车辆的轨迹列表
        vehicleTracks[vehicle.id] = MutableStateFlow(emptyList())
        
        // 更新项目-车辆关联
        projectRepository.addVehicleToProject(vehicle)
        
        return vehicle
    }
    
    override suspend fun updateVehicle(vehicle: Vehicle): Vehicle {
        val currentVehicles = vehicles.value.toMutableList()
        val index = currentVehicles.indexOfFirst { it.id == vehicle.id }
        if (index != -1) {
            currentVehicles[index] = vehicle
            vehicles.value = currentVehicles
            
            // 更新项目-车辆关联
            projectRepository.updateVehicleInProject(vehicle)
        }
        return vehicle
    }
    
    override suspend fun deleteVehicle(id: String): Boolean {
        val vehicle = vehicles.value.find { it.id == id }
        if (vehicle != null) {
            val currentVehicles = vehicles.value.toMutableList()
            val removed = currentVehicles.removeIf { it.id == id }
            if (removed) {
                vehicles.value = currentVehicles
                
                // 移除车辆-轨迹关联
                vehicleTracks.remove(id)
                
                // 更新项目-车辆关联
                projectRepository.removeVehicleFromProject(id, vehicle.projectId)
                
                return true
            }
        }
        return false
    }
    
    override fun getVehiclesByProjectId(projectId: String): Flow<List<Vehicle>> {
        return projectRepository.getVehiclesByProjectId(projectId)
    }
    
    override suspend fun getVehicleById(id: String): Vehicle? {
        return vehicles.value.find { it.id == id }
    }
    
    override fun getTracksByVehicleId(vehicleId: String): Flow<List<Track>> {
        // 确保车辆轨迹列表已初始化
        if (!vehicleTracks.containsKey(vehicleId)) {
            vehicleTracks[vehicleId] = MutableStateFlow(emptyList())
        }
        return vehicleTracks[vehicleId]!!.asStateFlow()
    }
    
    // 内部方法，供TrackRepositoryImpl调用
    internal fun addTrackToVehicle(track: Track) {
        val vehicleId = track.vehicleId
        if (!vehicleTracks.containsKey(vehicleId)) {
            vehicleTracks[vehicleId] = MutableStateFlow(emptyList())
        }
        
        val currentTracks = vehicleTracks[vehicleId]!!.value.toMutableList()
        currentTracks.add(track)
        vehicleTracks[vehicleId]!!.value = currentTracks
    }
    
    internal fun updateTrackInVehicle(track: Track) {
        val vehicleId = track.vehicleId
        if (vehicleTracks.containsKey(vehicleId)) {
            val currentTracks = vehicleTracks[vehicleId]!!.value.toMutableList()
            val index = currentTracks.indexOfFirst { it.id == track.id }
            if (index != -1) {
                currentTracks[index] = track
                vehicleTracks[vehicleId]!!.value = currentTracks
            }
        }
    }
    
    internal fun removeTrackFromVehicle(trackId: String, vehicleId: String) {
        if (vehicleTracks.containsKey(vehicleId)) {
            val currentTracks = vehicleTracks[vehicleId]!!.value.toMutableList()
            val removed = currentTracks.removeIf { it.id == trackId }
            if (removed) {
                vehicleTracks[vehicleId]!!.value = currentTracks
            }
        }
    }
} 