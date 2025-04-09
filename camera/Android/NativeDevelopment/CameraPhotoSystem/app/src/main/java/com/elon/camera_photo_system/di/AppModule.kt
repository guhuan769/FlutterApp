package com.elon.camera_photo_system.di

import android.content.Context
import androidx.room.Room
import com.elon.camera_photo_system.data.local.AppDatabase
import com.elon.camera_photo_system.data.local.dao.PhotoDao
import com.elon.camera_photo_system.data.local.dao.ProjectDao
import com.elon.camera_photo_system.data.local.dao.TrackDao
import com.elon.camera_photo_system.data.local.dao.VehicleDao
import com.elon.camera_photo_system.data.remote.ApiConfig
import com.elon.camera_photo_system.data.remote.PhotoRemoteDataSource
import com.elon.camera_photo_system.data.repository.PhotoRepositoryImpl
import com.elon.camera_photo_system.data.repository.ProjectRepositoryImpl
import com.elon.camera_photo_system.data.repository.TrackRepositoryImpl
import com.elon.camera_photo_system.data.repository.VehicleRepositoryImpl
import com.elon.camera_photo_system.domain.repository.PhotoRepository
import com.elon.camera_photo_system.domain.repository.ProjectRepository
import com.elon.camera_photo_system.domain.repository.SettingsRepository
import com.elon.camera_photo_system.domain.repository.TrackRepository
import com.elon.camera_photo_system.domain.repository.VehicleRepository
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {
    
    @Provides
    @Singleton
    fun provideAppDatabase(@ApplicationContext context: Context): AppDatabase {
        return AppDatabase.getInstance(context)
    }
    
    @Provides
    @Singleton
    fun providePhotoDao(database: AppDatabase): PhotoDao {
        return database.photoDao()
    }
    
    @Provides
    @Singleton
    fun provideProjectDao(database: AppDatabase): ProjectDao {
        return database.projectDao()
    }
    
    @Provides
    @Singleton
    fun provideVehicleDao(database: AppDatabase): VehicleDao {
        return database.vehicleDao()
    }
    
    @Provides
    @Singleton
    fun provideTrackDao(database: AppDatabase): TrackDao {
        return database.trackDao()
    }
    
    @Provides
    @Singleton
    fun provideSettingsRepository(@ApplicationContext context: Context): SettingsRepository {
        return SettingsRepository(context)
    }
    
    @Provides
    @Singleton
    fun providePhotoRepository(
        photoDao: PhotoDao,
        photoRemoteDataSource: PhotoRemoteDataSource,
        apiConfig: ApiConfig
    ): PhotoRepository {
        return PhotoRepositoryImpl(photoDao, photoRemoteDataSource, apiConfig)
    }
    
    @Provides
    @Singleton
    fun provideProjectRepository(
        projectDao: ProjectDao,
        photoRepository: PhotoRepository,
        vehicleRepository: VehicleRepository
    ): ProjectRepository {
        return ProjectRepositoryImpl(projectDao, photoRepository, vehicleRepository)
    }
    
    @Provides
    @Singleton
    fun provideVehicleRepository(vehicleDao: VehicleDao): VehicleRepository {
        return VehicleRepositoryImpl(vehicleDao)
    }
    
    @Provides
    @Singleton
    fun provideTrackRepository(trackDao: TrackDao): TrackRepository {
        return TrackRepositoryImpl(trackDao)
    }
} 