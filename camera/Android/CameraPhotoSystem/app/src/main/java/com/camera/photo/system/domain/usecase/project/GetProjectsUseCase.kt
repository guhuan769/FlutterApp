package com.camera.photo.system.domain.usecase.project

import com.camera.photo.system.domain.entity.Project
import com.camera.photo.system.domain.repository.ProjectRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

/**
 * 获取项目列表用例
 */
class GetProjectsUseCase @Inject constructor(
    private val projectRepository: ProjectRepository
) {
    /**
     * 执行获取项目列表操作
     * @return 项目列表流
     */
    fun execute(): Flow<List<Project>> {
        return projectRepository.getProjects()
    }
} 