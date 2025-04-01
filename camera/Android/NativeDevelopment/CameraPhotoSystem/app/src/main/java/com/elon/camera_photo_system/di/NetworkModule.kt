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

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    
    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient {
        val loggingInterceptor = HttpLoggingInterceptor { message ->
            Log.d("OkHttp", message)
        }.apply {
            level = HttpLoggingInterceptor.Level.BODY
        }
        
        return OkHttpClient.Builder()
            .addInterceptor(loggingInterceptor)
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
    
    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient, apiConfig: ApiConfig): Retrofit {
        val baseUrl = apiConfig.baseUrl
        Log.d("NetworkModule", "创建Retrofit实例，使用baseUrl: $baseUrl")
        return Retrofit.Builder()
            .baseUrl(baseUrl)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
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