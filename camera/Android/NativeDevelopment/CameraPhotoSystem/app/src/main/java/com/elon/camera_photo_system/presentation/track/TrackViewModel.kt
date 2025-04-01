package com.elon.camera_photo_system.presentation.track

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.elon.camera_photo_system.domain.model.PhotoType
import com.elon.camera_photo_system.domain.model.Track
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import javax.inject.Inject

@HiltViewModel
class TrackViewModel @Inject constructor() : ViewModel() {
    private val _tracksState = MutableStateFlow(TracksState())
    val tracksState: StateFlow<TracksState> = _tracksState.asStateFlow()

    private val _trackState = MutableStateFlow(TrackState())
    val trackState: StateFlow<TrackState> = _trackState.asStateFlow()

    fun loadTracksByVehicle(vehicleId: Long) {
        viewModelScope.launch {
            _tracksState.update { it.copy(isLoading = true, error = null) }
            try {
                // TODO: 实现从数据库加载轨迹列表的逻辑
                _tracksState.update { it.copy(isLoading = false, tracks = emptyList()) }
            } catch (e: Exception) {
                _tracksState.update { it.copy(isLoading = false, error = e.message) }
            }
        }
    }

    fun loadTrack(trackId: Long) {
        viewModelScope.launch {
            _trackState.update { it.copy(isLoading = true, error = null) }
            try {
                // TODO: 实现从数据库加载单个轨迹的逻辑
                _trackState.update { it.copy(isLoading = false, track = null) }
            } catch (e: Exception) {
                _trackState.update { it.copy(isLoading = false, error = e.message) }
            }
        }
    }
    
    /**
     * 开始轨迹记录
     */
    fun startTrack(trackId: Long) {
        viewModelScope.launch {
            _trackState.update { it.copy(isLoading = true, error = null) }
            try {
                // TODO: 实现开始轨迹记录的逻辑
                // 1. 更新数据库中轨迹的开始时间
                // 2. 更新轨迹状态为已开始
                
                // 模拟成功
                val currentTrack = _trackState.value.track
                if (currentTrack != null) {
                    val updatedTrack = currentTrack.copy(
                        isStarted = true,
                        startTime = java.time.LocalDateTime.now()
                    )
                    _trackState.update { it.copy(isLoading = false, track = updatedTrack) }
                } else {
                    _trackState.update { it.copy(
                        isLoading = false, 
                        error = "无法开始轨迹记录，轨迹不存在"
                    ) }
                }
            } catch (e: Exception) {
                _trackState.update { it.copy(
                    isLoading = false, 
                    error = "开始轨迹记录失败: ${e.message}"
                ) }
            }
        }
    }
    
    /**
     * 结束轨迹记录
     */
    fun endTrack(trackId: Long) {
        viewModelScope.launch {
            _trackState.update { it.copy(isLoading = true, error = null) }
            try {
                // TODO: 实现结束轨迹记录的逻辑
                // 1. 更新数据库中轨迹的结束时间
                // 2. 更新轨迹状态为已结束
                // 3. 计算轨迹长度（如果有GPS数据）
                
                // 模拟成功
                val currentTrack = _trackState.value.track
                if (currentTrack != null) {
                    if (!currentTrack.isStarted) {
                        _trackState.update { it.copy(
                            isLoading = false,
                            error = "无法结束轨迹记录，轨迹尚未开始"
                        ) }
                        return@launch
                    }
                    
                    val updatedTrack = currentTrack.copy(
                        isEnded = true,
                        endTime = java.time.LocalDateTime.now()
                    )
                    _trackState.update { it.copy(isLoading = false, track = updatedTrack) }
                } else {
                    _trackState.update { it.copy(
                        isLoading = false, 
                        error = "无法结束轨迹记录，轨迹不存在"
                    ) }
                }
            } catch (e: Exception) {
                _trackState.update { it.copy(
                    isLoading = false, 
                    error = "结束轨迹记录失败: ${e.message}"
                ) }
            }
        }
    }
    
    /**
     * 检查照片类型是否可用
     */
    fun isPhotoTypeAvailable(photoType: PhotoType): Boolean {
        val track = _trackState.value.track ?: return false
        
        return when (photoType) {
            PhotoType.START_POINT -> !track.isStarted
            PhotoType.MIDDLE_POINT -> track.isStarted && !track.isEnded
            PhotoType.MODEL_POINT -> true // 模型点随时可用
            PhotoType.END_POINT -> track.isStarted && !track.isEnded
        }
    }
    
    /**
     * 生成照片文件名
     */
    fun generatePhotoFileName(photoType: PhotoType): String {
        val track = _trackState.value.track ?: return "unknown"
        
        val prefix = when (photoType) {
            PhotoType.START_POINT -> "起始点拍照"
            PhotoType.MIDDLE_POINT -> "中间点拍照"
            PhotoType.MODEL_POINT -> "模型点拍照"
            PhotoType.END_POINT -> "结束点拍照"
        }
        
        val count = when (photoType) {
            PhotoType.START_POINT -> track.startPointPhotoCount
            PhotoType.MIDDLE_POINT -> track.middlePointPhotoCount
            PhotoType.MODEL_POINT -> track.modelPointPhotoCount
            PhotoType.END_POINT -> track.endPointPhotoCount
        }
        
        return "${prefix}_${count + 1}"
    }
    
    /**
     * 拍照完成后更新照片计数
     */
    fun updatePhotoCount(photoType: PhotoType) {
        viewModelScope.launch {
            val currentTrack = _trackState.value.track ?: return@launch
            
            val updatedTrack = when (photoType) {
                PhotoType.START_POINT -> currentTrack.copy(
                    startPointPhotoCount = currentTrack.startPointPhotoCount + 1
                )
                PhotoType.MIDDLE_POINT -> currentTrack.copy(
                    middlePointPhotoCount = currentTrack.middlePointPhotoCount + 1
                )
                PhotoType.MODEL_POINT -> currentTrack.copy(
                    modelPointPhotoCount = currentTrack.modelPointPhotoCount + 1
                )
                PhotoType.END_POINT -> currentTrack.copy(
                    endPointPhotoCount = currentTrack.endPointPhotoCount + 1
                )
            }
            
            _trackState.update { it.copy(track = updatedTrack) }
        }
    }
}

data class TracksState(
    val tracks: List<Track> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)

data class TrackState(
    val track: Track? = null,
    val isLoading: Boolean = false,
    val error: String? = null
) 