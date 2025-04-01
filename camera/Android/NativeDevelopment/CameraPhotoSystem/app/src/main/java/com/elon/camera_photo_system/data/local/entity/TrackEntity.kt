package com.elon.camera_photo_system.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.LocalDateTime

/**
 * 轨迹数据库实体
 */
@Entity(tableName = "tracks")
data class TrackEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val vehicleId: Long,
    val name: String,
    val startTime: String, // LocalDateTime以字符串形式存储
    val endTime: String? = null,
    val length: Double = 0.0,
    val creationDate: String // LocalDateTime以字符串形式存储
) 