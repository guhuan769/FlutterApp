package com.elon.camera_photo_system.data.local.dao

import androidx.room.*
import com.elon.camera_photo_system.data.local.entity.ProcessTypeEntity
import kotlinx.coroutines.flow.Flow

/**
 * 工艺类型数据访问对象
 */
@Dao
interface ProcessTypeDao {
    /**
     * 获取所有工艺类型
     */
    @Query("SELECT * FROM process_types ORDER BY name ASC")
    fun getAllProcessTypes(): Flow<List<ProcessTypeEntity>>
    
    /**
     * 根据ID获取工艺类型
     */
    @Query("SELECT * FROM process_types WHERE id = :id")
    suspend fun getProcessTypeById(id: String): ProcessTypeEntity?
    
    /**
     * 插入工艺类型
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertProcessType(processType: ProcessTypeEntity)
    
    /**
     * 更新工艺类型
     */
    @Update
    suspend fun updateProcessType(processType: ProcessTypeEntity)
    
    /**
     * 删除工艺类型
     */
    @Delete
    suspend fun deleteProcessType(processType: ProcessTypeEntity)
    
    /**
     * 获取工艺类型数量
     */
    @Query("SELECT COUNT(*) FROM process_types")
    suspend fun getProcessTypeCount(): Int
    
    /**
     * 检查默认工艺类型是否存在
     */
    @Query("SELECT COUNT(*) FROM process_types WHERE id = :id")
    suspend fun checkDefaultProcessTypeExists(id: String): Int
} 