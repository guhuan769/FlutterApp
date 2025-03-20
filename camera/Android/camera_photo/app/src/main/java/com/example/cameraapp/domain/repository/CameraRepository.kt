package com.example.cameraapp.domain.repository

import android.content.Context
import android.net.Uri
import androidx.camera.core.CameraSelector
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.lifecycle.LifecycleOwner
import kotlinx.coroutines.flow.Flow

interface CameraRepository {
    
    /**
     * 初始化相机并绑定生命周期
     */3
    fun initCamera(
        lifecycleOwner: LifecycleOwner,
        previewView: PreviewView,
        lensFacing: Int = CameraSelector.LENS_FACING_BACK
    ): Flow<ProcessCameraProvider?>
    
    /**
     * 拍照并保存到文件
     */
    suspend fun takePhoto(context: Context): Flow<Uri?>
    
    /**
     * 切换前后摄像头
     */
    fun toggleCamera(preview: Preview)
    
    /**
     * 获取当前使用的摄像头方向
     */
    fun getCurrentLensFacing(): Int
} 