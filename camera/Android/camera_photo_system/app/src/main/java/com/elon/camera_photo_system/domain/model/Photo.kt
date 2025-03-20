package com.elon.camera_photo_system.domain.model

import android.net.Uri
import java.util.Date

/**
 * 照片实体类，表示一张照片的基本信息
 * @property id 照片唯一标识
 * @property uri 照片Uri
 * @property name 照片名称
 * @property type 照片类型
 * @property sequence 序列号
 * @property createTime 创建时间
 * @property projectId 关联项目ID（可选）
 * @property vehicleId 关联车辆ID（可选）
 * @property routeId 关联轨迹ID（可选）
 * @property isUploaded 是否已上传
 */
data class Photo(
    val id: Long = 0,
    val uri: Uri,
    val name: String,
    val type: PhotoType,
    val sequence: Int,
    val createTime: Date = Date(),
    val projectId: Long? = null,
    val vehicleId: Long? = null,
    val routeId: Long? = null,
    val isUploaded: Boolean = false
) 