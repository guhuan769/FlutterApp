package com.elon.camera_photo_system.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * 工艺类型数据库实体
 */
@Entity(tableName = "process_types")
data class ProcessTypeEntity(
    @PrimaryKey
    val id: String,
    val name: String,           // 工艺名称
    val description: String,    // 工艺描述
    val createdAt: Long         // 创建时间
) 