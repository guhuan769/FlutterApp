package com.elon.camera_photo_system.data.remote.api

import com.elon.camera_photo_system.data.remote.model.TestResponse
import okhttp3.MultipartBody
import okhttp3.RequestBody
import retrofit2.Response
import retrofit2.http.*

interface PhotoApi {
    @GET("photo/test")
    suspend fun testConnection(): Response<TestResponse>
    
    @Multipart
    @POST("photo/upload")
    suspend fun uploadPhoto(
        @Part("moduleId") moduleId: RequestBody,
        @Part("moduleType") moduleType: RequestBody,
        @Part("photoType") photoType: RequestBody,
        @Part photo: MultipartBody.Part
    ): Response<Map<String, Any>>
}

data class TestResponse(
    val status: String,
    val message: String,
    val timestamp: String
) 