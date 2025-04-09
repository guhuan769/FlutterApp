package com.elon.camera_photo_system.data.repository

import com.elon.camera_photo_system.data.local.dao.TrackDao
import com.elon.camera_photo_system.data.mapper.TrackMapper.toDomain
import com.elon.camera_photo_system.data.mapper.TrackMapper.toEntity
import com.elon.camera_photo_system.domain.model.Track
import com.elon.camera_photo_system.domain.repository.TrackRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import javax.inject.Inject

/**
 * 轨迹仓库实现类
 */
class TrackRepositoryImpl @Inject constructor(
    private val trackDao: TrackDao
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
        endPointCount: Int?
    ) {
        // 更新各个点的照片数量
        startPointCount?.let { trackDao.updateStartPointPhotoCount(trackId, it) }
        middlePointCount?.let { trackDao.updateMiddlePointPhotoCount(trackId, it) }
        modelPointCount?.let { trackDao.updateModelPointPhotoCount(trackId, it) }
        endPointCount?.let { trackDao.updateEndPointPhotoCount(trackId, it) }
        
        // 计算并更新总照片数量
        val track = trackDao.getTrackById(trackId).map { it?.toDomain() }.first() ?: return
        val totalCount = track.totalPhotoCount
        trackDao.updatePhotoCount(trackId, totalCount)
    }
    
    override suspend fun getTrackWithPhotoCounts(trackId: Long): Track? {
        val trackEntity = trackDao.getTrackById(trackId).first() ?: return null
        return trackEntity.toDomain()
    }
} 