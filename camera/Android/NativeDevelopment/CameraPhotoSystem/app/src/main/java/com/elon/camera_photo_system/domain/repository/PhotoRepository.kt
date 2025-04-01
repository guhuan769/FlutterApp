package com.elon.camera_photo_system.domain.repository

import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.model.PhotoType
import kotlinx.coroutines.flow.Flow

/**
 * 照片仓库接口
 */
interface PhotoRepository {
    
    /**
     * 保存照片
     */
    suspend fun savePhoto(photo: Photo): Long
    
    /**
     * 更新照片
     */
    suspend fun updatePhoto(photo: Photo)
    
    /**
     * 删除照片
     */
    suspend fun deletePhoto(photo: Photo)
    
    /**
     * 根据ID获取照片
     */
    suspend fun getPhotoById(photoId: Long): Photo?
    
    /**
     * 获取指定模块的所有照片
     */
    fun getPhotosByModule(moduleId: Long, moduleType: ModuleType): Flow<List<Photo>>
    
    /**
     * 获取指定模块类型的所有照片
     */
    fun getPhotosByModuleType(moduleType: ModuleType): Flow<List<Photo>>
    
    /**
     * 获取指定类型的照片
     */
    fun getPhotosByType(moduleId: Long, moduleType: ModuleType, photoType: PhotoType): Flow<List<Photo>>
    
    /**
     * 获取指定类型照片的数量
     */
    suspend fun getPhotoCountByType(moduleId: Long, moduleType: ModuleType, photoType: PhotoType): Int
    
    /**
     * 获取未上传的照片
     */
    fun getNotUploadedPhotos(): Flow<List<Photo>>
} 