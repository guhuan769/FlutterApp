package com.elon.camera_photo_system.domain.model

/**
 * 上传状态枚举
 * 描述上传过程中的各种状态
 */
enum class UploadStatus {
    IDLE,           // 空闲状态，未开始上传
    UPLOADING,      // 正在上传
    SUCCESS,        // 上传成功
    PARTIAL_SUCCESS, // 部分上传成功
    NO_PHOTOS,      // 没有照片需要上传
    ALREADY_UPLOADED, // 已经上传过
    FAILED          // 上传失败
} 