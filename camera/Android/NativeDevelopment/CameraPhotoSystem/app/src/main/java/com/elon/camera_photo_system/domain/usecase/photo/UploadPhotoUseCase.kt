package com.elon.camera_photo_system.domain.usecase.photo

import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.repository.PhotoRepository
import javax.inject.Inject

/**
 * 上传照片用例
 */
class UploadPhotoUseCase @Inject constructor(
    private val photoRepository: PhotoRepository
) {
    /**
     * 上传照片
     *
     * @param photoId 照片ID
     * @return 上传结果
     */
    suspend operator fun invoke(photoId: Long): Result<Boolean> {
        return try {
            val photo = photoRepository.getPhotoById(photoId)
                ?: return Result.failure(Exception("照片不存在"))
            
            if (photo.isUploaded) {
                return Result.success(true) // 已上传，直接返回成功
            }
            
            val result = photoRepository.uploadPhoto(photo)
            Result.success(result)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * 设置API基础URL
     *
     * @param url API基础URL
     */
    fun setApiBaseUrl(url: String) {
        photoRepository.setApiBaseUrl(url)
    }
} 