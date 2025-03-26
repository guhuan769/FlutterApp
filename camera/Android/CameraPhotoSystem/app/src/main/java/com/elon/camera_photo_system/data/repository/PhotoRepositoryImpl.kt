package com.elon.camera_photo_system.data.repository

import com.elon.camera_photo_system.data.local.dao.PhotoDao
import com.elon.camera_photo_system.data.local.entity.PhotoEntity
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.model.PhotoType
import com.elon.camera_photo_system.domain.repository.PhotoRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class PhotoRepositoryImpl @Inject constructor(
    private val photoDao: PhotoDao
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