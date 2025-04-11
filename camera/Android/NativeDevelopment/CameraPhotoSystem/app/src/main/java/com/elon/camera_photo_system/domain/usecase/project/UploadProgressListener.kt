package com.elon.camera_photo_system.domain.usecase.project

/**
 * 上传进度监听器接口
 */
interface UploadProgressListener {
    /**
     * 进度更新回调
     * @param uploaded 已上传数量
     * @param total 总数量
     */
    fun onProgress(uploaded: Int, total: Int)
} 