package com.elon.camera_photo_system.domain.repository

import com.elon.camera_photo_system.domain.model.upload.ProcessType
import kotlinx.coroutines.flow.Flow

/**
 * 工艺类型仓库接口
 */
interface ProcessTypeRepository {
    
    /**
     * 获取所有工艺类型
     */
    fun getAllProcessTypes(): Flow<List<ProcessType>>
    
    /**
     * 根据ID获取工艺类型
     */
    suspend fun getProcessTypeById(id: String): ProcessType?
    
    /**
     * 保存工艺类型
     */
    suspend fun saveProcessType(processType: ProcessType): String
    
    /**
     * 更新工艺类型
     */
    suspend fun updateProcessType(processType: ProcessType)
    
    /**
     * 删除工艺类型
     */
    suspend fun deleteProcessType(processType: ProcessType)
    
    /**
     * 检查是否存在默认工艺类型，如不存在则创建
     */
    suspend fun ensureDefaultProcessTypeExists()
} 