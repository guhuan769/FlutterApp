package com.elon.camera_photo_system.data.local.dao

import androidx.room.*
import com.elon.camera_photo_system.data.local.entity.VehicleEntity
import kotlinx.coroutines.flow.Flow
import java.time.LocalDateTime

/**
 * 车辆数据访问对象
 */
@Dao
interface VehicleDao {
    /**
     * 获取特定项目下的所有车辆
     */
    @Query("SELECT v.*, " +
            "(SELECT COUNT(*) FROM photos WHERE moduleId = v.id AND moduleType = 'VEHICLE') as photoCount, " +
            "(SELECT COUNT(*) FROM tracks WHERE vehicleId = v.id) as trackCount " +
            "FROM vehicles v WHERE v.projectId = :projectId")
    fun getVehiclesByProject(projectId: Long): Flow<List<VehicleWithCounts>>

    /**
     * 根据ID获取车辆
     */
    @Query("SELECT v.*, " +
            "(SELECT COUNT(*) FROM photos WHERE moduleId = v.id AND moduleType = 'VEHICLE') as photoCount, " +
            "(SELECT COUNT(*) FROM tracks WHERE vehicleId = v.id) as trackCount " +
            "FROM vehicles v WHERE v.id = :vehicleId")
    fun getVehicleById(vehicleId: Long): Flow<VehicleWithCounts?>

    /**
     * 插入车辆
     */
    @Insert
    suspend fun insert(vehicle: VehicleEntity): Long

    /**
     * 更新车辆
     */
    @Update
    suspend fun update(vehicle: VehicleEntity)

    /**
     * 删除车辆
     */
    @Delete
    suspend fun delete(vehicle: VehicleEntity)
}

/**
 * 带统计数据的车辆
 */
data class VehicleWithCounts(
    val id: Long,
    val projectId: Long,
    val name: String,
    val plateNumber: String,
    val brand: String,
    val model: String,
    val creationDate: LocalDateTime,
    val photoCount: Int = 0,
    val trackCount: Int = 0
) 