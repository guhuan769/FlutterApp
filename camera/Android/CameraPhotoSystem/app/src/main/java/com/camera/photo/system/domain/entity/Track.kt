package com.camera.photo.system.domain.entity

/**
 * 轨迹实体类
 * 作为底层实体，属于某个车辆，包含多个轨迹点位
 */
data class Track(
    val id: String,
    val vehicleId: String,    // 关联到车辆
    val name: String,
    val length: Float,
    val startTime: Long,
    val endTime: Long
) 