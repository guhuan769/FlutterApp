package com.example.cameraapp.di

import android.content.Context
import com.example.cameraapp.data.CameraRepositoryImpl
import com.example.cameraapp.domain.repository.CameraRepository
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
    fun provideCameraRepository(@ApplicationContext context: Context): CameraRepository {
        return CameraRepositoryImpl(context)
    }
} 