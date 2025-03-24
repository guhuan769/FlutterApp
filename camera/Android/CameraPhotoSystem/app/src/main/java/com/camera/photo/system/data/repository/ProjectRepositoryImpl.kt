package com.camera.photo.system.data.repository

import android.content.Context
import com.camera.photo.system.domain.entity.Project
import com.camera.photo.system.domain.entity.Vehicle
import com.camera.photo.system.domain.repository.ProjectRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 项目仓库实现
 * 目前使用内存存储，后续可扩展为使用Room数据库
 */
@Singleton
class ProjectRepositoryImpl @Inject constructor(
    private val context: Context
) : ProjectRepository {
    
    // 内存缓存的项目列表
    private val projects = MutableStateFlow<List<Project>>(emptyList())
    
    // 项目与车辆的关联映射
    private val projectVehicles = mutableMapOf<String, MutableStateFlow<List<Vehicle>>>()
    
    override suspend fun createProject(project: Project): Project {
        val currentProjects = projects.value.toMutableList()
        currentProjects.add(project)
        projects.value = currentProjects
        // 初始化项目的车辆列表
        projectVehicles[project.id] = MutableStateFlow(emptyList())
        return project
    }
    
    override suspend fun updateProject(project: Project): Project {
        val currentProjects = projects.value.toMutableList()
        val index = currentProjects.indexOfFirst { it.id == project.id }
        if (index != -1) {
            currentProjects[index] = project
            projects.value = currentProjects
        }
        return project
    }
    
    override suspend fun deleteProject(id: String): Boolean {
        val currentProjects = projects.value.toMutableList()
        val removed = currentProjects.removeIf { it.id == id }
        if (removed) {
            projects.value = currentProjects
            // 删除项目关联的车辆列表
            projectVehicles.remove(id)
        }
        return removed
    }
    
    override fun getProjects(): Flow<List<Project>> {
        return projects.asStateFlow()
    }
    
    override suspend fun getProjectById(id: String): Project? {
        return projects.value.find { it.id == id }
    }
    
    override fun getVehiclesByProjectId(projectId: String): Flow<List<Vehicle>> {
        // 确保项目车辆列表已初始化
        if (!projectVehicles.containsKey(projectId)) {
            projectVehicles[projectId] = MutableStateFlow(emptyList())
        }
        return projectVehicles[projectId]!!.asStateFlow()
    }
    
    // 内部方法，供VehicleRepositoryImpl调用
    internal fun addVehicleToProject(vehicle: Vehicle) {
        val projectId = vehicle.projectId
        if (!projectVehicles.containsKey(projectId)) {
            projectVehicles[projectId] = MutableStateFlow(emptyList())
        }
        
        val currentVehicles = projectVehicles[projectId]!!.value.toMutableList()
        currentVehicles.add(vehicle)
        projectVehicles[projectId]!!.value = currentVehicles
    }
    
    internal fun updateVehicleInProject(vehicle: Vehicle) {
        val projectId = vehicle.projectId
        if (projectVehicles.containsKey(projectId)) {
            val currentVehicles = projectVehicles[projectId]!!.value.toMutableList()
            val index = currentVehicles.indexOfFirst { it.id == vehicle.id }
            if (index != -1) {
                currentVehicles[index] = vehicle
                projectVehicles[projectId]!!.value = currentVehicles
            }
        }
    }
    
    internal fun removeVehicleFromProject(vehicleId: String, projectId: String) {
        if (projectVehicles.containsKey(projectId)) {
            val currentVehicles = projectVehicles[projectId]!!.value.toMutableList()
            val removed = currentVehicles.removeIf { it.id == vehicleId }
            if (removed) {
                projectVehicles[projectId]!!.value = currentVehicles
            }
        }
    }
} 