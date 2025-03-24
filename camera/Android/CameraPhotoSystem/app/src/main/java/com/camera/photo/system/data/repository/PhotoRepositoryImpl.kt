package com.camera.photo.system.data.repository

import android.content.Context
import com.camera.photo.system.domain.entity.EntityType
import com.camera.photo.system.domain.entity.Photo
import com.camera.photo.system.domain.repository.PhotoRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 照片仓库实现
 * 目前使用内存存储，后续可扩展为使用Room数据库
 */
@Singleton
class PhotoRepositoryImpl @Inject constructor(
    private val context: Context
) : PhotoRepository {
    
    // 内存缓存的照片列表
    private val photos = MutableStateFlow<List<Photo>>(emptyList())
    
    override suspend fun savePhoto(photo: Photo): Photo {
        val currentPhotos = photos.value.toMutableList()
        
        // 检查是否已存在同ID的照片，如果存在则更新
        val index = currentPhotos.indexOfFirst { it.id == photo.id }
        if (index != -1) {
            currentPhotos[index] = photo
        } else {
            currentPhotos.add(photo)
        }
        
        photos.value = currentPhotos
        return photo
    }
    
    override suspend fun getPhotoById(id: String): Photo? {
        return photos.value.find { it.id == id }
    }
    
    override suspend fun deletePhoto(id: String): Boolean {
        val currentPhotos = photos.value.toMutableList()
        val removed = currentPhotos.removeIf { it.id == id }
        if (removed) {
            photos.value = currentPhotos
        }
        return removed
    }
    
    override fun getPhotosByEntity(
        entityId: String,
        entityType: EntityType,
        photoType: String?
    ): Flow<List<Photo>> {
        return photos.asStateFlow().map { photoList ->
            photoList.filter { photo ->
                photo.entityId == entityId &&
                photo.entityType == entityType &&
                (photoType == null || photo.photoType == photoType)
            }
        }
    }
    
    override fun getPhotosByEntityIds(
        entityIds: List<String>,
        entityType: EntityType,
        photoType: String?
    ): Flow<List<Photo>> {
        return photos.asStateFlow().map { photoList ->
            photoList.filter { photo ->
                entityIds.contains(photo.entityId) &&
                photo.entityType == entityType &&
                (photoType == null || photo.photoType == photoType)
            }
        }
    }
} 