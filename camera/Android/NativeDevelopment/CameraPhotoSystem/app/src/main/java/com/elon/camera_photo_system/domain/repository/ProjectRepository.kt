package com.elon.camera_photo_system.domain.repository

import com.elon.camera_photo_system.domain.model.Project

/**
 * 项目仓库接口
 */
interface ProjectRepository {
    
    /**
     * 添加项目
     */
    suspend fun addProject(project: Project): Long
    
    /**
     * 获取所有项目
     */
    suspend fun getProjects(): List<Project>
    
    /**
     * 通过ID获取项目
     */
    suspend fun getProjectById(projectId: Long): Project?
    
    /**
     * 更新项目
     */
    suspend fun updateProject(project: Project)
} 