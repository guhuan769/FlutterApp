package com.elon.camera_photo_system.di

import android.content.Context
import com.elon.camera_photo_system.data.repository.CameraRepositoryImpl
import com.elon.camera_photo_system.data.repository.PhotoRepositoryImpl
import com.elon.camera_photo_system.domain.repository.CameraRepository
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
    fun providePhotoRepository(
        @ApplicationContext context: Context
    ): PhotoRepository {
        return PhotoRepositoryImpl(context)
    }
    
    @Provides
    @Singleton
    fun provideCameraRepository(
        @ApplicationContext context: Context,
        photoRepository: PhotoRepository
    ): CameraRepository {
        return CameraRepositoryImpl(context, photoRepository)
    }
} 