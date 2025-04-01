package com.elon.camera_photo_system.domain.usecase.photo

import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.repository.PhotoRepository
import java.io.File
import javax.inject.Inject

/**
 * 删除照片用例
 */
class DeletePhotoUseCase @Inject constructor(
    private val photoRepository: PhotoRepository
) {
    /**
     * 删除照片
     *
     * @param photo 要删除的照片
     * @param deleteFile 是否同时删除文件
     */
    suspend operator fun invoke(photo: Photo, deleteFile: Boolean = true) {
        photoRepository.deletePhoto(photo)
        
        // 同时删除文件系统中的照片文件
        if (deleteFile) {
            val file = File(photo.filePath)
            if (file.exists()) {
                file.delete()
            }
        }
    }
} 