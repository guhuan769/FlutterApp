package com.elon.camera_photo_system.di

import android.content.Context
import androidx.room.Room
import com.elon.camera_photo_system.data.local.AppDatabase
import com.elon.camera_photo_system.data.local.dao.PhotoDao
import com.elon.camera_photo_system.data.repository.PhotoRepositoryImpl
import com.elon.camera_photo_system.domain.repository.PhotoRepository
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
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            AppDatabase.DATABASE_NAME
        ).build()
    }
    
    @Provides
    @Singleton
    fun providePhotoDao(database: AppDatabase): PhotoDao {
        return database.photoDao()
    }
    
    @Provides
    @Singleton
    fun providePhotoRepository(photoDao: PhotoDao): PhotoRepository {
        return PhotoRepositoryImpl(photoDao)
    }
} 