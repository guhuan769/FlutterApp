package com.elon.camera_photo_system.data.util

import android.util.Log
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.repository.PhotoRepository
import com.elon.camera_photo_system.domain.repository.ProjectRepository
import com.elon.camera_photo_system.presentation.home.state.UploadState
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 照片上传服务
 * 处理项目、车辆和轨迹照片的上传操作
 */
@Singleton
class UploadService @Inject constructor(
    private val photoRepository: PhotoRepository,
    private val projectRepository: ProjectRepository
) {
    /**
     * 上传项目照片
     * @param projectId 项目ID
     * @param projectPhotos 项目照片列表
     * @param uploadInfo 上传类型信息 Pair<类型名称, 类型ID>
     * @return 上传状态Flow
     */
    fun uploadProjectPhotos(
        projectId: Long, 
        projectPhotos: List<Photo>,
        uploadInfo: Pair<String, String>
    ): Flow<UploadState> = flow {
        // 初始化上传状态
        val projectName = projectRepository.getProjectById(projectId)?.name ?: "Unknown Project"
        var currentState = UploadState(
            isUploading = true,
            currentProject = projectRepository.getProjectById(projectId),
            progress = 0f,
            totalCount = projectPhotos.size,
            uploadedCount = 0,
            currentModuleType = ModuleType.PROJECT.name,
            currentModuleName = projectName,
            projectPhotosCount = projectPhotos.size,
            selectedUploadPhotoType = uploadInfo.first,
            selectedUploadTypeId = uploadInfo.second,
            selectedUploadTypeName = getTypeNameFromId(uploadInfo)
        )
        emit(currentState)
        
        try {
            // 遍历照片进行上传
            projectPhotos.forEachIndexed { index, photo ->
                try {
                    // 更新照片的上传类型信息
                    val updatedPhoto = photo.copy(
                        uploadPhotoType = uploadInfo.first,
                        uploadTypeId = uploadInfo.second
                    )
                    
                    // 上传照片
                    val success = photoRepository.uploadPhoto(updatedPhoto)
                    
                    // 更新上传状态
                    val uploadedCount = index + 1
                    val progress = if (projectPhotos.isNotEmpty()) uploadedCount.toFloat() / projectPhotos.size else 1f
                    
                    // 更新并发送状态
                    currentState = currentState.copy(
                        progress = progress,
                        uploadedCount = uploadedCount,
                        projectUploadedCount = uploadedCount
                    )
                    emit(currentState)
                    
                } catch (e: Exception) {
                    Log.e("UploadService", "上传照片失败: ${photo.fileName}", e)
                    throw e
                }
            }
            
            // 上传完成
            currentState = currentState.copy(
                isUploading = false,
                isSuccess = true,
                progress = 1f
            )
            emit(currentState)
            
        } catch (e: Exception) {
            // 上传失败
            currentState = currentState.copy(
                isUploading = false,
                isSuccess = false,
                error = "上传失败: ${e.message}"
            )
            emit(currentState)
            throw e
        }
    }.flowOn(Dispatchers.IO)
    
    /**
     * 从类型ID获取类型名称
     */
    private fun getTypeNameFromId(uploadInfo: Pair<String, String>): String {
        // 这里应该实际返回类型名称，但是为了简单起见直接返回ID
        // 实际应用中可以查询数据库或其他方式获取
        return uploadInfo.second
    }
} 