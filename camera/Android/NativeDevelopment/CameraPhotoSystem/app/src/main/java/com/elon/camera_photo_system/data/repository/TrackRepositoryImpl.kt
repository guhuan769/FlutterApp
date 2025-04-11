package com.elon.camera_photo_system.data.repository

import com.elon.camera_photo_system.data.local.dao.TrackDao
import com.elon.camera_photo_system.data.mapper.TrackMapper.toDomain
import com.elon.camera_photo_system.data.mapper.TrackMapper.toEntity
import com.elon.camera_photo_system.domain.model.Track
import com.elon.camera_photo_system.domain.repository.TrackRepository
import com.elon.camera_photo_system.domain.repository.PhotoRepository
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.PhotoType
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import android.util.Log

/**
 * 轨迹仓库实现类
 */
class TrackRepositoryImpl @Inject constructor(
    private val trackDao: TrackDao,
    private val photoRepository: PhotoRepository
) : TrackRepository {
    
    override fun getTracksByVehicle(vehicleId: Long): Flow<List<Track>> {
        return trackDao.getTracksByVehicle(vehicleId)
            .map { tracks -> tracks.map { it.toDomain() } }
    }
    
    override fun getTrackById(trackId: Long): Flow<Track?> {
        return trackDao.getTrackById(trackId)
            .map { it?.toDomain() }
    }
    
    override suspend fun addTrack(track: Track): Long {
        return trackDao.insert(track.toEntity())
    }
    
    override suspend fun updateTrack(track: Track) {
        trackDao.update(track.toEntity())
    }
    
    override suspend fun deleteTrack(track: Track) {
        trackDao.delete(track.toEntity())
    }
    
    override suspend fun startTrack(trackId: Long) {
        trackDao.startTrack(trackId)
    }
    
    override suspend fun endTrack(trackId: Long) {
        trackDao.endTrack(trackId)
    }
    
    override suspend fun updateTrackPhotoCount(
        trackId: Long,
        startPointCount: Int?,
        middlePointCount: Int?,
        modelPointCount: Int?,
        transitionPointCount: Int?,
        endPointCount: Int?
    ) {
        // 更新各个点的照片数量
        startPointCount?.let { trackDao.updateStartPointPhotoCount(trackId, it) }
        middlePointCount?.let { trackDao.updateMiddlePointPhotoCount(trackId, it) }
        modelPointCount?.let { trackDao.updateModelPointPhotoCount(trackId, it) }
        transitionPointCount?.let { trackDao.updateTransitionPointPhotoCount(trackId, it) }
        endPointCount?.let { trackDao.updateEndPointPhotoCount(trackId, it) }
        
        // 计算并更新总照片数量
        val track = trackDao.getTrackById(trackId).map { it?.toDomain() }.first() ?: return
        val totalCount = track.totalPhotoCount
        trackDao.updatePhotoCount(trackId, totalCount)
    }
    
    override suspend fun getTrackWithPhotoCounts(trackId: Long): Track? {
        return try {
            val trackEntity = trackDao.getTrackById(trackId).first() ?: return null
            val track = trackEntity.toDomain()
            
            // 从照片仓库获取实际的照片计数
            val startCount = photoRepository.getPhotoCountByType(trackId, ModuleType.TRACK, PhotoType.START_POINT)
            val middleCount = photoRepository.getPhotoCountByType(trackId, ModuleType.TRACK, PhotoType.MIDDLE_POINT)
            val modelCount = photoRepository.getPhotoCountByType(trackId, ModuleType.TRACK, PhotoType.MODEL_POINT)
            val transitionCount = photoRepository.getPhotoCountByType(trackId, ModuleType.TRACK, PhotoType.TRANSITION_POINT)
            val endCount = photoRepository.getPhotoCountByType(trackId, ModuleType.TRACK, PhotoType.END_POINT)
            
            // 更新轨迹的照片计数
            updateTrackPhotoCount(
                trackId = trackId,
                startPointCount = startCount,
                middlePointCount = middleCount,
                modelPointCount = modelCount,
                transitionPointCount = transitionCount,
                endPointCount = endCount
            )
            
            // 重新获取更新后的轨迹
            trackDao.getTrackById(trackId).first()?.toDomain()
        } catch (e: Exception) {
            Log.e("TrackRepository", "获取轨迹详情失败: $trackId", e)
            null
        }
    }
} 