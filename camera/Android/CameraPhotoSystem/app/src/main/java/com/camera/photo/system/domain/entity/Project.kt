package com.camera.photo.system.domain.entity

/**
 * 项目实体类
 * 作为顶层实体，包含多个车辆
 */
data class Project(
    val id: String,
    val name: String,
    val description: String,
    val createdAt: Long,
    val updatedAt: Long,
    val coverPhotoPath: String?
) 