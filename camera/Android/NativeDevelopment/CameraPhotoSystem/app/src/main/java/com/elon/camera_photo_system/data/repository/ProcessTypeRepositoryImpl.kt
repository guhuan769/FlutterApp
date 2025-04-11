package com.elon.camera_photo_system.data.repository

import com.elon.camera_photo_system.data.local.dao.ProcessTypeDao
import com.elon.camera_photo_system.data.local.entity.ProcessTypeEntity
import com.elon.camera_photo_system.domain.model.upload.ProcessType
import com.elon.camera_photo_system.domain.repository.ProcessTypeRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 工艺类型仓库实现
 */
@Singleton
class ProcessTypeRepositoryImpl @Inject constructor(
    private val processTypeDao: ProcessTypeDao
) : ProcessTypeRepository {
    
    override fun getAllProcessTypes(): Flow<List<ProcessType>> {
        return processTypeDao.getAllProcessTypes().map { entities ->
            entities.map { it.toProcessType() }
        }
    }
    
    override suspend fun getProcessTypeById(id: String): ProcessType? {
        return processTypeDao.getProcessTypeById(id)?.toProcessType()
    }
    
    override suspend fun saveProcessType(processType: ProcessType): String {
        val entity = processType.toProcessTypeEntity()
        processTypeDao.insertProcessType(entity)
        return entity.id
    }
    
    override suspend fun updateProcessType(processType: ProcessType) {
        processTypeDao.updateProcessType(processType.toProcessTypeEntity())
    }
    
    override suspend fun deleteProcessType(processType: ProcessType) {
        // 不允许删除默认类型
        if (processType.id == ProcessType.DEFAULT.id) {
            return
        }
        processTypeDao.deleteProcessType(processType.toProcessTypeEntity())
    }
    
    override suspend fun ensureDefaultProcessTypeExists() {
        val count = processTypeDao.checkDefaultProcessTypeExists(ProcessType.DEFAULT.id)
        if (count <= 0) {
            saveProcessType(ProcessType.DEFAULT)
        }
    }
    
    /**
     * 将ProcessTypeEntity转换为ProcessType
     */
    private fun ProcessTypeEntity.toProcessType(): ProcessType {
        return ProcessType(
            id = id,
            name = name,
            description = description,
            createdAt = createdAt
        )
    }
    
    /**
     * 将ProcessType转换为ProcessTypeEntity
     */
    private fun ProcessType.toProcessTypeEntity(): ProcessTypeEntity {
        return ProcessTypeEntity(
            id = id,
            name = name,
            description = description,
            createdAt = createdAt
        )
    }
} 