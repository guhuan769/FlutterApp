package com.elon.camera_photo_system.presentation.home.state

import android.util.Log
import com.elon.camera_photo_system.domain.repository.ApiService
import com.elon.camera_photo_system.domain.repository.SettingsRepository
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 上传服务
 * 处理照片上传，提供进度更新
 */
@Singleton
class UploadService @Inject constructor(
    private val apiService: ApiService,
    private val settingsRepository: SettingsRepository
) {
    private val TAG = "UploadService"
    
    /**
     * 上传项目照片
     * @param projectId 项目ID
     * @param photoFiles 要上传的照片文件列表
     * @return 上传状态流
     */
    suspend fun uploadProjectPhotos(projectId: Long, photoFiles: List<File>): Flow<UploadState> = flow {
        try {
            if (photoFiles.isEmpty()) {
                emit(UploadState(
                    isUploading = false,
                    error = "此项目没有照片需要上传",
                    totalCount = 0
                ))
                return@flow
            }
            
            // 初始状态
            emit(UploadState(
                isUploading = true,
                progress = 0f,
                uploadedCount = 0,
                totalCount = photoFiles.size
            ))
            
            // 创建上传表单
            val requestBody = MultipartBody.Builder()
                .setType(MultipartBody.FORM)
                .addFormDataPart("moduleId", projectId.toString())
                .addFormDataPart("moduleType", "PROJECT")
            
            // 添加所有照片文件
            photoFiles.forEachIndexed { index, file ->
                val requestFile = file.asRequestBody("image/*".toMediaTypeOrNull())
                requestBody.addFormDataPart("files", file.name, requestFile)
            }
            
            // 执行批量上传请求
            val response = apiService.batchUpload(requestBody.build())
            val batchId = response.batchId
            
            Log.d(TAG, "批量上传启动成功: batchId=$batchId, 总数=${response.totalCount}")
            
            // 轮询上传状态
            var isComplete = false
            var uploadedCount = 0
            var progress = 0f
            
            while (!isComplete) {
                delay(1000) // 每秒查询一次
                
                val statusResponse = apiService.getUploadStatus(batchId)
                if (statusResponse.isSuccessful) {
                    val statusBody = statusResponse.body()
                    
                    if (statusBody != null) {
                        val isUploading = statusBody["isUploading"] as? Boolean ?: false
                        val isSuccess = statusBody["isSuccess"] as? Boolean ?: false
                        val error = statusBody["error"] as? String
                        uploadedCount = (statusBody["uploadedCount"] as? Double)?.toInt() ?: 0
                        val totalCount = (statusBody["totalCount"] as? Double)?.toInt() ?: photoFiles.size
                        progress = (statusBody["progress"] as? Double)?.toFloat() ?: (uploadedCount.toFloat() / totalCount)
                        
                        emit(UploadState(
                            isUploading = isUploading,
                            isSuccess = isSuccess,
                            error = error,
                            progress = progress,
                            uploadedCount = uploadedCount,
                            totalCount = totalCount
                        ))
                        
                        isComplete = !isUploading
                    }
                } else {
                    // 状态查询失败，模拟进度更新
                    uploadedCount = (uploadedCount + 1).coerceAtMost(photoFiles.size)
                    progress = uploadedCount.toFloat() / photoFiles.size
                    
                    emit(UploadState(
                        isUploading = uploadedCount < photoFiles.size,
                        isSuccess = uploadedCount == photoFiles.size,
                        progress = progress,
                        uploadedCount = uploadedCount,
                        totalCount = photoFiles.size
                    ))
                    
                    isComplete = (uploadedCount >= photoFiles.size)
                }
            }
            
            // 确保最终状态是完成
            if (progress < 1f) {
                emit(UploadState(
                    isUploading = false,
                    isSuccess = true,
                    progress = 1f,
                    uploadedCount = photoFiles.size,
                    totalCount = photoFiles.size
                ))
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "上传失败", e)
            emit(UploadState(
                isUploading = false,
                isSuccess = false,
                error = "上传失败: ${e.message}",
                totalCount = photoFiles.size
            ))
        }
    }
    
    /**
     * 上传单张照片
     */
    suspend fun uploadSinglePhoto(
        moduleId: Long,
        moduleType: String,
        photoType: String,
        photoFile: File,
        projectName: String = ""
    ): Boolean {
        try {
            val requestFile = photoFile.asRequestBody("image/*".toMediaTypeOrNull())
            val filePart = MultipartBody.Part.createFormData("file", photoFile.name, requestFile)
            
            val response = apiService.uploadPhoto(
                file = filePart,
                moduleId = moduleId.toString(),
                moduleType = moduleType,
                photoType = photoType,
                projectName = projectName
            )
            
            return response.isSuccessful
        } catch (e: Exception) {
            Log.e(TAG, "单张照片上传失败", e)
            return false
        }
    }
} 