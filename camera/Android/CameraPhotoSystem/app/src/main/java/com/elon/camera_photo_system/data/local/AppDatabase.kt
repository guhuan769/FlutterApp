package com.elon.camera_photo_system.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
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
    version = 2,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    
    abstract fun photoDao(): PhotoDao
    
    abstract fun projectDao(): ProjectDao
    
    companion object {
        const val DATABASE_NAME = "camera_photo_system.db"
        
        // 从版本1迁移到版本2的迁移策略
        private val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(database: SupportSQLiteDatabase) {
                // 检查表是否存在再进行迁移
                database.execSQL("CREATE TABLE IF NOT EXISTS projects_new (id INTEGER PRIMARY KEY NOT NULL, name TEXT NOT NULL, description TEXT NOT NULL, creationDate TEXT NOT NULL)")
                
                // 有条件地复制数据
                database.execSQL("INSERT OR IGNORE INTO projects_new (id, name, description, creationDate) SELECT id, name, description, creationDate FROM projects WHERE EXISTS (SELECT 1 FROM sqlite_master WHERE type='table' AND name='projects')")
                
                // 安全删除旧表
                database.execSQL("DROP TABLE IF EXISTS projects")
                database.execSQL("ALTER TABLE projects_new RENAME TO projects")
            }
        }
        
        @Volatile
        private var INSTANCE: AppDatabase? = null
        
        fun getInstance(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                try {
                    val instance = Room.databaseBuilder(
                        context.applicationContext,
                        AppDatabase::class.java,
                        DATABASE_NAME
                    )
                    .addMigrations(MIGRATION_1_2)  // 添加迁移策略
                    .build()
                    INSTANCE = instance
                    instance
                } catch (e: Exception) {
                    // 迁移失败，回退到重建数据库
                    Room.databaseBuilder(
                        context.applicationContext,
                        AppDatabase::class.java,
                        DATABASE_NAME
                    )
                    .fallbackToDestructiveMigration()
                    .build()
                }
            }
        }
    }
} 