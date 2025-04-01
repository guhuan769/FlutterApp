package com.elon.camera_photo_system.data.local.dao

import androidx.room.*
import com.elon.camera_photo_system.data.local.entity.ProjectEntity

/**
 * 项目数据访问对象接口
 */
@Dao
interface ProjectDao {
    /**
     * 获取所有项目
     */
    @Query("SELECT * FROM projects ORDER BY creationDate DESC")
    suspend fun getAllProjects(): List<ProjectEntity>
    
    /**
     * 根据ID获取项目
     */
    @Query("SELECT * FROM projects WHERE id = :projectId")
    suspend fun getProjectById(projectId: Long): ProjectEntity?
    
    /**
     * 插入项目
     */
    @Insert
    suspend fun insertProject(project: ProjectEntity): Long
    
    /**
     * 更新项目
     */
    @Update
    suspend fun updateProject(project: ProjectEntity)
    
    /**
     * 删除项目
     */
    @Delete
    suspend fun deleteProject(project: ProjectEntity)
} 