package com.elon.camera_photo_system.presentation.settings

import com.elon.camera_photo_system.domain.model.upload.ModelType
import com.elon.camera_photo_system.domain.model.upload.ProcessType

/**
 * 类型管理界面状态
 */
data class TypeManagementState(
    val modelTypes: List<ModelType> = emptyList(),
    val processTypes: List<ProcessType> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
) 