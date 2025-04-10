package com.elon.camera_photo_system.domain.model

import com.elon.camera_photo_system.presentation.project.ProjectStatus
import java.time.LocalDateTime

/**
 * 项目领域模型
 */
data class Project(
    val id: Long,
    val name: String,
    val description: String = "",
    val location: String = "",
    val createdAt: LocalDateTime = LocalDateTime.now(),
    val vehicleCount: Int = 0,
    val trackCount: Int = 0,
    val photoCount: Int = 0,
    val status: ProjectStatus = ProjectStatus.ACTIVE
) 