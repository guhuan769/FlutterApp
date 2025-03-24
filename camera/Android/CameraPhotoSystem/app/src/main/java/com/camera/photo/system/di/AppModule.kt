package com.camera.photo.system.di

import android.content.Context
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import com.camera.photo.system.domain.repository.CameraRepository
import com.camera.photo.system.data.repository.CameraRepositoryImpl
import com.camera.photo.system.domain.repository.ProjectRepository
import com.camera.photo.system.domain.repository.VehicleRepository
import com.camera.photo.system.domain.repository.TrackRepository
import com.camera.photo.system.domain.repository.PhotoRepository
import com.camera.photo.system.data.repository.ProjectRepositoryImpl
import com.camera.photo.system.data.repository.VehicleRepositoryImpl
import com.camera.photo.system.data.repository.TrackRepositoryImpl
import com.camera.photo.system.data.repository.PhotoRepositoryImpl
import com.camera.photo.system.domain.usecase.GetRecentPhotosUseCase
import com.camera.photo.system.domain.usecase.InitCameraUseCase
import com.camera.photo.system.domain.usecase.TakePhotoUseCase
import com.camera.photo.system.domain.usecase.project.CreateProjectUseCase
import com.camera.photo.system.domain.usecase.project.GetProjectsUseCase
import com.camera.photo.system.domain.usecase.photo.GetProjectPhotosUseCase
import com.camera.photo.system.domain.usecase.photo.TakeProjectPhotoUseCase
import java.util.concurrent.Executor
import java.util.concurrent.Executors
import javax.inject.Singleton

/**
 * 应用依赖注入模块
 */
@Module
@InstallIn(SingletonComponent::class)
object AppModule {
    
    /**
     * 提供Executor依赖
     */
    @Provides
    @Singleton
    fun provideExecutor(): Executor {
        return Executors.newSingleThreadExecutor()
    }
    
    // ========= 仓库提供 =========
    
    /**
     * 提供CameraRepository依赖
     */
    @Provides
    @Singleton
    fun provideCameraRepository(
        executor: Executor,
        @ApplicationContext context: Context
    ): CameraRepository {
        return CameraRepositoryImpl(executor, context)
    }
    
    /**
     * 提供ProjectRepository依赖
     */
    @Provides
    @Singleton
    fun provideProjectRepository(
        @ApplicationContext context: Context
    ): ProjectRepository {
        return ProjectRepositoryImpl(context)
    }
    
    /**
     * 提供VehicleRepository依赖
     */
    @Provides
    @Singleton
    fun provideVehicleRepository(
        @ApplicationContext context: Context,
        projectRepository: ProjectRepository
    ): VehicleRepository {
        return VehicleRepositoryImpl(context, projectRepository as ProjectRepositoryImpl)
    }
    
    /**
     * 提供TrackRepository依赖
     */
    @Provides
    @Singleton
    fun provideTrackRepository(
        @ApplicationContext context: Context,
        vehicleRepository: VehicleRepository
    ): TrackRepository {
        return TrackRepositoryImpl(context, vehicleRepository as VehicleRepositoryImpl)
    }
    
    /**
     * 提供PhotoRepository依赖
     */
    @Provides
    @Singleton
    fun providePhotoRepository(
        @ApplicationContext context: Context
    ): PhotoRepository {
        return PhotoRepositoryImpl(context)
    }
    
    // ========= 用例提供 =========
    
    /**
     * 提供初始化相机用例
     */
    @Provides
    fun provideInitCameraUseCase(cameraRepository: CameraRepository): InitCameraUseCase {
        return InitCameraUseCase(cameraRepository)
    }
    
    /**
     * 提供拍照用例
     */
    @Provides
    fun provideTakePhotoUseCase(cameraRepository: CameraRepository): TakePhotoUseCase {
        return TakePhotoUseCase(cameraRepository)
    }
    
    /**
     * 提供获取最近照片用例
     */
    @Provides
    fun provideGetRecentPhotosUseCase(cameraRepository: CameraRepository): GetRecentPhotosUseCase {
        return GetRecentPhotosUseCase(cameraRepository)
    }
    
    // 项目相关用例
    
    /**
     * 提供创建项目用例
     */
    @Provides
    fun provideCreateProjectUseCase(projectRepository: ProjectRepository): CreateProjectUseCase {
        return CreateProjectUseCase(projectRepository)
    }
    
    /**
     * 提供获取项目列表用例
     */
    @Provides
    fun provideGetProjectsUseCase(projectRepository: ProjectRepository): GetProjectsUseCase {
        return GetProjectsUseCase(projectRepository)
    }
    
    /**
     * 提供项目拍照用例
     */
    @Provides
    fun provideTakeProjectPhotoUseCase(
        cameraRepository: CameraRepository,
        photoRepository: PhotoRepository,
        projectRepository: ProjectRepository
    ): TakeProjectPhotoUseCase {
        return TakeProjectPhotoUseCase(cameraRepository, photoRepository, projectRepository)
    }
    
    /**
     * 提供获取项目照片用例
     */
    @Provides
    fun provideGetProjectPhotosUseCase(photoRepository: PhotoRepository): GetProjectPhotosUseCase {
        return GetProjectPhotosUseCase(photoRepository)
    }
} 