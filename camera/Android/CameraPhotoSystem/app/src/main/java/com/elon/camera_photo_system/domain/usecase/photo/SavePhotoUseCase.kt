package com.elon.camera_photo_system.domain.usecase.photo

import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.model.PhotoType
import com.elon.camera_photo_system.domain.repository.PhotoRepository
import java.time.LocalDateTime
import javax.inject.Inject

/**
 * 保存照片用例
 */
class SavePhotoUseCase @Inject constructor(
    private val photoRepository: PhotoRepository
) {
    /**
     * 保存照片
     *
     * @param moduleId 模块ID
     * @param moduleType 模块类型
     * @param photoType 照片类型
     * @param filePath 文件路径
     * @param fileName 文件名
     * @param latitude 纬度
     * @param longitude 经度
     * @return 照片ID
     */
    suspend operator fun invoke(
        moduleId: Long,
        moduleType: ModuleType,
        photoType: PhotoType,
        filePath: String,
        fileName: String,
        latitude: Double? = null,
        longitude: Double? = null
    ): Long {
        val photo = Photo(
            moduleId = moduleId,
            moduleType = moduleType,
            photoType = photoType,
            filePath = filePath,
            fileName = fileName,
            createdAt = LocalDateTime.now(),
            latitude = latitude,
            longitude = longitude,
            isUploaded = false
        )
        
        return photoRepository.savePhoto(photo)
    }
} 