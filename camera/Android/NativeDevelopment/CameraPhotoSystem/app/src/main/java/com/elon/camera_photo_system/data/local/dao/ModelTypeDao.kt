package com.elon.camera_photo_system.data.local.dao

import androidx.room.*
import com.elon.camera_photo_system.data.local.entity.ModelTypeEntity
import kotlinx.coroutines.flow.Flow

/**
 * 模型类型数据访问对象
 */
@Dao
interface ModelTypeDao {
    /**
     * 获取所有模型类型
     */
    @Query("SELECT * FROM model_types ORDER BY name ASC")
    fun getAllModelTypes(): Flow<List<ModelTypeEntity>>
    
    /**
     * 根据ID获取模型类型
     */
    @Query("SELECT * FROM model_types WHERE id = :id")
    suspend fun getModelTypeById(id: String): ModelTypeEntity?
    
    /**
     * 插入模型类型
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertModelType(modelType: ModelTypeEntity)
    
    /**
     * 更新模型类型
     */
    @Update
    suspend fun updateModelType(modelType: ModelTypeEntity)
    
    /**
     * 删除模型类型
     */
    @Delete
    suspend fun deleteModelType(modelType: ModelTypeEntity)
    
    /**
     * 获取模型类型数量
     */
    @Query("SELECT COUNT(*) FROM model_types")
    suspend fun getModelTypeCount(): Int
    
    /**
     * 检查默认模型类型是否存在
     */
    @Query("SELECT COUNT(*) FROM model_types WHERE id = :id")
    suspend fun checkDefaultModelTypeExists(id: String): Int
} 