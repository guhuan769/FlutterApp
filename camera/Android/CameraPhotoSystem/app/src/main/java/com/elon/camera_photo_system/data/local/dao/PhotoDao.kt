package com.elon.camera_photo_system.data.local.dao

import androidx.room.*
import com.elon.camera_photo_system.data.local.entity.PhotoEntity
import kotlinx.coroutines.flow.Flow

/**
 * 照片数据访问对象
 */
@Dao
interface PhotoDao {
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPhoto(photo: PhotoEntity): Long
    
    @Update
    suspend fun updatePhoto(photo: PhotoEntity)
    
    @Delete
    suspend fun deletePhoto(photo: PhotoEntity)
    
    @Query("SELECT * FROM photos WHERE id = :photoId")
    suspend fun getPhotoById(photoId: Long): PhotoEntity?
    
    @Query("SELECT * FROM photos WHERE moduleId = :moduleId AND moduleType = :moduleType")
    fun getPhotosByModule(moduleId: Long, moduleType: String): Flow<List<PhotoEntity>>
    
    @Query("SELECT * FROM photos WHERE moduleType = :moduleType")
    fun getPhotosByModuleType(moduleType: String): Flow<List<PhotoEntity>>
    
    @Query("SELECT * FROM photos WHERE moduleId = :moduleId AND moduleType = :moduleType AND photoType = :photoType")
    fun getPhotosByType(moduleId: Long, moduleType: String, photoType: String): Flow<List<PhotoEntity>>
    
    @Query("SELECT COUNT(*) FROM photos WHERE moduleId = :moduleId AND moduleType = :moduleType AND photoType = :photoType")
    suspend fun getPhotoCountByType(moduleId: Long, moduleType: String, photoType: String): Int
    
    @Query("SELECT * FROM photos WHERE isUploaded = 0")
    fun getNotUploadedPhotos(): Flow<List<PhotoEntity>>
} 