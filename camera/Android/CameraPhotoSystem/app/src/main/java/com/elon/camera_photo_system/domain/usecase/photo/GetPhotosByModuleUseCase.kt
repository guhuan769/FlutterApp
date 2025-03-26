package com.elon.camera_photo_system.domain.usecase.photo

import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.repository.PhotoRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

/**
 * 获取模块照片用例
 */
class GetPhotosByModuleUseCase @Inject constructor(
    private val photoRepository: PhotoRepository
) {
    /**
     * 获取指定模块的所有照片
     *
     * @param moduleId 模块ID
     * @param moduleType 模块类型
     * @return 照片列表Flow
     */
    operator fun invoke(moduleId: Long, moduleType: ModuleType): Flow<List<Photo>> {
        return photoRepository.getPhotosByModule(moduleId, moduleType)
    }
} 