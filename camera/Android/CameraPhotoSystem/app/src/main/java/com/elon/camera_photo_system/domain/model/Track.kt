package com.elon.camera_photo_system.domain.model

import java.time.LocalDateTime

/**
 * 轨迹领域模型
 */
data class Track(
    val id: Long,
    val vehicleId: Long,
    val name: String,
    val length: Double = 0.0, // 轨迹长度（公里）
    val startTime: LocalDateTime = LocalDateTime.now(),
    val endTime: LocalDateTime? = null,
    val photoCount: Int = 0,
    val isStarted: Boolean = startTime != null,
    val isEnded: Boolean = endTime != null,
    val startPointPhotoCount: Int = 0,
    val middlePointPhotoCount: Int = 0,
    val modelPointPhotoCount: Int = 0,
    val endPointPhotoCount: Int = 0
) {
    val totalPhotoCount: Int
        get() = startPointPhotoCount + middlePointPhotoCount + modelPointPhotoCount + endPointPhotoCount
} 