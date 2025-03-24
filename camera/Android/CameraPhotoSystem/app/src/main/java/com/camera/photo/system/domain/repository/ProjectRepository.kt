package com.camera.photo.system.domain.repository

import com.camera.photo.system.domain.entity.Project
import com.camera.photo.system.domain.entity.Vehicle
import kotlinx.coroutines.flow.Flow

/**
 * 项目仓库接口
 * 定义项目相关的数据操作
 */
interface ProjectRepository {
    /**
     * 创建新项目
     * @param project 项目信息
     * @return 创建的项目
     */
    suspend fun createProject(project: Project): Project
    
    /**
     * 更新项目信息
     * @param project 更新后的项目信息
     * @return 更新后的项目
     */
    suspend fun updateProject(project: Project): Project
    
    /**
     * 删除项目
     * @param id 项目ID
     * @return 是否删除成功
     */
    suspend fun deleteProject(id: String): Boolean
    
    /**
     * 获取所有项目
     * @return 项目列表流
     */
    fun getProjects(): Flow<List<Project>>
    
    /**
     * 根据ID获取项目
     * @param id 项目ID
     * @return 项目信息，如不存在返回null
     */
    suspend fun getProjectById(id: String): Project?
    
    /**
     * 获取项目下的所有车辆
     * @param projectId 项目ID
     * @return 车辆列表流
     */
    fun getVehiclesByProjectId(projectId: String): Flow<List<Vehicle>>
} 