package com.elon.camera_photo_system.domain.model

import java.time.LocalDateTime

/**
 * 照片领域模型
 */
data class Photo(
    val id: Long = 0,
    val moduleId: Long, // 关联的模块ID（项目/车辆/轨迹ID）
    val moduleType: ModuleType, // 模块类型
    val photoType: PhotoType, // 照片类型
    val filePath: String, // 照片文件路径
    val fileName: String, // 照片文件名
    val photoNumber: Int = 0, // 照片序号
    val angle: Int = 0, // 拍摄角度
    val createdAt: LocalDateTime = LocalDateTime.now(), // 创建时间
    val latitude: Double? = null, // 纬度
    val longitude: Double? = null, // 经度
    val isUploaded: Boolean = false // 是否已上传
) 