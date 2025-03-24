package com.camera.photo.system.presentation.state

import com.camera.photo.system.domain.entity.EntityType
import com.camera.photo.system.domain.entity.Photo

/**
 * 照片列表UI状态
 */
data class PhotoListState(
    val photos: List<Photo> = emptyList(),
    val entityId: String = "",
    val entityType: EntityType? = null,
    val photoType: String? = null,
    val isLoading: Boolean = false,
    val error: String? = null
)

/**
 * 照片详情UI状态
 */
data class PhotoDetailState(
    val photo: Photo? = null,
    val isLoading: Boolean = false,
    val error: String? = null
)

/**
 * 照片拍摄UI状态
 */
data class PhotoCaptureState(
    val entityId: String = "",
    val entityType: EntityType? = null,
    val photoType: String? = null,
    val isCapturing: Boolean = false,
    val capturedPhotoPath: String? = null,
    val error: String? = null
) 