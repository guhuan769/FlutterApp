package com.elon.camera_photo_system.domain.repository

import android.net.Uri
import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.model.PhotoType
import kotlinx.coroutines.flow.Flow

/**
 * 照片仓库接口，定义照片管理相关操作
 */
interface PhotoRepository {
    /**
     * 保存照片到本地存储和数据库
     * @param uri 照片URI
     * @param type 照片类型
     * @param projectId 项目ID（可选）
     * @param vehicleId 车辆ID（可选）
     * @param routeId 轨迹ID（可选）
     * @return 保存的照片实体
     */
    suspend fun savePhoto(
        uri: Uri,
        type: PhotoType,
        projectId: Long? = null,
        vehicleId: Long? = null,
        routeId: Long? = null
    ): Photo
    
    /**
     * 根据照片类型获取下一个序号
     * @param type 照片类型
     * @param projectId 项目ID（可选）
     * @param vehicleId 车辆ID（可选）
     * @param routeId 轨迹ID（可选）
     * @return 下一个序号
     */
    suspend fun getNextSequence(
        type: PhotoType,
        projectId: Long? = null,
        vehicleId: Long? = null,
        routeId: Long? = null
    ): Int
    
    /**
     * 获取所有照片
     * @param projectId 项目ID（可选）
     * @param vehicleId 车辆ID（可选）
     * @param routeId 轨迹ID（可选）
     * @return 照片流
     */
    fun getAllPhotos(
        projectId: Long? = null,
        vehicleId: Long? = null,
        routeId: Long? = null
    ): Flow<List<Photo>>
    
    /**
     * 根据类型获取照片
     * @param type 照片类型
     * @param projectId 项目ID（可选）
     * @param vehicleId 车辆ID（可选）
     * @param routeId 轨迹ID（可选）
     * @return 照片流
     */
    fun getPhotosByType(
        type: PhotoType,
        projectId: Long? = null,
        vehicleId: Long? = null,
        routeId: Long? = null
    ): Flow<List<Photo>>
    
    /**
     * 删除照片
     * @param photo 要删除的照片
     * @return 是否删除成功
     */
    suspend fun deletePhoto(photo: Photo): Boolean
    
    /**
     * 标记照片为已上传
     * @param photoId 照片ID
     * @return 是否标记成功
     */
    suspend fun markPhotoAsUploaded(photoId: Long): Boolean
} 