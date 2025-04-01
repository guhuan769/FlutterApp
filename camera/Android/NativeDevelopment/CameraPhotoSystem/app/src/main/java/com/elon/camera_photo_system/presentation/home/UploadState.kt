package com.elon.camera_photo_system.presentation.home

import com.elon.camera_photo_system.domain.model.Project

/**
 * 上传状态
 */
data class UploadState(
    val isUploading: Boolean = false,
    val currentProject: Project? = null,
    val isSuccess: Boolean = false,
    val error: String? = null
) 