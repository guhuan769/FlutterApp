package com.elon.camera_photo_system.domain.usecase

import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.model.PhotoType
import com.elon.camera_photo_system.domain.repository.PhotoRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

/**
 * 获取照片用例
 * @property photoRepository 照片仓库
 */
class GetPhotosUseCase @Inject constructor(
    private val photoRepository: PhotoRepository
) {
    /**
     * 获取所有照片
     * @param projectId 项目ID（可选）
     * @param vehicleId 车辆ID（可选）
     * @param routeId 轨迹ID（可选）
     * @return 照片流
     */
    operator fun invoke(
        projectId: Long? = null,
        vehicleId: Long? = null,
        routeId: Long? = null
    ): Flow<List<Photo>> {
        return photoRepository.getAllPhotos(projectId, vehicleId, routeId)
    }
    
    /**
     * 根据类型获取照片
     * @param type 照片类型
     * @param projectId 项目ID（可选）
     * @param vehicleId 车辆ID（可选）
     * @param routeId 轨迹ID（可选）
     * @return 照片流
     */
    fun getByType(
        type: PhotoType,
        projectId: Long? = null,
        vehicleId: Long? = null,
        routeId: Long? = null
    ): Flow<List<Photo>> {
        return photoRepository.getPhotosByType(type, projectId, vehicleId, routeId)
    }
} 