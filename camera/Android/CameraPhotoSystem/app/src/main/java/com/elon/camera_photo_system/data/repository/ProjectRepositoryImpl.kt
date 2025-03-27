package com.elon.camera_photo_system.data.repository

import com.elon.camera_photo_system.data.local.dao.ProjectDao
import com.elon.camera_photo_system.data.local.entity.ProjectEntity
import com.elon.camera_photo_system.domain.model.Project
import com.elon.camera_photo_system.domain.repository.ProjectRepository
import java.time.LocalDateTime
import java.time.ZoneOffset
import javax.inject.Inject

/**
 * 项目仓库实现
 */
class ProjectRepositoryImpl @Inject constructor(
    private val projectDao: ProjectDao
) : ProjectRepository {
    
    override suspend fun addProject(project: Project): Long {
        // 转换领域模型为数据库实体
        val entity = ProjectEntity(
            name = project.name,
            description = project.description,
            creationDate = project.creationDate.toEpochSecond(ZoneOffset.UTC)
        )
        
        // 存储并返回ID
        return projectDao.insertProject(entity)
    }
    
    override suspend fun getProjects(): List<Project> {
        // 加载并转换数据库实体为领域模型
        return projectDao.getAllProjects().map { entity ->
            Project(
                id = entity.id,
                name = entity.name,
                description = entity.description,
                creationDate = LocalDateTime.ofEpochSecond(entity.creationDate, 0, ZoneOffset.UTC),
                vehicleCount = 0, // 这些可以通过关联查询获取
                photoCount = 0
            )
        }
    }
} 