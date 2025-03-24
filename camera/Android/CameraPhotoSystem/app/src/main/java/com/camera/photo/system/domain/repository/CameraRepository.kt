package com.camera.photo.system.domain.repository

import android.content.Context
import androidx.camera.core.CameraSelector
import com.camera.photo.system.domain.model.Photo
import kotlinx.coroutines.flow.Flow
import java.io.File

/**
 * 相机仓库接口
 * 定义相机相关的所有操作
 */
interface CameraRepository {
    
    /**
     * 初始化相机
     * 
     * @param context 上下文
     * @param cameraSelector 相机选择器，默认为后置相机
     */
    suspend fun initCamera(
        context: Context, 
        cameraSelector: CameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
    )
    
    /**
     * 拍照并保存图片
     * 
     * @param fileName 自定义文件名，如果为null则自动生成
     * @return 保存的照片对象
     */
    suspend fun takePhoto(fileName: String? = null): Photo
    
    /**
     * 获取所有已保存的照片
     * 
     * @return 照片列表Flow
     */
    fun getAllPhotos(): Flow<List<Photo>>
    
    /**
     * 根据类型获取照片
     * 
     * @param type 照片类型
     * @return 特定类型的照片列表Flow
     */
    fun getPhotosByType(type: String): Flow<List<Photo>>
    
    /**
     * 删除照片
     * 
     * @param photo 要删除的照片
     * @return 操作是否成功
     */
    suspend fun deletePhoto(photo: Photo): Boolean
    
    /**
     * 获取相机支持的最大分辨率
     * 
     * @return 相机最大分辨率
     */
    suspend fun getMaxResolution(): Pair<Int, Int>
    
    /**
     * 设置相机闪光灯模式
     * 
     * @param flashMode 闪光灯模式
     */
    suspend fun setFlashMode(flashMode: Int)
    
    /**
     * 获取相机预览帧数据
     * 
     * @return 相机预览帧数据流
     */
    fun getPreviewFrameData(): Flow<ByteArray>
} 