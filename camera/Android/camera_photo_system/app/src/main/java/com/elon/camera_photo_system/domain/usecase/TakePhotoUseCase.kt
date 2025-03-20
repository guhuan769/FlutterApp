package com.elon.camera_photo_system.domain.usecase

import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.model.PhotoType
import com.elon.camera_photo_system.domain.repository.CameraRepository
import javax.inject.Inject

/**
 * 拍照用例
 * @property cameraRepository 相机仓库
 */
class TakePhotoUseCase @Inject constructor(
    private val cameraRepository: CameraRepository
) {
    /**
     * 拍照
     * @param type 照片类型
     * @param projectId 项目ID（可选）
     * @param vehicleId 车辆ID（可选）
     * @param routeId 轨迹ID（可选）
     * @return 拍摄的照片
     */
    suspend operator fun invoke(
        type: PhotoType,
        projectId: Long? = null,
        vehicleId: Long? = null,
        routeId: Long? = null
    ): Result<Photo> {
        return try {
            val photo = cameraRepository.takePhoto(type, projectId, vehicleId, routeId)
            if (photo != null) {
                Result.success(photo)
            } else {
                Result.failure(Exception("拍照失败"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
} 