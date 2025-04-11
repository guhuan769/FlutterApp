package com.elon.camera_photo_system.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.PhotoType
import java.time.LocalDateTime

/**
 * 照片数据库实体
 */
@Entity(tableName = "photos")
data class PhotoEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val moduleId: Long, // 关联的模块ID（项目/车辆/轨迹ID）
    val moduleType: String, // 模块类型，存储枚举字符串值
    val photoType: String, // 照片类型，存储枚举字符串值
    val filePath: String, // 照片文件路径
    val fileName: String, // 照片文件名
    val photoNumber: Int = 0, // 照片序号
    val angle: Int = 0, // 拍摄角度
    val createdAt: String, // 创建时间，ISO格式字符串
    val latitude: Double?, // 纬度
    val longitude: Double?, // 经度
    val isUploaded: Boolean, // 是否已上传
    val uploadPhotoType: String? = null, // 上传照片类型（MODEL/PROCESS）
    val uploadTypeId: String? = null // 上传类型ID（模型ID或工艺ID）
) 