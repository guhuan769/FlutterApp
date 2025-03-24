package com.camera.photo.system.domain.repository

import com.camera.photo.system.domain.entity.Track
import com.camera.photo.system.domain.entity.TrackPoint
import kotlinx.coroutines.flow.Flow

/**
 * 轨迹仓库接口
 * 定义轨迹相关的数据操作
 */
interface TrackRepository {
    /**
     * 创建新轨迹
     * @param track 轨迹信息
     * @return 创建的轨迹
     */
    suspend fun createTrack(track: Track): Track
    
    /**
     * 更新轨迹信息
     * @param track 更新后的轨迹信息
     * @return 更新后的轨迹
     */
    suspend fun updateTrack(track: Track): Track
    
    /**
     * 删除轨迹
     * @param id 轨迹ID
     * @return 是否删除成功
     */
    suspend fun deleteTrack(id: String): Boolean
    
    /**
     * 根据车辆ID获取轨迹列表
     * @param vehicleId 车辆ID
     * @return 轨迹列表流
     */
    fun getTracksByVehicleId(vehicleId: String): Flow<List<Track>>
    
    /**
     * 根据ID获取轨迹
     * @param id 轨迹ID
     * @return 轨迹信息，如不存在返回null
     */
    suspend fun getTrackById(id: String): Track?
    
    /**
     * 获取轨迹的所有点位
     * @param trackId 轨迹ID
     * @return 轨迹点位列表流
     */
    fun getTrackPoints(trackId: String): Flow<List<TrackPoint>>
    
    /**
     * 添加轨迹点位
     * @param trackPoint 轨迹点位信息
     * @return 添加的轨迹点位
     */
    suspend fun addTrackPoint(trackPoint: TrackPoint): TrackPoint
    
    /**
     * 删除轨迹点位
     * @param id 点位ID
     * @return 是否删除成功
     */
    suspend fun deleteTrackPoint(id: String): Boolean
} 