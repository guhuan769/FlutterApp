package com.elon.camera_photo_system.data.repository

import com.elon.camera_photo_system.data.local.dao.PhotoDao
import com.elon.camera_photo_system.data.local.entity.PhotoEntity
import com.elon.camera_photo_system.data.remote.ApiConfig
import com.elon.camera_photo_system.data.remote.PhotoRemoteDataSource
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.model.PhotoType
import com.elon.camera_photo_system.domain.repository.PhotoRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import javax.inject.Inject
import javax.inject.Singleton
import android.util.Log

@Singleton
class PhotoRepositoryImpl @Inject constructor(
    private val photoDao: PhotoDao,
    private val photoRemoteDataSource: PhotoRemoteDataSource,
    private val apiConfig: ApiConfig
) : PhotoRepository {
    
    private val formatter = DateTimeFormatter.ISO_LOCAL_DATE_TIME
    
    override suspend fun savePhoto(photo: Photo): Long {
        return photoDao.insertPhoto(photo.toPhotoEntity())
    }
    
    override suspend fun updatePhoto(photo: Photo) {
        photoDao.updatePhoto(photo.toPhotoEntity())
    }
    
    override suspend fun deletePhoto(photo: Photo) {
        photoDao.deletePhoto(photo.toPhotoEntity())
    }
    
    override suspend fun getPhotoById(photoId: Long): Photo? {
        return photoDao.getPhotoById(photoId)?.toPhoto()
    }
    
    override fun getPhotosByModule(moduleId: Long, moduleType: ModuleType): Flow<List<Photo>> {
        return photoDao.getPhotosByModule(moduleId, moduleType.name)
            .map { entities -> entities.map { it.toPhoto() } }
    }
    
    override fun getPhotosByModuleType(moduleType: ModuleType): Flow<List<Photo>> {
        return photoDao.getPhotosByModuleType(moduleType.name)
            .map { entities -> entities.map { it.toPhoto() } }
    }
    
    override fun getPhotosByType(
        moduleId: Long,
        moduleType: ModuleType,
        photoType: PhotoType
    ): Flow<List<Photo>> {
        return photoDao.getPhotosByType(moduleId, moduleType.name, photoType.name)
            .map { entities -> entities.map { it.toPhoto() } }
    }
    
    override suspend fun getPhotoCountByType(
        moduleId: Long,
        moduleType: ModuleType,
        photoType: PhotoType
    ): Int {
        return photoDao.getPhotoCountByType(moduleId, moduleType.name, photoType.name)
    }
    
    override fun getNotUploadedPhotos(): Flow<List<Photo>> {
        return photoDao.getNotUploadedPhotos()
            .map { entities -> entities.map { it.toPhoto() } }
    }
    
    override suspend fun uploadPhoto(photo: Photo): Boolean {
        try {
            val result = photoRemoteDataSource.uploadPhoto(
                filePath = photo.filePath,
                fileName = photo.fileName,
                moduleId = photo.moduleId,
                moduleType = photo.moduleType,
                photoType = photo.photoType,
                projectName = getProjectName(photo.moduleId),
                latitude = photo.latitude,
                longitude = photo.longitude
            )
            
            if (result) {
                // 更新照片上传状态
                val updatedPhoto = photo.copy(isUploaded = true)
                updatePhoto(updatedPhoto)
            }
            
            return result
        } catch (e: Exception) {
            Log.e("PhotoRepository", "上传照片失败: ${photo.fileName}", e)
            // 重新抛出异常给上层处理
            throw e
        }
    }
    
    /**
     * 获取项目名称
     */
    private suspend fun getProjectName(projectId: Long): String {
        try {
            // 直接使用DAO中的方法获取项目名称
            val projectName = photoDao.getProjectName(projectId)
            return projectName ?: projectId.toString()  // 如果获取不到，返回ID作为标识
        } catch (e: Exception) {
            Log.e("PhotoRepository", "获取项目名称失败", e)
            return projectId.toString()  // 出错时返回ID
        }
    }
    
    override fun setApiBaseUrl(url: String) {
        apiConfig.updateBaseUrl(url)
    }
    
    override suspend fun deleteProjectPhotosOnServer(moduleId: Long, moduleType: ModuleType): Boolean {
        return try {
            // 调用远程数据源删除服务器上的照片
            val result = photoRemoteDataSource.deleteProjectPhotos(moduleId, moduleType)
            
            // 如果成功删除，重置本地照片的上传状态
            if (result) {
                resetUploadStatus(moduleId, moduleType)
            }
            
            result
        } catch (e: Exception) {
            Log.e("PhotoRepository", "删除服务器上的项目照片失败", e)
            throw e
        }
    }
    
    override suspend fun resetUploadStatus(moduleId: Long, moduleType: ModuleType): Int {
        var updatedCount = 0
        
        // 由于getPhotosByModule返回Flow类型，需要先收集数据
        val photos = photoDao.getPhotosByModule(moduleId, moduleType.name).first()
        
        photos.forEach { entity ->
            if (entity.isUploaded) {
                val updatedEntity = entity.copy(isUploaded = false)
                photoDao.updatePhoto(updatedEntity)
                updatedCount++
            }
        }
        
        Log.d("PhotoRepository", "重置了 $updatedCount 张照片的上传状态")
        return updatedCount
    }
    
    // 扩展函数：将领域模型转换为数据库实体
    private fun Photo.toPhotoEntity(): PhotoEntity {
        return PhotoEntity(
            id = id,
            moduleId = moduleId,
            moduleType = moduleType.name,
            photoType = photoType.name,
            filePath = filePath,
            fileName = fileName,
            createdAt = createdAt.format(formatter),
            latitude = latitude,
            longitude = longitude,
            isUploaded = isUploaded
        )
    }
    
    // 扩展函数：将数据库实体转换为领域模型
    private fun PhotoEntity.toPhoto(): Photo {
        return Photo(
            id = id,
            moduleId = moduleId,
            moduleType = ModuleType.valueOf(moduleType),
            photoType = PhotoType.valueOf(photoType),
            filePath = filePath,
            fileName = fileName,
            createdAt = LocalDateTime.parse(createdAt, formatter),
            latitude = latitude,
            longitude = longitude,
            isUploaded = isUploaded
        )
    }
} 