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
import com.elon.camera_photo_system.data.local.dao.VehicleDao
import com.elon.camera_photo_system.data.local.entity.PhotoEntity
import com.elon.camera_photo_system.data.local.entity.ProjectEntity
import com.elon.camera_photo_system.data.local.entity.TrackEntity
import com.elon.camera_photo_system.data.local.entity.VehicleEntity
import com.elon.camera_photo_system.data.local.util.Converters

/**
 * 应用数据库
 */
@Database(
    entities = [
        PhotoEntity::class,
        ProjectEntity::class,
        VehicleEntity::class,
        TrackEntity::class
    ],
    version = 4,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    
    abstract fun photoDao(): PhotoDao
    
    abstract fun projectDao(): ProjectDao
    
    abstract fun vehicleDao(): VehicleDao
    
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
        
        // 从版本2迁移到版本3的迁移策略
        private val MIGRATION_2_3 = object : Migration(2, 3) {
            override fun migrate(database: SupportSQLiteDatabase) {
                // 创建vehicles表
                database.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS vehicles (
                        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        projectId INTEGER NOT NULL,
                        name TEXT NOT NULL,
                        plateNumber TEXT NOT NULL,
                        brand TEXT NOT NULL,
                        model TEXT NOT NULL,
                        creationDate TEXT NOT NULL,
                        FOREIGN KEY (projectId) REFERENCES projects(id) ON DELETE CASCADE
                    )
                    """
                )
                // 创建索引
                database.execSQL("CREATE INDEX IF NOT EXISTS index_vehicles_projectId ON vehicles(projectId)")
                
                // 为tracks表添加vehicleId外键(如果不存在则创建)
                try {
                    database.execSQL(
                        """
                        CREATE TABLE IF NOT EXISTS tracks (
                            id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                            vehicleId INTEGER NOT NULL,
                            name TEXT NOT NULL,
                            startTime TEXT NOT NULL,
                            endTime TEXT,
                            creationDate TEXT NOT NULL,
                            FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
                        )
                        """
                    )
                    database.execSQL("CREATE INDEX IF NOT EXISTS index_tracks_vehicleId ON tracks(vehicleId)")
                } catch (e: Exception) {
                    // 如果表已存在，可能会抛出异常
                }
                
                // 为photos表添加vehicleId外键(如果已存在则跳过)
                try {
                    // 检查photos表中是否已有vehicleId列
                    val cursor = database.query("PRAGMA table_info(photos)")
                    var hasVehicleId = false
                    while (cursor.moveToNext()) {
                        val columnName = cursor.getString(1)
                        if (columnName == "vehicleId") {
                            hasVehicleId = true
                            break
                        }
                    }
                    cursor.close()
                    
                    // 如果不存在vehicleId列，则添加
                    if (!hasVehicleId) {
                        database.execSQL("ALTER TABLE photos ADD COLUMN vehicleId INTEGER")
                        database.execSQL("CREATE INDEX IF NOT EXISTS index_photos_vehicleId ON photos(vehicleId)")
                    }
                } catch (e: Exception) {
                    // 如果操作失败，记录异常
                }
            }
        }
        
        // 从版本3迁移到版本4的迁移策略
        private val MIGRATION_3_4 = object : Migration(3, 4) {
            override fun migrate(database: SupportSQLiteDatabase) {
                // 确保tracks表存在，如果不存在则创建
                try {
                    val cursor = database.query("SELECT name FROM sqlite_master WHERE type='table' AND name='tracks'")
                    val tableExists = cursor.moveToFirst()
                    cursor.close()
                    
                    if (!tableExists) {
                        // 创建tracks表
                        database.execSQL("""
                            CREATE TABLE IF NOT EXISTS tracks (
                                id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                                vehicleId INTEGER NOT NULL,
                                name TEXT NOT NULL,
                                startTime TEXT NOT NULL,
                                endTime TEXT,
                                length REAL NOT NULL DEFAULT 0.0,
                                creationDate TEXT NOT NULL,
                                FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
                            )
                        """)
                        database.execSQL("CREATE INDEX IF NOT EXISTS index_tracks_vehicleId ON tracks(vehicleId)")
                    } else {
                        // 如果表已存在但缺少length列，添加它
                        try {
                            database.execSQL("ALTER TABLE tracks ADD COLUMN length REAL NOT NULL DEFAULT 0.0")
                        } catch (e: Exception) {
                            // 列可能已存在，忽略错误
                        }
                    }
                } catch (e: Exception) {
                    // 如果检查失败，尝试直接创建表
                    try {
                        database.execSQL("""
                            CREATE TABLE IF NOT EXISTS tracks (
                                id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                                vehicleId INTEGER NOT NULL,
                                name TEXT NOT NULL,
                                startTime TEXT NOT NULL,
                                endTime TEXT,
                                length REAL NOT NULL DEFAULT 0.0,
                                creationDate TEXT NOT NULL,
                                FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
                            )
                        """)
                    } catch (e: Exception) {
                        // 忽略错误
                    }
                }
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
                    .addMigrations(MIGRATION_1_2, MIGRATION_2_3, MIGRATION_3_4)  // 添加迁移策略
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