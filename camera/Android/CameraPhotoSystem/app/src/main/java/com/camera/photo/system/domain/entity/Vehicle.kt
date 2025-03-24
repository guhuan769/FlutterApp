package com.camera.photo.system.domain.entity

/**
 * 车辆实体类
 * 作为中层实体，属于某个项目，包含多个轨迹
 */
data class Vehicle(
    val id: String,
    val projectId: String,    // 关联到项目
    val name: String,
    val licensePlate: String,
    val model: String,
    val createdAt: Long
) 