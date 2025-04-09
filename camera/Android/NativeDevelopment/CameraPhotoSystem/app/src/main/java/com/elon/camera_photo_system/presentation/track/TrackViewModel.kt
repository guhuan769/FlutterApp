package com.elon.camera_photo_system.presentation.track

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.elon.camera_photo_system.domain.model.PhotoType
import com.elon.camera_photo_system.domain.model.Track
import com.elon.camera_photo_system.domain.repository.TrackRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import javax.inject.Inject

@HiltViewModel
class TrackViewModel @Inject constructor(
    private val trackRepository: TrackRepository
) : ViewModel() {
    private val _tracksState = MutableStateFlow(TracksState())
    val tracksState: StateFlow<TracksState> = _tracksState.asStateFlow()

    private val _trackState = MutableStateFlow(TrackState())
    val trackState: StateFlow<TrackState> = _trackState.asStateFlow()

    // 添加轨迹状态
    private val _addTrackState = MutableStateFlow(AddTrackState())
    val addTrackState: StateFlow<AddTrackState> = _addTrackState.asStateFlow()

    fun loadTracksByVehicle(vehicleId: Long) {
        viewModelScope.launch {
            _tracksState.update { it.copy(isLoading = true, error = null) }
            try {
                trackRepository.getTracksByVehicle(vehicleId).collect { tracks ->
                    _tracksState.update { it.copy(isLoading = false, tracks = tracks) }
                }
            } catch (e: Exception) {
                _tracksState.update { it.copy(isLoading = false, error = e.message) }
            }
        }
    }

    fun loadTrack(trackId: Long) {
        viewModelScope.launch {
            _trackState.update { it.copy(isLoading = true, error = null) }
            try {
                // 使用getTrackWithPhotoCounts方法获取完整照片数据
                val track = trackRepository.getTrackWithPhotoCounts(trackId)
                _trackState.update { it.copy(track = track, isLoading = false) }
            } catch (e: Exception) {
                _trackState.update { it.copy(isLoading = false, error = e.message) }
            }
        }
    }
    
    /**
     * 创建轨迹
     */
    fun createTrack(name: String, vehicleId: Long) {
        if (name.isBlank()) {
            _addTrackState.update { it.copy(nameError = "轨迹名称不能为空") }
            return
        }
        
        _addTrackState.update { 
            it.copy(
                isSubmitting = true,
                error = null,
                nameError = null
            ) 
        }
        
        viewModelScope.launch {
            try {
                // 创建轨迹
                val newTrack = Track(
                    id = 0,
                    vehicleId = vehicleId,
                    name = name,
                    startTime = LocalDateTime.now(),
                    isStarted = false, // 先创建为未开始状态
                    endTime = null,
                    isEnded = false,
                    length = 0.0,
                    photoCount = 0,
                    startPointPhotoCount = 0,
                    middlePointPhotoCount = 0,
                    modelPointPhotoCount = 0,
                    endPointPhotoCount = 0
                )
                
                val trackId = trackRepository.addTrack(newTrack)
                
                // 重新加载轨迹列表
                loadTracksByVehicle(vehicleId)
                
                // 更新状态
                _addTrackState.update { 
                    it.copy(
                        isSubmitting = false,
                        isSuccess = true,
                        name = "",
                        createdTrackId = trackId
                    ) 
                }
            } catch (e: Exception) {
                _addTrackState.update { 
                    it.copy(
                        isSubmitting = false,
                        error = "创建轨迹失败: ${e.message}"
                    ) 
                }
            }
        }
    }
    
    /**
     * 重置添加轨迹状态
     */
    fun resetAddTrackState() {
        _addTrackState.update {
            AddTrackState()
        }
    }
    
    /**
     * 更新添加轨迹字段
     */
    fun updateAddTrackField(field: AddTrackField, value: String) {
        when (field) {
            AddTrackField.NAME -> {
                _addTrackState.update { 
                    it.copy(
                        name = value,
                        nameError = if (value.isBlank()) "轨迹名称不能为空" else null
                    ) 
                }
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
                trackRepository.startTrack(trackId)
                
                // 刷新轨迹状态
                loadTrack(trackId)
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
                trackRepository.endTrack(trackId)
                
                // 刷新轨迹状态
                loadTrack(trackId)
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
            
            try {
                when (photoType) {
                    PhotoType.START_POINT -> {
                        trackRepository.updateTrackPhotoCount(
                            trackId = currentTrack.id,
                            startPointCount = currentTrack.startPointPhotoCount + 1
                        )
                    }
                    PhotoType.MIDDLE_POINT -> {
                        trackRepository.updateTrackPhotoCount(
                            trackId = currentTrack.id,
                            middlePointCount = currentTrack.middlePointPhotoCount + 1
                        )
                    }
                    PhotoType.MODEL_POINT -> {
                        trackRepository.updateTrackPhotoCount(
                            trackId = currentTrack.id,
                            modelPointCount = currentTrack.modelPointPhotoCount + 1
                        )
                    }
                    PhotoType.END_POINT -> {
                        trackRepository.updateTrackPhotoCount(
                            trackId = currentTrack.id,
                            endPointCount = currentTrack.endPointPhotoCount + 1
                        )
                    }
                }
                
                // 刷新轨迹数据
                loadTrack(currentTrack.id)
            } catch (e: Exception) {
                _trackState.update { it.copy(error = "更新照片计数失败: ${e.message}") }
            }
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

data class AddTrackState(
    val name: String = "",
    val nameError: String? = null,
    val isSubmitting: Boolean = false,
    val isSuccess: Boolean = false,
    val error: String? = null,
    val createdTrackId: Long = -1
)

enum class AddTrackField {
    NAME
} 