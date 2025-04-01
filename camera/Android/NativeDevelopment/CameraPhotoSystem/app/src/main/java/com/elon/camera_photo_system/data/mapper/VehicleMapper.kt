package com.elon.camera_photo_system.data.mapper

import com.elon.camera_photo_system.data.local.dao.VehicleWithCounts
import com.elon.camera_photo_system.data.local.entity.VehicleEntity
import com.elon.camera_photo_system.domain.model.Vehicle

/**
 * 车辆数据映射器
 */
object VehicleMapper {
    /**
     * 将VehicleEntity转换为Vehicle领域模型
     */
    fun VehicleEntity.toDomain(): Vehicle {
        return Vehicle(
            id = id,
            projectId = projectId,
            name = name,
            plateNumber = plateNumber,
            brand = brand,
            model = model,
            creationDate = creationDate
        )
    }
    
    /**
     * 将Vehicle领域模型转换为VehicleEntity
     */
    fun Vehicle.toEntity(): VehicleEntity {
        return VehicleEntity(
            id = id,
            projectId = projectId,
            name = name,
            plateNumber = plateNumber,
            brand = brand,
            model = model,
            creationDate = creationDate
        )
    }
    
    /**
     * 将VehicleWithCounts转换为Vehicle领域模型
     */
    fun VehicleWithCounts.toDomain(): Vehicle {
        return Vehicle(
            id = id,
            projectId = projectId,
            name = name,
            plateNumber = plateNumber,
            brand = brand,
            model = model,
            creationDate = creationDate,
            photoCount = photoCount,
            trackCount = trackCount
        )
    }
} 