package com.elon.camera_photo_system.data.repository

import android.util.Log
import com.elon.camera_photo_system.data.local.dao.ProjectDao
import com.elon.camera_photo_system.data.local.entity.ProjectEntity
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.Project
import com.elon.camera_photo_system.domain.repository.ProjectRepository
import com.elon.camera_photo_system.domain.repository.PhotoRepository
import com.elon.camera_photo_system.domain.repository.VehicleRepository
import kotlinx.coroutines.flow.first
import java.time.LocalDateTime
import java.time.ZoneOffset
import javax.inject.Inject
import javax.inject.Provider

/**
 * 项目仓库实现
 */
class ProjectRepositoryImpl @Inject constructor(
    private val projectDao: ProjectDao,
    private val photoRepository: PhotoRepository,
    private val vehicleRepositoryProvider: Provider<VehicleRepository>
) : ProjectRepository {
    
    override suspend fun addProject(project: Project): Long {
        // 转换领域模型为数据库实体
        val entity = ProjectEntity(
            name = project.name,
            description = project.description,
            creationDate = project.createdAt.toEpochSecond(ZoneOffset.UTC)
        )
        
        // 存储并返回ID
        return projectDao.insertProject(entity)
    }
    
    override suspend fun getProjects(): List<Project> {
        // 加载并转换数据库实体为领域模型
        val projects = projectDao.getAllProjects().map { entity ->
            Project(
                id = entity.id,
                name = entity.name,
                description = entity.description,
                createdAt = LocalDateTime.ofEpochSecond(entity.creationDate, 0, ZoneOffset.UTC),
                vehicleCount = 0, // 后续更新
                photoCount = 0  // 后续更新
            )
        }
        
        // 更新每个项目的照片数量
        return projects.map { project ->
            updateProjectCounts(project)
        }
    }
    
    override suspend fun getProjectById(projectId: Long): Project? {
        val entity = projectDao.getProjectById(projectId) ?: return null
        
        val project = Project(
            id = entity.id,
            name = entity.name,
            description = entity.description,
            createdAt = LocalDateTime.ofEpochSecond(entity.creationDate, 0, ZoneOffset.UTC),
            vehicleCount = 0, // 后续更新
            photoCount = 0  // 后续更新
        )
        
        return updateProjectCounts(project)
    }
    
    override suspend fun updateProject(project: Project) {
        val entity = ProjectEntity(
            id = project.id,
            name = project.name,
            description = project.description,
            creationDate = project.createdAt.toEpochSecond(ZoneOffset.UTC)
        )
        
        projectDao.updateProject(entity)
    }
    
    override suspend fun deleteProject(project: Project) {
        val entity = ProjectEntity(
            id = project.id,
            name = project.name,
            description = project.description,
            creationDate = project.createdAt.toEpochSecond(ZoneOffset.UTC)
        )
        
        projectDao.deleteProject(entity)
    }
    
    /**
     * 更新项目的照片和车辆计数
     */
    private suspend fun updateProjectCounts(project: Project): Project {
        try {
            // 获取照片数量
            val photoCount = try {
                val photos = photoRepository.getPhotosByModule(
                    moduleId = project.id,
                    moduleType = ModuleType.PROJECT
                ).first()
                photos.size
            } catch (e: Exception) {
                Log.e("ProjectRepository", "获取照片列表失败", e)
                0
            }
            
            // 获取车辆数量 - 使用Provider延迟获取VehicleRepository实例
            val vehicleCount = try {
                val vehicleRepository = vehicleRepositoryProvider.get()
                val vehicles = vehicleRepository.getVehiclesByProject(project.id).first()
                vehicles.size
            } catch (e: Exception) {
                Log.e("ProjectRepository", "获取车辆列表失败", e)
                0
            }
            
            Log.d("ProjectRepository", "项目 ${project.name} (ID: ${project.id}) 照片数: $photoCount, 车辆数: $vehicleCount")
            
            return project.copy(
                photoCount = photoCount,
                vehicleCount = vehicleCount
            )
        } catch (e: Exception) {
            Log.e("ProjectRepository", "获取项目计数失败", e)
            return project // 失败时返回原始项目
        }
    }
} 