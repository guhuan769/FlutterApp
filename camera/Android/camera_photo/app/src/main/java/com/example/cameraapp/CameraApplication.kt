package com.example.cameraapp

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class CameraApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // 应用程序全局初始化代码可以放在这里
    }
} 