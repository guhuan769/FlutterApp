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
import com.elon.camera_photo_system.data.local.dao.TrackDao
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
    version = 7,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    
    abstract fun photoDao(): PhotoDao
    
    abstract fun projectDao(): ProjectDao
    
    abstract fun vehicleDao(): VehicleDao
    
    abstract fun trackDao(): TrackDao
    
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
        
        private val MIGRATION_4_6 = object : Migration(4, 6) {
            override fun migrate(database: SupportSQLiteDatabase) {
                // 从版本4升级到版本6的迁移逻辑
                // 可以添加后续的迁移逻辑
            }
        }
        
        private val MIGRATION_6_4 = object : Migration(6, 4) {
            override fun migrate(database: SupportSQLiteDatabase) {
                // 从版本6降级到版本4的迁移逻辑
                // 通常降级是危险的，但如果需要支持，这里提供框架
            }
        }

        // 添加从版本6迁移到版本7的迁移策略
        private val MIGRATION_6_7 = object : Migration(6, 7) {
            override fun migrate(database: SupportSQLiteDatabase) {
                // 使用重建表的方式确保所有列都存在并且类型正确
                try {
                    // 1. 创建临时表
                    database.execSQL("""
                        CREATE TABLE IF NOT EXISTS tracks_new (
                            id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                            vehicleId INTEGER NOT NULL,
                            name TEXT NOT NULL,
                            startTime TEXT NOT NULL,
                            endTime TEXT,
                            length REAL NOT NULL DEFAULT 0.0,
                            isStarted INTEGER NOT NULL DEFAULT 1,
                            isEnded INTEGER NOT NULL DEFAULT 0,
                            photoCount INTEGER NOT NULL DEFAULT 0,
                            startPointPhotoCount INTEGER NOT NULL DEFAULT 0,
                            middlePointPhotoCount INTEGER NOT NULL DEFAULT 0,
                            modelPointPhotoCount INTEGER NOT NULL DEFAULT 0,
                            endPointPhotoCount INTEGER NOT NULL DEFAULT 0,
                            FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
                        )
                    """)
                    
                    // 2. 复制现有数据到新表，不存在的列使用默认值
                    database.execSQL("""
                        INSERT OR IGNORE INTO tracks_new (id, vehicleId, name, startTime, endTime, length)
                        SELECT id, vehicleId, name, startTime, endTime, COALESCE(length, 0.0) 
                        FROM tracks
                    """)
                    
                    // 3. 删除旧表
                    database.execSQL("DROP TABLE IF EXISTS tracks")
                    
                    // 4. 重命名新表为正确的表名
                    database.execSQL("ALTER TABLE tracks_new RENAME TO tracks")
                    
                    // 5. 重建索引
                    database.execSQL("CREATE INDEX IF NOT EXISTS index_tracks_vehicleId ON tracks(vehicleId)")
                } catch (e: Exception) {
                    // 如果重建表失败，尝试单独添加列
                    try {
                        database.execSQL("ALTER TABLE tracks ADD COLUMN isStarted INTEGER NOT NULL DEFAULT 1")
                        database.execSQL("ALTER TABLE tracks ADD COLUMN isEnded INTEGER NOT NULL DEFAULT 0")
                        database.execSQL("ALTER TABLE tracks ADD COLUMN photoCount INTEGER NOT NULL DEFAULT 0")
                        database.execSQL("ALTER TABLE tracks ADD COLUMN startPointPhotoCount INTEGER NOT NULL DEFAULT 0")
                        database.execSQL("ALTER TABLE tracks ADD COLUMN middlePointPhotoCount INTEGER NOT NULL DEFAULT 0")
                        database.execSQL("ALTER TABLE tracks ADD COLUMN modelPointPhotoCount INTEGER NOT NULL DEFAULT 0")
                        database.execSQL("ALTER TABLE tracks ADD COLUMN endPointPhotoCount INTEGER NOT NULL DEFAULT 0")
                    } catch (e: Exception) {
                        // 忽略列已存在的错误
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
                    .addMigrations(MIGRATION_1_2, MIGRATION_2_3, MIGRATION_3_4, MIGRATION_4_6, MIGRATION_6_4, MIGRATION_6_7)  // 添加迁移策略
                    .build()
                    INSTANCE = instance
                    instance
                } catch (e: Exception) {
                    // 迁移失败，回退到重建数据库
                    val instance = Room.databaseBuilder(
                        context.applicationContext,
                        AppDatabase::class.java,
                        DATABASE_NAME
                    )
                    .fallbackToDestructiveMigration() // 如果迁移失败，允许重建数据库（会丢失数据）
                    .build()
                    INSTANCE = instance
                    instance
                }
            }
        }
    }
} 