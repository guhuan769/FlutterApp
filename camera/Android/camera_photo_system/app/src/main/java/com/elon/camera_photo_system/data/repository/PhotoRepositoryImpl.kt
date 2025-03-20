package com.elon.camera_photo_system.data.repository

import android.content.Context
import android.net.Uri
import androidx.room.Room
import com.elon.camera_photo_system.data.source.local.PhotoDatabase
import com.elon.camera_photo_system.data.source.local.entity.PhotoEntity
import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.model.PhotoType
import com.elon.camera_photo_system.domain.repository.PhotoRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import java.util.Date
import javax.inject.Inject

class PhotoRepositoryImpl @Inject constructor(
    context: Context
) : PhotoRepository {

    private val database = Room.databaseBuilder(
        context,
        PhotoDatabase::class.java,
        "photo_database"
    ).build()
    
    private val photoDao = database.photoDao()
    
    override suspend fun savePhoto(
        uri: Uri,
        type: PhotoType,
        projectId: Long?,
        vehicleId: Long?,
        routeId: Long?
    ): Photo = withContext(Dispatchers.IO) {
        val sequence = getNextSequence(type, projectId, vehicleId, routeId)
        val name = PhotoType.generateFileName(type, sequence)
        
        val photoEntity = PhotoEntity(
            id = 0,
            uri = uri.toString(),
            name = name,
            type = type.name,
            sequence = sequence,
            createTime = Date(),
            projectId = projectId,
            vehicleId = vehicleId,
            routeId = routeId,
            isUploaded = false
        )
        
        val id = photoDao.insertPhoto(photoEntity)
        return@withContext Photo(
            id = id,
            uri = uri,
            name = name,
            type = type,
            sequence = sequence,
            createTime = photoEntity.createTime,
            projectId = projectId,
            vehicleId = vehicleId,
            routeId = routeId,
            isUploaded = false
        )
    }
    
    override suspend fun getNextSequence(
        type: PhotoType,
        projectId: Long?,
        vehicleId: Long?,
        routeId: Long?
    ): Int = withContext(Dispatchers.IO) {
        val maxSequence = photoDao.getMaxSequence(
            type = type.name,
            projectId = projectId,
            vehicleId = vehicleId,
            routeId = routeId
        )
        return@withContext (maxSequence ?: 0) + 1
    }
    
    override fun getAllPhotos(
        projectId: Long?,
        vehicleId: Long?,
        routeId: Long?
    ): Flow<List<Photo>> {
        return photoDao.getAllPhotos(projectId, vehicleId, routeId).map { entities ->
            entities.map { it.toDomainModel() }
        }
    }
    
    override fun getPhotosByType(
        type: PhotoType,
        projectId: Long?,
        vehicleId: Long?,
        routeId: Long?
    ): Flow<List<Photo>> {
        return photoDao.getPhotosByType(
            type.name,
            projectId,
            vehicleId,
            routeId
        ).map { entities ->
            entities.map { it.toDomainModel() }
        }
    }
    
    override suspend fun deletePhoto(photo: Photo): Boolean = withContext(Dispatchers.IO) {
        val count = photoDao.deletePhoto(photo.id)
        return@withContext count > 0
    }
    
    override suspend fun markPhotoAsUploaded(photoId: Long): Boolean = withContext(Dispatchers.IO) {
        val count = photoDao.updateUploadStatus(photoId, true)
        return@withContext count > 0
    }
    
    private fun PhotoEntity.toDomainModel(): Photo {
        return Photo(
            id = id,
            uri = Uri.parse(uri),
            name = name,
            type = PhotoType.valueOf(type),
            sequence = sequence,
            createTime = createTime,
            projectId = projectId,
            vehicleId = vehicleId,
            routeId = routeId,
            isUploaded = isUploaded
        )
    }
} 