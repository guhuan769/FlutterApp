package com.elon.camera_photo_system.data.source.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.elon.camera_photo_system.data.source.local.entity.PhotoEntity
import com.elon.camera_photo_system.util.DateConverter

/**
 * 照片数据库
 */
@Database(
    entities = [PhotoEntity::class],
    version = 1,
    exportSchema = false
)
@TypeConverters(DateConverter::class)
abstract class PhotoDatabase : RoomDatabase() {
    
    /**
     * 获取照片数据访问对象
     */
    abstract fun photoDao(): PhotoDao
} 