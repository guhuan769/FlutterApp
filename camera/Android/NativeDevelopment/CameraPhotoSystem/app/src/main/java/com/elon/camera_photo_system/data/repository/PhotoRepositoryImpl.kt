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
        // 根据不同模块类型生成标准化的文件名
        val standardizedPhoto = generateStandardizedPhotoName(photo)
        return photoDao.insertPhoto(standardizedPhoto.toPhotoEntity())
    }
    
    /**
     * 生成标准化的照片名称
     * 项目照片：项目名称_照片类型(中文)_序号_角度°.jpg
     * 车辆照片：项目名称_车辆名称_照片类型(中文)_序号_角度°.jpg
     * 轨迹照片：项目名称_车辆名称_轨迹名称_照片类型(中文)_序号_角度°.jpg
     */
    private suspend fun generateStandardizedPhotoName(photo: Photo): Photo {
        val originalFileName = photo.fileName
        // 获取文件扩展名
        val extension = originalFileName.substringAfterLast('.', "")
        
        // 获取照片类型的中文描述
        val photoTypeLabel = photo.photoType.label
        
        // 确保角度值有效
        val angle = if (photo.angle > 0) photo.angle else {
            // 尝试从文件名提取角度信息
            val (_, extractedAngle) = extractPhotoInfoFromFileName(originalFileName, photo.moduleType)
            extractedAngle
        }
        
        Log.d("PhotoRepository", "标准化照片名称: 序号=${photo.photoNumber}, 角度=$angle")
        
        // 根据模块类型获取相应的命名
        val newFileName = when (photo.moduleType) {
            ModuleType.PROJECT -> {
                val projectName = photoDao.getProjectName(photo.moduleId) ?: "未知项目"
                val photoCount: Int
                if (photo.photoNumber > 0) {
                    photoCount = photo.photoNumber
                } else {
                    photoCount = photoDao.getPhotoCountByModule(photo.moduleId, photo.moduleType.name) + 1
                }
                "${projectName}_${photoTypeLabel}_${photoCount}_${angle}°.$extension"
            }
            ModuleType.VEHICLE -> {
                val vehicleWithProject = photoDao.getVehicleWithProject(photo.moduleId)
                val projectName = vehicleWithProject?.projectName ?: "未知项目"
                val vehicleName = vehicleWithProject?.vehicleName ?: "未知车辆"
                val photoCount: Int
                if (photo.photoNumber > 0) {
                    photoCount = photo.photoNumber
                } else {
                    photoCount = photoDao.getPhotoCountByModule(photo.moduleId, photo.moduleType.name) + 1
                }
                "${projectName}_${vehicleName}_${photoTypeLabel}_${photoCount}_${angle}°.$extension"
            }
            ModuleType.TRACK -> {
                val trackWithVehicleAndProject = photoDao.getTrackWithVehicleAndProject(photo.moduleId)
                val projectName = trackWithVehicleAndProject?.projectName ?: "未知项目"
                val vehicleName = trackWithVehicleAndProject?.vehicleName ?: "未知车辆"
                val trackName = trackWithVehicleAndProject?.trackName ?: "未知轨迹"
                val photoCount: Int
                if (photo.photoNumber > 0) {
                    photoCount = photo.photoNumber
                } else {
                    photoCount = photoDao.getPhotoCountByModule(photo.moduleId, photo.moduleType.name) + 1
                }
                "${projectName}_${vehicleName}_${trackName}_${photoTypeLabel}_${photoCount}_${angle}°.$extension"
            }
        }
        
        // 返回更新了文件名和角度的照片对象
        return photo.copy(fileName = newFileName, angle = angle)
    }
    
    /**
     * 从文件名中提取照片序号和角度信息
     */
    private fun extractPhotoInfoFromFileName(fileName: String, moduleType: ModuleType): Pair<Int, Int> {
        try {
            Log.d("PhotoRepository", "从文件名提取信息: $fileName")
            val parts = fileName.split("_")
            
            // 根据不同模块类型，序号位置不同
            val numIndex = when (moduleType) {
                ModuleType.PROJECT -> 2 // 项目名称_照片类型_序号_角度.jpg
                ModuleType.VEHICLE -> 3 // 项目名称_车辆名称_照片类型_序号_角度.jpg
                ModuleType.TRACK -> 4   // 项目名称_车辆名称_轨迹名称_照片类型_序号_角度.jpg
            }
            
            // 确保序号索引有效
            if (numIndex >= parts.size) {
                Log.e("PhotoRepository", "无效的序号索引: $numIndex, 部分大小: ${parts.size}")
                return Pair(0, 0)
            }
            
            // 提取序号
            val photoNumber = parts[numIndex].toIntOrNull() ?: 0
            
            // 提取角度 - 更强健的方法
            val angle = if (numIndex + 1 < parts.size) {
                // 获取可能包含角度和扩展名的部分
                val anglePart = parts[numIndex + 1]
                // 使用正则表达式提取数字部分
                val angleMatch = Regex("(\\d+)").find(anglePart)
                angleMatch?.groupValues?.get(1)?.toIntOrNull() ?: 0
            } else 0
            
            Log.d("PhotoRepository", "提取的序号: $photoNumber, 角度: $angle")
            return Pair(photoNumber, angle)
        } catch (e: Exception) {
            Log.e("PhotoRepository", "提取照片信息错误: ${e.message}")
            return Pair(0, 0)
        }
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
            // 获取照片的标准化文件名（如果已经标准化过则不需要再次处理）
            val standardizedPhoto = if (isStandardizedFileName(photo)) {
                photo
            } else {
                generateStandardizedPhotoName(photo)
            }
            
            val result = photoRemoteDataSource.uploadPhoto(
                filePath = standardizedPhoto.filePath,
                fileName = standardizedPhoto.fileName,
                moduleId = standardizedPhoto.moduleId,
                moduleType = standardizedPhoto.moduleType,
                photoType = standardizedPhoto.photoType,
                projectName = getProjectName(standardizedPhoto.moduleId),
                latitude = standardizedPhoto.latitude,
                longitude = standardizedPhoto.longitude
            )
            
            if (result) {
                // 更新照片上传状态和文件名（如果更改了）
                if (standardizedPhoto.fileName != photo.fileName) {
                    // 如果文件名改变了，更新数据库中的文件名
                    val updated = standardizedPhoto.copy(isUploaded = true)
                    updatePhoto(updated)
                } else {
                    // 仅更新上传状态
                    val updated = photo.copy(isUploaded = true)
                    updatePhoto(updated)
                }
            }
            
            return result
        } catch (e: Exception) {
            Log.e("PhotoRepository", "上传照片失败: ${photo.fileName}", e)
            // 重新抛出异常给上层处理
            throw e
        }
    }
    
    /**
     * 检查照片名称是否已经标准化
     */
    private fun isStandardizedFileName(photo: Photo): Boolean {
        val fileName = photo.fileName
        val photoTypeLabel = photo.photoType.label
        
        // 更准确的正则表达式检查，包含角度信息
        return when (photo.moduleType) {
            ModuleType.PROJECT -> {
                // 项目照片格式：项目名称_照片类型(中文)_序号_角度°.扩展名
                fileName.matches(Regex(".+_${photoTypeLabel}_\\d+_\\d+°\\..+"))
            }
            ModuleType.VEHICLE -> {
                // 车辆照片格式：项目名称_车辆名称_照片类型(中文)_序号_角度°.扩展名
                fileName.matches(Regex(".+_.+_${photoTypeLabel}_\\d+_\\d+°\\..+"))
            }
            ModuleType.TRACK -> {
                // 轨迹照片格式：项目名称_车辆名称_轨迹名称_照片类型(中文)_序号_角度°.扩展名
                fileName.matches(Regex(".+_.+_.+_${photoTypeLabel}_\\d+_\\d+°\\..+"))
            }
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
    
    /**
     * 将Photo对象转换为数据库实体
     */
    private fun Photo.toPhotoEntity(): PhotoEntity {
        return PhotoEntity(
            id = id,
            moduleId = moduleId,
            moduleType = moduleType.name,
            photoType = photoType.name,
            filePath = filePath,
            fileName = fileName,
            photoNumber = photoNumber,
            angle = angle,
            createdAt = createdAt.format(formatter),
            latitude = latitude,
            longitude = longitude,
            isUploaded = isUploaded,
            uploadPhotoType = uploadPhotoType,
            uploadTypeId = uploadTypeId
        )
    }
    
    /**
     * 将数据库实体转换为Photo对象
     */
    private fun PhotoEntity.toPhoto(): Photo {
        return Photo(
            id = id,
            moduleId = moduleId,
            moduleType = ModuleType.valueOf(moduleType),
            photoType = PhotoType.valueOf(photoType),
            filePath = filePath,
            fileName = fileName,
            photoNumber = photoNumber,
            angle = angle,
            createdAt = LocalDateTime.parse(createdAt, formatter),
            latitude = latitude,
            longitude = longitude,
            isUploaded = isUploaded,
            uploadPhotoType = uploadPhotoType,
            uploadTypeId = uploadTypeId
        )
    }
} 