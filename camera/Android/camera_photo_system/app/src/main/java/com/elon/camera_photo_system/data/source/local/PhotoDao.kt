package com.elon.camera_photo_system.data.source.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import com.elon.camera_photo_system.data.source.local.entity.PhotoEntity
import kotlinx.coroutines.flow.Flow

/**
 * 照片数据访问接口
 */
@Dao
interface PhotoDao {
    
    /**
     * 插入照片
     * @param photo 照片实体
     * @return 插入的照片ID
     */
    @Insert
    suspend fun insertPhoto(photo: PhotoEntity): Long
    
    /**
     * 获取所有照片
     * @param projectId 项目ID（可选）
     * @param vehicleId 车辆ID（可选）
     * @param routeId 轨迹ID（可选）
     * @return 照片实体流
     */
    @Query("""
        SELECT * FROM photos 
        WHERE (:projectId IS NULL OR projectId = :projectId)
        AND (:vehicleId IS NULL OR vehicleId = :vehicleId)
        AND (:routeId IS NULL OR routeId = :routeId)
        ORDER BY createTime DESC
    """)
    fun getAllPhotos(
        projectId: Long? = null,
        vehicleId: Long? = null,
        routeId: Long? = null
    ): Flow<List<PhotoEntity>>
    
    /**
     * 根据类型获取照片
     * @param type 照片类型
     * @param projectId 项目ID（可选）
     * @param vehicleId 车辆ID（可选）
     * @param routeId 轨迹ID（可选）
     * @return 照片实体流
     */
    @Query("""
        SELECT * FROM photos 
        WHERE type = :type
        AND (:projectId IS NULL OR projectId = :projectId)
        AND (:vehicleId IS NULL OR vehicleId = :vehicleId)
        AND (:routeId IS NULL OR routeId = :routeId)
        ORDER BY createTime DESC
    """)
    fun getPhotosByType(
        type: String,
        projectId: Long? = null,
        vehicleId: Long? = null,
        routeId: Long? = null
    ): Flow<List<PhotoEntity>>
    
    /**
     * 获取最大序列号
     * @param type 照片类型
     * @param projectId 项目ID（可选）
     * @param vehicleId 车辆ID（可选）
     * @param routeId 轨迹ID（可选）
     * @return 最大序列号
     */
    @Query("""
        SELECT MAX(sequence) FROM photos 
        WHERE type = :type
        AND (:projectId IS NULL OR projectId = :projectId)
        AND (:vehicleId IS NULL OR vehicleId = :vehicleId)
        AND (:routeId IS NULL OR routeId = :routeId)
    """)
    suspend fun getMaxSequence(
        type: String,
        projectId: Long? = null,
        vehicleId: Long? = null,
        routeId: Long? = null
    ): Int?
    
    /**
     * 删除照片
     * @param photoId 照片ID
     * @return 影响的行数
     */
    @Query("DELETE FROM photos WHERE id = :photoId")
    suspend fun deletePhoto(photoId: Long): Int
    
    /**
     * 更新上传状态
     * @param photoId 照片ID
     * @param isUploaded 是否已上传
     * @return 影响的行数
     */
    @Query("UPDATE photos SET isUploaded = :isUploaded WHERE id = :photoId")
    suspend fun updateUploadStatus(photoId: Long, isUploaded: Boolean): Int
} 