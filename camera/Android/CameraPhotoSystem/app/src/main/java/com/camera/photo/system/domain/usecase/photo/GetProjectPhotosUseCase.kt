package com.camera.photo.system.domain.usecase.photo

import com.camera.photo.system.domain.entity.EntityType
import com.camera.photo.system.domain.entity.Photo
import com.camera.photo.system.domain.entity.ProjectPhotoType
import com.camera.photo.system.domain.repository.PhotoRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

/**
 * 获取项目照片用例
 */
class GetProjectPhotosUseCase @Inject constructor(
    private val photoRepository: PhotoRepository
) {
    /**
     * 执行获取项目照片操作
     * @param projectId 项目ID
     * @param photoType 照片类型，可选
     * @return 照片列表流
     */
    fun execute(projectId: String, photoType: ProjectPhotoType? = null): Flow<List<Photo>> {
        return photoRepository.getPhotosByEntity(
            entityId = projectId,
            entityType = EntityType.PROJECT,
            photoType = photoType?.name
        )
    }
} 