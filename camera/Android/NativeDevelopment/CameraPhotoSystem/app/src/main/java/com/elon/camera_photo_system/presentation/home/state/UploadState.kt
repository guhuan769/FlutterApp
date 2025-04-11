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
    val totalCount: Int = 0 // 总数量
) 