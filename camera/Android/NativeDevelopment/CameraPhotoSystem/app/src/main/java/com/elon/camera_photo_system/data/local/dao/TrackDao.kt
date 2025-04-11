package com.elon.camera_photo_system.data.local.dao

import androidx.room.*
import com.elon.camera_photo_system.data.local.entity.TrackEntity
import kotlinx.coroutines.flow.Flow
import java.time.LocalDateTime

/**
 * 轨迹DAO
 */
@Dao
interface TrackDao {
    /**
     * 获取车辆下的所有轨迹
     */
    @Query("SELECT * FROM tracks WHERE vehicleId = :vehicleId ORDER BY startTime DESC")
    fun getTracksByVehicle(vehicleId: Long): Flow<List<TrackEntity>>
    
    /**
     * 获取指定ID的轨迹
     */
    @Query("SELECT * FROM tracks WHERE id = :trackId")
    fun getTrackById(trackId: Long): Flow<TrackEntity?>
    
    /**
     * 插入轨迹
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(track: TrackEntity): Long
    
    /**
     * 更新轨迹
     */
    @Update
    suspend fun update(track: TrackEntity)
    
    /**
     * 删除轨迹
     */
    @Delete
    suspend fun delete(track: TrackEntity)
    
    /**
     * 设置轨迹开始时间
     */
    @Query("UPDATE tracks SET startTime = :startTime, isStarted = 1 WHERE id = :trackId")
    suspend fun startTrack(trackId: Long, startTime: LocalDateTime = LocalDateTime.now())
    
    /**
     * 设置轨迹结束时间
     */
    @Query("UPDATE tracks SET endTime = :endTime, isEnded = 1 WHERE id = :trackId")
    suspend fun endTrack(trackId: Long, endTime: LocalDateTime = LocalDateTime.now())
    
    /**
     * 更新起点照片数量
     */
    @Query("UPDATE tracks SET startPointPhotoCount = :count WHERE id = :trackId")
    suspend fun updateStartPointPhotoCount(trackId: Long, count: Int)
    
    /**
     * 更新中间点照片数量
     */
    @Query("UPDATE tracks SET middlePointPhotoCount = :count WHERE id = :trackId")
    suspend fun updateMiddlePointPhotoCount(trackId: Long, count: Int)
    
    /**
     * 更新模型照片数量
     */
    @Query("UPDATE tracks SET modelPointPhotoCount = :count WHERE id = :trackId")
    suspend fun updateModelPointPhotoCount(trackId: Long, count: Int)
    
    /**
     * 更新过渡点照片数量
     */
    @Query("UPDATE tracks SET transitionPointPhotoCount = :count WHERE id = :trackId")
    suspend fun updateTransitionPointPhotoCount(trackId: Long, count: Int)
    
    /**
     * 更新终点照片数量
     */
    @Query("UPDATE tracks SET endPointPhotoCount = :count WHERE id = :trackId")
    suspend fun updateEndPointPhotoCount(trackId: Long, count: Int)
    
    /**
     * 更新轨迹总照片数量
     */
    @Query("UPDATE tracks SET photoCount = :count WHERE id = :trackId")
    suspend fun updatePhotoCount(trackId: Long, count: Int)
} 