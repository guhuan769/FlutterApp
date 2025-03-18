package com.elon.camera_photo_system.data.source.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.Date

/**
 * 照片数据库实体类
 */
@Entity(tableName = "photos")
data class PhotoEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val uri: String,
    val name: String,
    val type: String,
    val sequence: Int,
    val createTime: Date,
    val projectId: Long? = null,
    val vehicleId: Long? = null,
    val routeId: Long? = null,
    val isUploaded: Boolean = false
) 