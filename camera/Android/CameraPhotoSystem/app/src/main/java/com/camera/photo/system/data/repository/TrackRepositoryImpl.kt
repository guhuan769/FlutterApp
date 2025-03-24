package com.camera.photo.system.data.repository

import android.content.Context
import com.camera.photo.system.domain.entity.Track
import com.camera.photo.system.domain.entity.TrackPoint
import com.camera.photo.system.domain.repository.TrackRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 轨迹仓库实现
 * 目前使用内存存储，后续可扩展为使用Room数据库
 */
@Singleton
class TrackRepositoryImpl @Inject constructor(
    private val context: Context,
    private val vehicleRepository: VehicleRepositoryImpl
) : TrackRepository {
    
    // 内存缓存的轨迹列表
    private val tracks = MutableStateFlow<List<Track>>(emptyList())
    
    // 轨迹与点位的关联映射
    private val trackPoints = mutableMapOf<String, MutableStateFlow<List<TrackPoint>>>()
    
    override suspend fun createTrack(track: Track): Track {
        val currentTracks = tracks.value.toMutableList()
        currentTracks.add(track)
        tracks.value = currentTracks
        
        // 初始化轨迹的点位列表
        trackPoints[track.id] = MutableStateFlow(emptyList())
        
        // 更新车辆-轨迹关联
        vehicleRepository.addTrackToVehicle(track)
        
        return track
    }
    
    override suspend fun updateTrack(track: Track): Track {
        val currentTracks = tracks.value.toMutableList()
        val index = currentTracks.indexOfFirst { it.id == track.id }
        if (index != -1) {
            currentTracks[index] = track
            tracks.value = currentTracks
            
            // 更新车辆-轨迹关联
            vehicleRepository.updateTrackInVehicle(track)
        }
        return track
    }
    
    override suspend fun deleteTrack(id: String): Boolean {
        val track = tracks.value.find { it.id == id }
        if (track != null) {
            val currentTracks = tracks.value.toMutableList()
            val removed = currentTracks.removeIf { it.id == id }
            if (removed) {
                tracks.value = currentTracks
                
                // 移除轨迹-点位关联
                trackPoints.remove(id)
                
                // 更新车辆-轨迹关联
                vehicleRepository.removeTrackFromVehicle(id, track.vehicleId)
                
                return true
            }
        }
        return false
    }
    
    override fun getTracksByVehicleId(vehicleId: String): Flow<List<Track>> {
        return vehicleRepository.getTracksByVehicleId(vehicleId)
    }
    
    override suspend fun getTrackById(id: String): Track? {
        return tracks.value.find { it.id == id }
    }
    
    override fun getTrackPoints(trackId: String): Flow<List<TrackPoint>> {
        // 确保轨迹点位列表已初始化
        if (!trackPoints.containsKey(trackId)) {
            trackPoints[trackId] = MutableStateFlow(emptyList())
        }
        return trackPoints[trackId]!!.asStateFlow()
    }
    
    override suspend fun addTrackPoint(trackPoint: TrackPoint): TrackPoint {
        val trackId = trackPoint.trackId
        
        // 确保轨迹点位列表已初始化
        if (!trackPoints.containsKey(trackId)) {
            trackPoints[trackId] = MutableStateFlow(emptyList())
        }
        
        val currentPoints = trackPoints[trackId]!!.value.toMutableList()
        currentPoints.add(trackPoint)
        trackPoints[trackId]!!.value = currentPoints
        
        return trackPoint
    }
    
    override suspend fun deleteTrackPoint(id: String): Boolean {
        for ((trackId, pointsFlow) in trackPoints) {
            val currentPoints = pointsFlow.value.toMutableList()
            val removed = currentPoints.removeIf { it.id == id }
            if (removed) {
                trackPoints[trackId]!!.value = currentPoints
                return true
            }
        }
        return false
    }
} 