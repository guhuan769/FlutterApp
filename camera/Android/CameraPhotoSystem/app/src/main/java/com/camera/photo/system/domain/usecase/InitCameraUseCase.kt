package com.camera.photo.system.domain.usecase

import android.content.Context
import androidx.camera.core.CameraSelector
import com.camera.photo.system.domain.repository.CameraRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import javax.inject.Inject

/**
 * 初始化相机用例
 */
class InitCameraUseCase @Inject constructor(
    private val cameraRepository: CameraRepository
) {
    /**
     * 执行相机初始化
     * 
     * @param context 上下文
     * @param cameraSelector 相机选择器，默认为后置相机
     * @return 初始化结果
     */
    suspend fun execute(
        context: Context,
        cameraSelector: CameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
    ): Result<Unit> = withContext(Dispatchers.Main) {
        try {
            // 调用仓库方法初始化相机
            cameraRepository.initCamera(context, cameraSelector)
            
            // 返回成功结果
            Result.success(Unit)
        } catch (e: Exception) {
            // 返回失败结果
            Result.failure(e)
        }
    }
} 