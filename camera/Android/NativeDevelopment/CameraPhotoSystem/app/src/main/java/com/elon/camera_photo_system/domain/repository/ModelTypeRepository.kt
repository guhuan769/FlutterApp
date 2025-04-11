package com.elon.camera_photo_system.domain.repository

import com.elon.camera_photo_system.domain.model.upload.ModelType
import kotlinx.coroutines.flow.Flow

/**
 * 模型类型仓库接口
 */
interface ModelTypeRepository {
    
    /**
     * 获取所有模型类型
     */
    fun getAllModelTypes(): Flow<List<ModelType>>
    
    /**
     * 根据ID获取模型类型
     */
    suspend fun getModelTypeById(id: String): ModelType?
    
    /**
     * 保存模型类型
     */
    suspend fun saveModelType(modelType: ModelType): String
    
    /**
     * 更新模型类型
     */
    suspend fun updateModelType(modelType: ModelType)
    
    /**
     * 删除模型类型
     */
    suspend fun deleteModelType(modelType: ModelType)
    
    /**
     * 检查是否存在默认模型类型，如不存在则创建
     */
    suspend fun ensureDefaultModelTypeExists()
} 