package com.elon.camera_photo_system.domain.model

import java.time.LocalDateTime

/**
 * 车辆领域模型
 */
data class Vehicle(
    val id: Long,
    val projectId: Long,
    val name: String,
    val plateNumber: String,
    val brand: String = "",
    val model: String = "",
    val creationDate: LocalDateTime = LocalDateTime.now(),
    val trackCount: Int = 0,
    val photoCount: Int = 0
) 