package com.elon.camera_photo_system.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.elon.camera_photo_system.data.local.dao.PhotoDao
import com.elon.camera_photo_system.data.local.dao.ProjectDao
import com.elon.camera_photo_system.data.local.entity.PhotoEntity
import com.elon.camera_photo_system.data.local.entity.ProjectEntity
import com.elon.camera_photo_system.data.local.util.Converters

/**
 * 应用数据库
 */
@Database(
    entities = [
        PhotoEntity::class,
        ProjectEntity::class
    ],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    
    abstract fun photoDao(): PhotoDao
    
    abstract fun projectDao(): ProjectDao
    
    companion object {
        const val DATABASE_NAME = "camera_photo_system.db"
    }
} 