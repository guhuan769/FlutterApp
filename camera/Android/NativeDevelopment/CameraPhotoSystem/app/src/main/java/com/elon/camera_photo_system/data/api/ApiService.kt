package com.elon.camera_photo_system.data.api

import okhttp3.MultipartBody
import okhttp3.ResponseBody
import retrofit2.Response
import retrofit2.http.*

interface ApiService {
    @GET("/Photo/test")
    suspend fun testConnection(): Response<TestResponse>
    
    @Multipart
    @POST("/Photo/upload")
    suspend fun uploadPhoto(
        @Part photo: MultipartBody.Part,
        @Query("moduleId") moduleId: String,
        @Query("moduleType") moduleType: String,
        @Query("photoType") photoType: String,
        @Query("projectName") projectName: String?,
        @Query("latitude") latitude: Double?,
        @Query("longitude") longitude: Double?
    ): Response<ResponseBody>
    
    @DELETE("/Photo/delete")
    suspend fun deleteProjectPhotos(
        @Query("moduleId") moduleId: String,
        @Query("moduleType") moduleType: String
    ): Response<ResponseBody>
    
    @GET("/api/Photo/GetPhotos")
    suspend fun getPhotos(): Response<List<PhotoDto>>
    
    @GET("/api/Photo/GetPhoto/{id}")
    suspend fun getPhoto(@Path("id") id: Int): Response<PhotoDto>
    
    @DELETE("/api/Photo/DeletePhoto/{id}")
    suspend fun deletePhoto(@Path("id") id: Int): Response<Unit>
}

data class TestResponse(
    val status: String,
    val message: String,
    val timestamp: String
)

data class PhotoDto(
    val id: Int,
    val fileName: String,
    val contentType: String,
    val size: Long,
    val uploadTime: String,
    val url: String
) 