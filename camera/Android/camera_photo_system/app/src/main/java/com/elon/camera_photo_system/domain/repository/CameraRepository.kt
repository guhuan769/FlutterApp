package com.elon.camera_photo_system.domain.repository

import android.content.Context
import androidx.camera.core.ImageCapture
import androidx.camera.core.Preview
import androidx.camera.view.PreviewView
import com.elon.camera_photo_system.domain.model.CameraState
import com.elon.camera_photo_system.domain.model.FlashMode
import com.elon.camera_photo_system.domain.model.LensFacing
import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.model.PhotoType
import kotlinx.coroutines.flow.Flow

/**
 * 相机仓库接口，定义相机相关操作
 */
interface CameraRepository {
    /**
     * 初始化相机
     * @param context 上下文
     * @param previewView 预览视图
     * @return 是否初始化成功
     */
    suspend fun initCamera(context: Context, previewView: PreviewView): Boolean
    
    /**
     * 获取相机状态流
     * @return 相机状态流
     */
    fun getCameraState(): Flow<CameraState>
    
    /**
     * 切换闪光灯模式
     * @param flashMode 闪光灯模式
     */
    suspend fun setFlashMode(flashMode: FlashMode)
    
    /**
     * 切换相机镜头方向
     * @param lensFacing 镜头方向
     */
    suspend fun switchCamera(lensFacing: LensFacing)
    
    /**
     * 拍照
     * @param type 照片类型
     * @param projectId 项目ID（可选）
     * @param vehicleId 车辆ID（可选）
     * @param routeId 轨迹ID（可选）
     * @return 拍摄的照片
     */
    suspend fun takePhoto(
        type: PhotoType,
        projectId: Long? = null,
        vehicleId: Long? = null,
        routeId: Long? = null
    ): Photo?
    
    /**
     * 调整缩放比例
     * @param zoomRatio 缩放比例
     */
    suspend fun setZoomRatio(zoomRatio: Float)
    
    /**
     * 释放相机资源
     */
    suspend fun releaseCamera()
} 