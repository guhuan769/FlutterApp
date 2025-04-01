package com.elon.camera_photo_system.data.remote

import android.util.Log
import java.net.URL
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * API配置
 */
@Singleton
class ApiConfig @Inject constructor() {
    private val _baseUrlFlow = MutableStateFlow("http://192.168.101.21:5000/")
    val baseUrlFlow: StateFlow<String> = _baseUrlFlow.asStateFlow()
    
    /**
     * 基础URL，默认为模拟器测试地址
     * 可以通过设置来更改
     */
    var baseUrl: String
        get() = _baseUrlFlow.value
        private set(value) {
            _baseUrlFlow.value = value
        }

    /**
     * 设置基础URL
     * @return 格式化后的URL
     */
    fun updateBaseUrl(newUrl: String): String {
        var formattedUrl = newUrl.trim()
        
        try {
            // 确保URL格式正确
            if (!formattedUrl.startsWith("http://") && !formattedUrl.startsWith("https://")) {
                formattedUrl = "http://$formattedUrl"
                Log.d("ApiConfig", "URL没有协议前缀，添加http://: $formattedUrl")
            }
            
            // 确保URL以/结尾
            if (!formattedUrl.endsWith("/")) {
                formattedUrl = "$formattedUrl/"
                Log.d("ApiConfig", "URL没有以/结尾，添加/: $formattedUrl")
            }
            
            // 验证URL格式
            val url = URL(formattedUrl)
            
            // 确保主机名有效
            if (url.host.isBlank() || !url.host.contains(".")) {
                Log.e("ApiConfig", "URL主机名无效: ${url.host}")
                throw IllegalArgumentException("URL主机名无效: ${url.host}")
            }
            
            // 检查端口是否有效
            if (url.port > 0 && (url.port < 1 || url.port > 65535)) {
                Log.e("ApiConfig", "端口号无效: ${url.port}")
                throw IllegalArgumentException("端口号无效: ${url.port}")
            }
            
            baseUrl = formattedUrl
            Log.d("ApiConfig", "API URL已更新为: $baseUrl")
            return formattedUrl
        } catch (e: Exception) {
            Log.e("ApiConfig", "URL格式错误: $formattedUrl", e)
            // 不要更新baseUrl，保持原有值
            throw IllegalArgumentException("URL格式错误: $formattedUrl", e)
        }
    }
    
    /**
     * 根据配置获取API端点URL
     * @param endpoint API端点路径（相对于baseUrl的路径）
     * @return 完整的API URL
     */
    fun getEndpointUrl(endpoint: String): String {
        // 确保endpoint不以/开头，因为baseUrl已经以/结尾
        val formattedEndpoint = if (endpoint.startsWith("/")) {
            endpoint.substring(1)
        } else {
            endpoint
        }
        
        return baseUrl + formattedEndpoint
    }
    
    /**
     * 用于测试：获取图片上传URL
     */
    fun getPhotoUploadUrl(): String {
        return getEndpointUrl("Photo/upload")
    }
    
    /**
     * 用于测试：获取连接测试URL
     */
    fun getConnectionTestUrl(): String {
        return getEndpointUrl("Photo/test")
    }
} 