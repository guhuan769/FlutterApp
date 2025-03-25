package com.camera.photo.system.domain.model

import java.io.File
import java.util.Date

/**
 * 照片领域模型
 * 
 * @property id 照片唯一标识
 * @property path 照片文件路径
 * @property timestamp 拍摄时间戳
 * @property width 照片宽度
 * @property height 照片高度
 * @property size 照片大小(字节)
 * @property type 照片类型，用于区分不同场景下的照片
 */
data class Photo(
    val id: String,
    val path: String,
    val timestamp: Date,
    val width: Int = 0,
    val height: Int = 0,
    val size: Long = 0,
    val type: PhotoType
) {
    /**
     * 获取照片文件对象
     */
    fun getFile(): File = File(path)
    
    /**
     * 检查照片文件是否存在
     */
    fun exists(): Boolean = getFile().exists()
    
    /**
     * 获取照片格式化时间
     */
    fun getFormattedDate(): String {
        // 简单格式化，实际项目中可以使用DateFormat或SimpleDateFormat
        return timestamp.toString()
    }
}

/**
 * 照片类型枚举
 * 用于区分不同场景下的拍照类型
 */
enum class PhotoType {
    // 项目相关照片类型
    PROJECT_MODEL,    // 项目模型照片
    PROJECT_SITE,     // 项目现场照片
    PROJECT_DOCUMENT, // 项目文档照片
    
    // 车辆相关照片类型
    VEHICLE,          // 车辆照片
    VEHICLE_FRONT,    // 车辆前部照片
    VEHICLE_REAR,     // 车辆后部照片
    VEHICLE_SIDE,     // 车辆侧面照片
    VEHICLE_PLATE,    // 车辆车牌照片
    
    // 轨迹相关照片类型
    TRACK_START,      // 轨迹起始点照片
    TRACK_MIDDLE,     // 轨迹中间点照片
    TRACK_MODEL,      // 轨迹模型点照片
    TRACK_END         // 轨迹结束点照片
} 