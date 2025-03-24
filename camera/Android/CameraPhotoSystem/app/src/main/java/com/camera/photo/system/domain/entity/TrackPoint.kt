package com.camera.photo.system.domain.entity

/**
 * 轨迹点位实体类
 * 轨迹中的关键点位，可以附带照片
 */
data class TrackPoint(
    val id: String,
    val trackId: String,
    val latitude: Double,
    val longitude: Double,
    val altitude: Double?,
    val sequence: Int,
    val timestamp: Long,
    val pointType: TrackPointType
)

/**
 * 轨迹点位类型
 */
enum class TrackPointType {
    START_POINT,      // 起始点
    MIDDLE_POINT,     // 中间点
    MODEL_POINT,      // 模型点
    END_POINT         // 结束点
} 