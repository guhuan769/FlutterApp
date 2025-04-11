package com.elon.camera_photo_system.presentation.home.state

import com.elon.camera_photo_system.domain.model.Project

/**
 * 上传状态
 */
data class UploadState(
    val isUploading: Boolean = false,
    val isSuccess: Boolean = false,
    val error: String? = null,
    val currentProject: Project? = null,
    val progress: Float = 0f, // 上传进度 (0-1)
    val uploadedCount: Int = 0, // 已上传数量
    val totalCount: Int = 0, // 总数量
    
    // 添加分层级的上传信息
    val currentModuleType: String = "", // 当前正在上传的模块类型：项目/车辆/轨迹
    val currentModuleName: String = "", // 当前正在上传的模块名称
    
    // 分层级的照片计数
    val projectPhotosCount: Int = 0,    // 项目照片数量
    val vehiclePhotosCount: Int = 0,    // 车辆照片数量
    val trackPhotosCount: Int = 0,      // 轨迹照片数量
    
    // 分层级的已上传计数
    val projectUploadedCount: Int = 0,  // 已上传项目照片数量
    val vehicleUploadedCount: Int = 0,  // 已上传车辆照片数量
    val trackUploadedCount: Int = 0,    // 已上传轨迹照片数量
    
    // 上传照片类型信息
    val selectedUploadPhotoType: String = "", // 选择的上传照片类型 (MODEL/PROCESS)
    val selectedUploadTypeId: String = "",    // 选择的上传类型ID
    val selectedUploadTypeName: String = ""   // 选择的上传类型名称
) 