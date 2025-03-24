package com.camera.photo.system.domain.entity

/**
 * 照片实体类
 * 可以关联到项目、车辆或轨迹点位
 */
data class Photo(
    val id: String,
    val entityId: String,     // 关联实体ID（项目ID、车辆ID或轨迹点位ID）
    val entityType: EntityType, // 关联实体类型
    val path: String,         // 照片存储路径
    val timestamp: Long,      // 创建时间戳
    val photoType: String     // 照片类型（根据实体类型有不同的照片类型）
)

/**
 * 实体类型枚举
 * 标识照片关联的实体类型
 */
enum class EntityType {
    PROJECT,      // 项目
    VEHICLE,      // 车辆
    TRACK_POINT   // 轨迹点
}

/**
 * 项目照片类型
 */
enum class ProjectPhotoType {
    OVERVIEW,      // 项目概览照片
    DOCUMENT,      // 项目文档照片
    SITE_SURVEY    // 项目现场勘察照片
}

/**
 * 车辆照片类型
 */
enum class VehiclePhotoType {
    FRONT,         // 车辆前部照片
    REAR,          // 车辆后部照片
    LEFT_SIDE,     // 车辆左侧照片
    RIGHT_SIDE,    // 车辆右侧照片
    INTERIOR,      // 车辆内部照片
    LICENSE_PLATE  // 车牌照片
} 