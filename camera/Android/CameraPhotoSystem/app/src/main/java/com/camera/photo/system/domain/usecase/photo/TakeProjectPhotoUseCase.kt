package com.camera.photo.system.domain.usecase.photo

import com.camera.photo.system.domain.entity.EntityType
import com.camera.photo.system.domain.entity.Photo
import com.camera.photo.system.domain.entity.ProjectPhotoType
import com.camera.photo.system.domain.repository.CameraRepository
import com.camera.photo.system.domain.repository.PhotoRepository
import com.camera.photo.system.domain.repository.ProjectRepository
import java.util.UUID
import javax.inject.Inject

/**
 * 项目拍照用例
 */
class TakeProjectPhotoUseCase @Inject constructor(
    private val cameraRepository: CameraRepository,
    private val photoRepository: PhotoRepository,
    private val projectRepository: ProjectRepository
) {
    /**
     * 执行项目拍照操作
     * @param projectId 项目ID
     * @param photoType 照片类型
     * @return 保存的照片
     * @throws IllegalArgumentException 如果项目不存在
     */
    suspend fun execute(projectId: String, photoType: ProjectPhotoType): Photo {
        // 验证项目是否存在
        val project = projectRepository.getProjectById(projectId)
            ?: throw IllegalArgumentException("Project not found")
            
        // 生成照片文件名
        val fileName = "project_${projectId}_${photoType.name.lowercase()}_${System.currentTimeMillis()}.jpg"
        
        // 调用相机拍照
        val cameraPhoto = cameraRepository.takePhoto(fileName)
        
        // 创建照片记录
        val photo = Photo(
            id = UUID.randomUUID().toString(),
            entityId = projectId,
            entityType = EntityType.PROJECT,
            path = cameraPhoto.path,
            timestamp = System.currentTimeMillis(),
            photoType = photoType.name
        )
        
        // 保存照片记录并返回
        val savedPhoto = photoRepository.savePhoto(photo)
        
        // 如果是概览照片，并且项目没有封面，则更新项目封面
        if (photoType == ProjectPhotoType.OVERVIEW && project.coverPhotoPath == null) {
            projectRepository.updateProject(project.copy(coverPhotoPath = cameraPhoto.path))
        }
        
        return savedPhoto
    }
} 