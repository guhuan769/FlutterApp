package com.elon.camera_photo_system.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import com.elon.camera_photo_system.data.local.entity.ProjectEntity

/**
 * 项目DAO
 */
@Dao
interface ProjectDao {
    @Insert
    suspend fun insertProject(project: ProjectEntity): Long
    
    @Query("SELECT * FROM projects ORDER BY creationDate DESC")
    suspend fun getAllProjects(): List<ProjectEntity>
    
    // 其他必要的查询方法
} 