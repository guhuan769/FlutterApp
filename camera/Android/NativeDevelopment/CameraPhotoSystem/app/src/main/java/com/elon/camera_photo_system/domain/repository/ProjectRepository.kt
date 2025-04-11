package com.elon.camera_photo_system.domain.repository

import com.elon.camera_photo_system.domain.model.Project
import kotlinx.coroutines.flow.Flow

/**
 * 项目仓库接口
 */
interface ProjectRepository {
    
    /**
     * 添加项目
     */
    suspend fun addProject(project: Project): Long
    
    /**
     * 创建新项目
     * @param name 项目名称
     * @param description 项目描述
     * @return 新项目ID
     */
    suspend fun createProject(name: String, description: String): Long
    
    /**
     * 获取所有项目
     */
    suspend fun getProjects(): List<Project>
    
    /**
     * 获取所有项目（Flow形式）
     */
    fun getAllProjects(): Flow<List<Project>>
    
    /**
     * 通过ID获取项目
     */
    suspend fun getProjectById(projectId: Long): Project?
    
    /**
     * 更新项目
     */
    suspend fun updateProject(project: Project)
    
    /**
     * 删除项目
     */
    suspend fun deleteProject(project: Project)
} 