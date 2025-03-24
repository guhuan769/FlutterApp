package com.camera.photo.system.presentation.state

import com.camera.photo.system.domain.entity.Track
import com.camera.photo.system.domain.entity.TrackPoint

/**
 * 轨迹列表UI状态
 */
data class TrackListState(
    val tracks: List<Track> = emptyList(),
    val vehicleId: String = "",
    val isLoading: Boolean = false,
    val error: String? = null
)

/**
 * 轨迹详情UI状态
 */
data class TrackDetailState(
    val track: Track? = null,
    val trackPoints: List<TrackPoint> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)

/**
 * 轨迹创建/编辑UI状态
 */
data class TrackFormState(
    val vehicleId: String = "",
    val name: String = "",
    val isSubmitting: Boolean = false,
    val nameError: String? = null,
    val generalError: String? = null,
    val isSuccess: Boolean = false
)

/**
 * 轨迹点位UI状态
 */
data class TrackPointState(
    val trackPoint: TrackPoint? = null,
    val isCreating: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null
) 