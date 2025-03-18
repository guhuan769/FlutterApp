package com.elon.camera_photo_system.domain.model

/**
 * 照片类型枚举，表示不同场景下的拍照类型
 */
enum class PhotoType(val displayName: String) {
    START_POINT("起始点拍照"),
    MIDDLE_POINT("中间点拍照"),
    MODEL_POINT("模型点拍照"),
    END_POINT("结束点拍照");

    companion object {
        /**
         * 根据照片类型生成文件名
         * @param type 照片类型
         * @param sequence 序号
         * @return 格式化的文件名
         */
        fun generateFileName(type: PhotoType, sequence: Int): String {
            return "${type.displayName}_${sequence}"
        }
    }
} 