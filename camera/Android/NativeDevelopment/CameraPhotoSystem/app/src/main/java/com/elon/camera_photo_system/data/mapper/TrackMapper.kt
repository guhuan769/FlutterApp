package com.elon.camera_photo_system.data.mapper

import com.elon.camera_photo_system.data.local.entity.TrackEntity
import com.elon.camera_photo_system.domain.model.Track

/**
 * 轨迹数据映射器
 */
object TrackMapper {
    /**
     * 将实体转换为领域模型
     */
    fun TrackEntity.toDomain(): Track {
        return Track(
            id = id,
            vehicleId = vehicleId,
            name = name,
            length = length,
            startTime = startTime,
            endTime = endTime,
            photoCount = photoCount,
            isStarted = isStarted,
            isEnded = isEnded,
            startPointPhotoCount = startPointPhotoCount,
            middlePointPhotoCount = middlePointPhotoCount,
            modelPointPhotoCount = modelPointPhotoCount,
            endPointPhotoCount = endPointPhotoCount
        )
    }

    /**
     * 将领域模型转换为实体
     */
    fun Track.toEntity(): TrackEntity {
        return TrackEntity(
            id = id,
            vehicleId = vehicleId,
            name = name,
            length = length,
            startTime = startTime,
            endTime = endTime,
            photoCount = photoCount,
            isStarted = isStarted,
            isEnded = isEnded,
            startPointPhotoCount = startPointPhotoCount,
            middlePointPhotoCount = middlePointPhotoCount,
            modelPointPhotoCount = modelPointPhotoCount,
            endPointPhotoCount = endPointPhotoCount
        )
    }
} 