package com.elon.camera_photo_system.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * 项目实体
 */
@Entity(tableName = "projects")
data class ProjectEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val name: String,
    val description: String,
    val creationDate: Long // 存储时间戳
) 