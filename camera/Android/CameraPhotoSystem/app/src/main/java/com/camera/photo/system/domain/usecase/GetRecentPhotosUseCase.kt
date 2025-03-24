package com.camera.photo.system.domain.usecase

import com.camera.photo.system.domain.model.Photo
import com.camera.photo.system.domain.repository.CameraRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.take
import javax.inject.Inject

/**
 * 获取最近拍摄的照片用例
 */
class GetRecentPhotosUseCase @Inject constructor(
    private val cameraRepository: CameraRepository
) {
    /**
     * 执行用例，获取最近的照片
     * 
     * @param limit 最大照片数量
     * @return 照片列表Flow
     */
    fun execute(limit: Int = 10): Flow<List<Photo>> {
        return cameraRepository.getAllPhotos()
            .take(1) // 只获取一次数据
            .flowOn(Dispatchers.IO) // 在IO线程执行
    }
} 