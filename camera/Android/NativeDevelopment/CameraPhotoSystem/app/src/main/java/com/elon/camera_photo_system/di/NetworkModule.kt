package com.elon.camera_photo_system.di

import android.util.Log
import com.elon.camera_photo_system.data.api.ApiService
import com.elon.camera_photo_system.data.remote.ApiConfig
import com.elon.camera_photo_system.data.remote.api.PhotoApi
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit
import javax.inject.Singleton
import java.net.URL

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    
    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient, apiConfig: ApiConfig): Retrofit {
        try {
            val baseUrl = apiConfig.baseUrl
            Log.d("NetworkModule", "创建Retrofit实例，使用baseUrl: $baseUrl")
            
            // 验证URL格式
            if (!isValidUrl(baseUrl)) {
                throw IllegalArgumentException("无效的API URL: $baseUrl")
            }
            
            return Retrofit.Builder()
                .baseUrl(baseUrl)
                .client(okHttpClient)
                .addConverterFactory(GsonConverterFactory.create())
                .build()
        } catch (e: Exception) {
            Log.e("NetworkModule", "创建Retrofit实例失败", e)
            throw e
        }
    }
    
    /**
     * 注意：这种方式创建的Retrofit实例使用的是创建时的baseUrl，
     * 如果ApiConfig.baseUrl后续改变，不会自动更新。
     * 推荐使用DynamicBaseUrlInterceptor来处理URL变更。
     */
    @Provides
    @Singleton
    fun provideOkHttpClient(apiConfig: ApiConfig): OkHttpClient {
        val loggingInterceptor = HttpLoggingInterceptor { message ->
            Log.d("OkHttp", message)
        }.apply {
            level = HttpLoggingInterceptor.Level.BODY
        }
        
        return OkHttpClient.Builder()
            .addInterceptor(loggingInterceptor)
            // 添加动态基础URL拦截器
            .addInterceptor { chain ->
                val originalRequest = chain.request()
                
                // 获取当前最新的baseUrl
                val currentBaseUrl = apiConfig.baseUrl
                
                // 构建新的URL
                val newUrl = originalRequest.url.newBuilder()
                    .scheme(URL(currentBaseUrl).protocol)
                    .host(URL(currentBaseUrl).host)
                    .port(if (URL(currentBaseUrl).port == -1) URL(currentBaseUrl).defaultPort else URL(currentBaseUrl).port)
                    .build()
                
                // 创建新的请求，使用新的URL
                val newRequest = originalRequest.newBuilder()
                    .url(newUrl)
                    .build()
                
                Log.d("NetworkModule", "动态更新请求URL: ${originalRequest.url} -> ${newRequest.url}")
                
                chain.proceed(newRequest)
            }
            .addInterceptor { chain ->
                val request = chain.request()
                val url = request.url.toString()
                val method = request.method
                Log.d("NetworkModule", "发送请求: $method $url")
                
                try {
                    val response = chain.proceed(request)
                    Log.d("NetworkModule", "收到响应: ${response.code} ${response.message}, 请求URL: $url")
                    response
                } catch (e: Exception) {
                    Log.e("NetworkModule", "网络错误: ${e.message}, 请求URL: $url", e)
                    throw e
                }
            }
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build()
    }
    
    /**
     * 验证URL是否有效
     */
    private fun isValidUrl(url: String): Boolean {
        return try {
            val urlObj = java.net.URL(url)
            !urlObj.host.isNullOrBlank() && urlObj.host.contains(".") && (url.startsWith("http://") || url.startsWith("https://"))
        } catch (e: Exception) {
            Log.e("NetworkModule", "URL验证失败: $url", e)
            false
        }
    }
    
    @Provides
    @Singleton
    fun provideApiService(retrofit: Retrofit): ApiService {
        return retrofit.create(ApiService::class.java)
    }
    
    @Provides
    @Singleton
    fun providePhotoApi(retrofit: Retrofit): PhotoApi {
        return retrofit.create(PhotoApi::class.java)
    }
} 