package com.elon.camera_photo_system.domain.repository

import com.elon.camera_photo_system.domain.model.Track
import kotlinx.coroutines.flow.Flow

/**
 * 轨迹仓库接口
 */
interface TrackRepository {
    /**
     * 获取指定车辆下的所有轨迹
     */
    fun getTracksByVehicle(vehicleId: Long): Flow<List<Track>>

    /**
     * 根据ID获取轨迹
     */
    fun getTrackById(trackId: Long): Flow<Track?>

    /**
     * 添加轨迹
     */
    suspend fun addTrack(track: Track): Long

    /**
     * 更新轨迹
     */
    suspend fun updateTrack(track: Track)

    /**
     * 删除轨迹
     */
    suspend fun deleteTrack(track: Track)
    
    /**
     * 开始轨迹
     */
    suspend fun startTrack(trackId: Long)
    
    /**
     * 结束轨迹
     */
    suspend fun endTrack(trackId: Long)
    
    /**
     * 更新轨迹照片计数
     */
    suspend fun updateTrackPhotoCount(trackId: Long, 
                                      startPointCount: Int? = null,
                                      middlePointCount: Int? = null,
                                      modelPointCount: Int? = null,
                                      endPointCount: Int? = null)

    /**
     * 获取包含照片计数的轨迹
     */
    suspend fun getTrackWithPhotoCounts(trackId: Long): Track?
} 