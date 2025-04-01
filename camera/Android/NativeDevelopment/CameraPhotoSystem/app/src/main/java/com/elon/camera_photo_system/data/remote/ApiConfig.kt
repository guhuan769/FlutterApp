package com.elon.camera_photo_system.data.remote

import android.util.Log
import javax.inject.Inject
import javax.inject.Singleton

/**
 * API配置
 */
@Singleton
class ApiConfig @Inject constructor() {
    /**
     * 基础URL，默认为模拟器测试地址
     * 可以通过设置来更改
     */
    var baseUrl: String = "http://192.168.101.21:5000/"
        private set

    /**
     * 设置基础URL
     */
    fun updateBaseUrl(newUrl: String) {
        var formattedUrl = newUrl.trim()
        
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
        
        baseUrl = formattedUrl
        Log.d("ApiConfig", "API URL已更新为: $baseUrl")
    }
} 