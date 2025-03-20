package com.elon.camera_photo_system.domain.usecase

import com.elon.camera_photo_system.domain.model.CameraState
import com.elon.camera_photo_system.domain.repository.CameraRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

/**
 * 获取相机状态用例
 * @property cameraRepository 相机仓库
 */
class GetCameraStateUseCase @Inject constructor(
    private val cameraRepository: CameraRepository
) {
    /**
     * 获取相机状态流
     * @return 相机状态流
     */
    operator fun invoke(): Flow<CameraState> {
        return cameraRepository.getCameraState()
    }
} 