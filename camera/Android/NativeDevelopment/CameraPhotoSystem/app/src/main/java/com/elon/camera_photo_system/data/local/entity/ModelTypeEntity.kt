package com.elon.camera_photo_system.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * 模型类型数据库实体
 */
@Entity(tableName = "model_types")
data class ModelTypeEntity(
    @PrimaryKey
    val id: String,
    val name: String,           // 模型名称
    val description: String,    // 模型描述
    val createdAt: Long         // 创建时间
) 