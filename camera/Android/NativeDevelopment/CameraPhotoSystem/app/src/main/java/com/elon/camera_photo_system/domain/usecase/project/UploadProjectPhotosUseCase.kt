package com.elon.camera_photo_system.domain.usecase.project

import android.util.Log
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.repository.PhotoRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import java.io.IOException
import javax.inject.Inject

/**
 * 上传项目照片用例
 */
class UploadProjectPhotosUseCase @Inject constructor(
    private val photoRepository: PhotoRepository
) {
    /**
     * 上传项目的所有照片
     *
     * @param projectId 项目ID
     * @param forceReupload 是否强制重新上传所有照片（忽略isUploaded标记）
     * @param progressListener 上传进度监听器
     * @return 上传结果，包含是否成功和其他信息
     */
    suspend operator fun invoke(
        projectId: Long, 
        forceReupload: Boolean = true,
        progressListener: UploadProgressListener? = null
    ): Result<UploadResult> {
        return try {
            Log.d("UploadProjectPhotos", "开始上传项目 $projectId 的照片, 强制重新上传: $forceReupload")
            
            // 获取项目的所有照片
            val photos: List<Photo> = photoRepository.getPhotosByModule(
                moduleId = projectId,
                moduleType = ModuleType.PROJECT
            ).first()
            
            if (photos.isEmpty()) {
                Log.d("UploadProjectPhotos", "项目没有照片需要上传")
                // 发送零进度事件，表示没有任务
                progressListener?.onProgress(0, 0)
                return Result.success(UploadResult(
                    success = true,
                    hasActualUploads = false,
                    status = UploadStatus.NO_PHOTOS
                ))
            }
            
            // 根据强制重新上传参数决定要上传的照片
            val photosToUpload = if (forceReupload) {
                photos // 上传所有照片，忽略已上传标记
            } else {
                photos.filter { !it.isUploaded } // 只上传未上传的照片
            }
            
            if (photosToUpload.isEmpty() && !forceReupload) {
                Log.d("UploadProjectPhotos", "项目照片已全部上传")
                // 发送零进度事件，表示没有任务
                progressListener?.onProgress(0, 0)
                return Result.success(UploadResult(
                    success = true,
                    hasActualUploads = false,
                    status = UploadStatus.ALREADY_UPLOADED
                ))
            }
            
            val totalPhotos = photosToUpload.size
            Log.d("UploadProjectPhotos", "准备上传 $totalPhotos 张照片")
            // 发送初始进度事件
            progressListener?.onProgress(0, totalPhotos)
            
            try {
                // 先删除后端服务器上该项目的所有照片，避免重复
                try {
                    Log.d("UploadProjectPhotos", "尝试删除后端服务器上项目 $projectId 的现有照片")
                    photoRepository.deleteProjectPhotosOnServer(projectId, ModuleType.PROJECT)
                    Log.d("UploadProjectPhotos", "已删除后端服务器上项目 $projectId 的现有照片")
                } catch (e: Exception) {
                    Log.e("UploadProjectPhotos", "删除后端照片失败，继续上传: ${e.message}")
                    // 删除失败也继续上传，不中断流程
                }
                
                // 上传所有照片
                var allSuccess = true
                var uploadedCount = 0
                
                photosToUpload.forEachIndexed { index, photo ->
                    try {
                        Log.d("UploadProjectPhotos", "正在上传照片(${index + 1}/$totalPhotos): ${photo.fileName}")
                        val uploadResult = photoRepository.uploadPhoto(photo)
                        if (!uploadResult) {
                            Log.e("UploadProjectPhotos", "照片 ${photo.fileName} 上传失败")
                            allSuccess = false
                        } else {
                            Log.d("UploadProjectPhotos", "照片 ${photo.fileName} 上传成功")
                            uploadedCount++
                            // 更新进度
                            progressListener?.onProgress(uploadedCount, totalPhotos)
                        }
                    } catch (e: IOException) {
                        // 捕获并重新抛出网络相关异常
                        Log.e("UploadProjectPhotos", "网络异常: ${e.message}", e)
                        throw e
                    } catch (e: Exception) {
                        Log.e("UploadProjectPhotos", "上传照片时发生错误", e)
                        allSuccess = false
                    }
                }
                
                Log.d("UploadProjectPhotos", "照片上传完成，全部成功: $allSuccess，已上传: $uploadedCount/$totalPhotos")
                
                // 最终更新进度
                progressListener?.onProgress(uploadedCount, totalPhotos)
                
                val status = if (allSuccess) UploadStatus.SUCCESS else UploadStatus.PARTIAL_SUCCESS
                Result.success(UploadResult(
                    success = allSuccess,
                    hasActualUploads = true,
                    status = status
                ))
            } catch (e: IOException) {
                // 处理网络异常
                Log.e("UploadProjectPhotos", "网络连接错误: ${e.message}", e)
                return Result.failure(IOException("网络连接失败: ${e.message}", e))
            }
        } catch (e: IOException) {
            // 处理网络异常
            Log.e("UploadProjectPhotos", "网络连接错误: ${e.message}", e)
            Result.failure(IOException("网络连接失败: ${e.message}", e))
        } catch (e: Exception) {
            Log.e("UploadProjectPhotos", "上传照片过程中发生异常", e)
            Result.failure(e)
        }
    }
}

/**
 * 上传结果数据类
 */
data class UploadResult(
    val success: Boolean,           // 是否成功
    val hasActualUploads: Boolean,  // 是否有实际上传操作
    val status: UploadStatus        // 上传状态
)

/**
 * 上传状态枚举
 */
enum class UploadStatus {
    SUCCESS,            // 全部上传成功
    PARTIAL_SUCCESS,    // 部分上传成功
    NO_PHOTOS,          // 没有照片
    ALREADY_UPLOADED    // 照片已全部上传
} 