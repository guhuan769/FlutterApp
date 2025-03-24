package com.camera.photo.system.domain.usecase.project

import com.camera.photo.system.domain.entity.Project
import com.camera.photo.system.domain.repository.ProjectRepository
import java.util.UUID
import javax.inject.Inject

/**
 * 创建项目用例
 */
class CreateProjectUseCase @Inject constructor(
    private val projectRepository: ProjectRepository
) {
    /**
     * 执行创建项目操作
     * @param name 项目名称
     * @param description 项目描述
     * @return 创建的项目
     */
    suspend fun execute(name: String, description: String): Project {
        val project = Project(
            id = UUID.randomUUID().toString(),
            name = name,
            description = description,
            createdAt = System.currentTimeMillis(),
            updatedAt = System.currentTimeMillis(),
            coverPhotoPath = null
        )
        return projectRepository.createProject(project)
    }
} 