package com.elon.camera_photo_system.data.local.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.time.LocalDateTime

/**
 * 轨迹实体类
 */
@Entity(
    tableName = "tracks",
    foreignKeys = [
        ForeignKey(
            entity = VehicleEntity::class,
            parentColumns = ["id"],
            childColumns = ["vehicleId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [
        Index("vehicleId")
    ]
)
data class TrackEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val vehicleId: Long,
    val name: String,
    val length: Double = 0.0,
    val startTime: LocalDateTime = LocalDateTime.now(),
    val endTime: LocalDateTime? = null,
    val photoCount: Int = 0,
    val isStarted: Boolean = true,
    val isEnded: Boolean = false,
    val startPointPhotoCount: Int = 0,
    val middlePointPhotoCount: Int = 0,
    val modelPointPhotoCount: Int = 0,
    val transitionPointPhotoCount: Int = 0,
    val endPointPhotoCount: Int = 0
) 