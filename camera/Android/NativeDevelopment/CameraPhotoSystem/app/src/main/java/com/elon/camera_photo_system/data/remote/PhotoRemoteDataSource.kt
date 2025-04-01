package com.elon.camera_photo_system.data.remote

import android.util.Log
import com.elon.camera_photo_system.data.api.ApiService
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.PhotoType
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import retrofit2.HttpException
import java.io.File
import java.io.IOException
import java.net.ConnectException
import java.net.SocketTimeoutException
import java.net.UnknownHostException
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 照片远程数据源
 */
@Singleton
class PhotoRemoteDataSource @Inject constructor(
    private val apiService: ApiService
) {
    /**
     * 上传照片
     * 
     * @param filePath 照片文件路径
     * @param fileName 照片文件名
     * @param moduleId 模块ID
     * @param moduleType 模块类型
     * @param photoType 照片类型
     * @param projectName 项目名称
     * @param latitude 纬度
     * @param longitude 经度
     * @return 是否上传成功
     * @throws IOException 当网络连接失败时抛出
     */
    suspend fun uploadPhoto(
        filePath: String,
        fileName: String,
        moduleId: Long,
        moduleType: ModuleType,
        photoType: PhotoType,
        projectName: String = "",
        latitude: Double? = null,
        longitude: Double? = null
    ): Boolean {
        try {
            Log.d("PhotoRemoteDataSource", "开始上传照片: $fileName, moduleId: $moduleId, moduleType: ${moduleType.name}, photoType: ${photoType.name}, projectName: $projectName")
            
            val file = File(filePath)
            if (!file.exists()) {
                Log.e("PhotoRemoteDataSource", "文件不存在: $filePath")
                return false
            }
            
            val requestFile = file.asRequestBody("image/*".toMediaTypeOrNull())
            val body = MultipartBody.Part.createFormData("photo", fileName, requestFile)
            
            Log.d("PhotoRemoteDataSource", "准备发送请求")
            
            try {
                val response = apiService.uploadPhoto(
                    photo = body,
                    moduleId = moduleId.toString(), // 转换为String类型
                    moduleType = moduleType.name,
                    photoType = photoType.name,
                    projectName = projectName,
                    latitude = latitude,
                    longitude = longitude
                )
                
                Log.d("PhotoRemoteDataSource", "上传结果: ${response.isSuccessful}, 状态码: ${response.code()}")
                if (!response.isSuccessful) {
                    Log.e("PhotoRemoteDataSource", "上传失败, 错误信息: ${response.errorBody()?.string()}")
                }
                
                return response.isSuccessful
            } catch (e: ConnectException) {
                Log.e("PhotoRemoteDataSource", "连接服务器失败", e)
                throw IOException("无法连接到服务器，请检查网络连接", e)
            } catch (e: UnknownHostException) {
                Log.e("PhotoRemoteDataSource", "找不到服务器主机", e)
                throw IOException("找不到服务器，请检查服务器地址", e)
            } catch (e: SocketTimeoutException) {
                Log.e("PhotoRemoteDataSource", "连接超时", e)
                throw IOException("连接服务器超时，请稍后重试", e)
            } catch (e: HttpException) {
                Log.e("PhotoRemoteDataSource", "HTTP错误: ${e.code()}", e)
                throw IOException("服务器返回错误: ${e.code()}", e)
            }
        } catch (e: Exception) {
            Log.e("PhotoRemoteDataSource", "上传异常", e)
            e.printStackTrace()
            
            if (e is IOException) {
                throw e // 重新抛出网络相关异常
            }
            
            return false
        }
    }

    /**
     * 删除服务器上项目的所有照片
     * 
     * @param moduleId 模块ID
     * @param moduleType 模块类型
     * @return 是否删除成功
     */
    suspend fun deleteProjectPhotos(
        moduleId: Long,
        moduleType: ModuleType
    ): Boolean {
        try {
            Log.d("PhotoRemoteDataSource", "开始删除服务器上的照片: moduleId: $moduleId, moduleType: ${moduleType.name}")
            
            try {
                val response = apiService.deleteProjectPhotos(
                    moduleId = moduleId.toString(),
                    moduleType = moduleType.name
                )
                
                Log.d("PhotoRemoteDataSource", "删除结果: ${response.isSuccessful}, 状态码: ${response.code()}")
                if (!response.isSuccessful) {
                    Log.e("PhotoRemoteDataSource", "删除失败, 错误信息: ${response.errorBody()?.string()}")
                }
                
                return response.isSuccessful
            } catch (e: ConnectException) {
                Log.e("PhotoRemoteDataSource", "连接服务器失败", e)
                throw IOException("无法连接到服务器，请检查网络连接", e)
            } catch (e: UnknownHostException) {
                Log.e("PhotoRemoteDataSource", "找不到服务器主机", e)
                throw IOException("找不到服务器，请检查服务器地址", e)
            } catch (e: SocketTimeoutException) {
                Log.e("PhotoRemoteDataSource", "连接超时", e)
                throw IOException("连接服务器超时，请稍后重试", e)
            } catch (e: HttpException) {
                Log.e("PhotoRemoteDataSource", "HTTP错误: ${e.code()}", e)
                throw IOException("服务器返回错误: ${e.code()}", e)
            }
        } catch (e: Exception) {
            Log.e("PhotoRemoteDataSource", "删除异常", e)
            e.printStackTrace()
            
            if (e is IOException) {
                throw e // 重新抛出网络相关异常
            }
            
            return false
        }
    }
} 