package com.elon.camera_photo_system.data.repository

import com.elon.camera_photo_system.data.local.dao.ModelTypeDao
import com.elon.camera_photo_system.data.local.entity.ModelTypeEntity
import com.elon.camera_photo_system.domain.model.upload.ModelType
import com.elon.camera_photo_system.domain.repository.ModelTypeRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 模型类型仓库实现
 */
@Singleton
class ModelTypeRepositoryImpl @Inject constructor(
    private val modelTypeDao: ModelTypeDao
) : ModelTypeRepository {
    
    override fun getAllModelTypes(): Flow<List<ModelType>> {
        return modelTypeDao.getAllModelTypes().map { entities ->
            entities.map { it.toModelType() }
        }
    }
    
    override suspend fun getModelTypeById(id: String): ModelType? {
        return modelTypeDao.getModelTypeById(id)?.toModelType()
    }
    
    override suspend fun saveModelType(modelType: ModelType): String {
        val entity = modelType.toModelTypeEntity()
        modelTypeDao.insertModelType(entity)
        return entity.id
    }
    
    override suspend fun updateModelType(modelType: ModelType) {
        modelTypeDao.updateModelType(modelType.toModelTypeEntity())
    }
    
    override suspend fun deleteModelType(modelType: ModelType) {
        // 不允许删除默认类型
        if (modelType.id == ModelType.DEFAULT.id) {
            return
        }
        modelTypeDao.deleteModelType(modelType.toModelTypeEntity())
    }
    
    override suspend fun ensureDefaultModelTypeExists() {
        val count = modelTypeDao.checkDefaultModelTypeExists(ModelType.DEFAULT.id)
        if (count <= 0) {
            saveModelType(ModelType.DEFAULT)
        }
    }
    
    /**
     * 将ModelTypeEntity转换为ModelType
     */
    private fun ModelTypeEntity.toModelType(): ModelType {
        return ModelType(
            id = id,
            name = name,
            description = description,
            createdAt = createdAt
        )
    }
    
    /**
     * 将ModelType转换为ModelTypeEntity
     */
    private fun ModelType.toModelTypeEntity(): ModelTypeEntity {
        return ModelTypeEntity(
            id = id,
            name = name,
            description = description,
            createdAt = createdAt
        )
    }
} 