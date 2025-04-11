package com.elon.camera_photo_system.domain.repository

import okhttp3.MultipartBody
import okhttp3.ResponseBody
import retrofit2.Response
import retrofit2.http.*

/**
 * API服务接口
 * 定义与服务器交互的各种API
 */
interface ApiService {
    /**
     * 测试API连接
     */
    @GET("photo/test")
    suspend fun testConnection(): Response<Map<String, Any>>
    
    /**
     * 上传单张照片
     */
    @Multipart
    @POST("photo/upload")
    suspend fun uploadPhoto(
        @Part file: MultipartBody.Part,
        @Query("moduleId") moduleId: String,
        @Query("moduleType") moduleType: String,
        @Query("photoType") photoType: String,
        @Query("projectName") projectName: String = ""
    ): Response<Map<String, Any>>
    
    /**
     * 批量上传照片
     */
    @POST("photo/batch-upload")
    suspend fun batchUpload(
        @Body requestBody: MultipartBody
    ): UploadBatchResponse
    
    /**
     * 获取上传状态
     */
    @GET("photo/upload-status/{batchId}")
    suspend fun getUploadStatus(
        @Path("batchId") batchId: String
    ): Response<Map<String, Any>>
    
    /**
     * 删除项目照片
     */
    @DELETE("photo/delete")
    suspend fun deleteProjectPhotos(
        @Query("moduleId") moduleId: String,
        @Query("moduleType") moduleType: String
    ): Response<Map<String, Any>>
}

/**
 * 批量上传响应
 */
data class UploadBatchResponse(
    val batchId: String,
    val totalCount: Int,
    val status: String
) 