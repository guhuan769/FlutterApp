package com.camera.photo.system.domain.repository

import com.camera.photo.system.domain.entity.EntityType
import com.camera.photo.system.domain.entity.Photo
import kotlinx.coroutines.flow.Flow

/**
 * 照片仓库接口
 * 定义照片相关的数据操作
 */
interface PhotoRepository {
    /**
     * 保存照片信息
     * @param photo 照片信息
     * @return 保存的照片
     */
    suspend fun savePhoto(photo: Photo): Photo
    
    /**
     * 根据ID获取照片
     * @param id 照片ID
     * @return 照片信息，如不存在返回null
     */
    suspend fun getPhotoById(id: String): Photo?
    
    /**
     * 删除照片
     * @param id 照片ID
     * @return 是否删除成功
     */
    suspend fun deletePhoto(id: String): Boolean
    
    /**
     * 根据实体获取照片列表
     * @param entityId 实体ID
     * @param entityType 实体类型
     * @param photoType 照片类型，可选
     * @return 照片列表流
     */
    fun getPhotosByEntity(
        entityId: String,
        entityType: EntityType,
        photoType: String? = null
    ): Flow<List<Photo>>
    
    /**
     * 根据多个实体ID获取照片列表
     * @param entityIds 实体ID列表
     * @param entityType 实体类型
     * @param photoType 照片类型，可选
     * @return 照片列表流
     */
    fun getPhotosByEntityIds(
        entityIds: List<String>,
        entityType: EntityType,
        photoType: String? = null
    ): Flow<List<Photo>>
} 