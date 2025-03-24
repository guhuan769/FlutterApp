package com.camera.photo.system

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

/**
 * 应用程序类
 * 启用Hilt依赖注入
 */
@HiltAndroidApp
class CameraPhotoApplication : Application() 