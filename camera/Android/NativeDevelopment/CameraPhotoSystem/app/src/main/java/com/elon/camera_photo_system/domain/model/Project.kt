package com.elon.camera_photo_system.domain.model

import java.time.LocalDateTime

/**
 * 项目领域模型
 */
data class Project(
    val id: Long,
    val name: String,
    val description: String = "",
    val creationDate: LocalDateTime = LocalDateTime.now(),
    val vehicleCount: Int = 0,
    val photoCount: Int = 0
) 