package com.camera.photo.system.domain.usecase

import com.camera.photo.system.domain.model.Photo
import com.camera.photo.system.domain.model.PhotoType
import com.camera.photo.system.domain.repository.CameraRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.UUID
import javax.inject.Inject

/**
 * 拍照用例
 * 实现拍照业务逻辑
 */
class TakePhotoUseCase @Inject constructor(
    private val cameraRepository: CameraRepository
) {
    /**
     * 执行拍照操作
     * 
     * @param photoType 照片类型
     * @param customFileName 自定义文件名，如果为null则自动生成
     * @return 拍摄的照片对象
     */
    suspend fun execute(
        photoType: PhotoType,
        customFileName: String? = null
    ): Result<Photo> = withContext(Dispatchers.IO) {
        try {
            // 生成文件名
            val fileName = customFileName ?: generateFileName(photoType)
            
            // 调用仓库方法拍照
            val photo = cameraRepository.takePhoto(fileName)
            
            // 返回成功结果
            Result.success(photo)
        } catch (e: Exception) {
            // 返回失败结果
            Result.failure(e)
        }
    }
    
    /**
     * 根据照片类型生成文件名
     * 
     * @param photoType 照片类型
     * @return 生成的文件名
     */
    private fun generateFileName(photoType: PhotoType): String {
        val timestamp = System.currentTimeMillis()
        val uuid = UUID.randomUUID().toString().substring(0, 8)
        val prefix = when (photoType) {
            PhotoType.PROJECT_MODEL -> "project_model"
            PhotoType.PROJECT_SITE -> "project_site"
            PhotoType.PROJECT_DOCUMENT -> "project_document"
            PhotoType.VEHICLE -> "vehicle"
            PhotoType.VEHICLE_FRONT -> "vehicle_front"
            PhotoType.VEHICLE_REAR -> "vehicle_rear"
            PhotoType.VEHICLE_SIDE -> "vehicle_side"
            PhotoType.VEHICLE_PLATE -> "vehicle_plate"
            PhotoType.TRACK_START -> "track_start"
            PhotoType.TRACK_MIDDLE -> "track_middle"
            PhotoType.TRACK_MODEL -> "track_model"
            PhotoType.TRACK_END -> "track_end"
        }
        
        return "${prefix}_${timestamp}_${uuid}.jpg"
    }
} 