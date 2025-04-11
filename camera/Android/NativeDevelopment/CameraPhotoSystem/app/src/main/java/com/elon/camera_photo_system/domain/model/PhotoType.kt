package com.elon.camera_photo_system.domain.model

/**
 * 照片类型枚举
 */
enum class PhotoType(val label: String) {
    START_POINT("起始点"),     // 起始点
    MIDDLE_POINT("中间点"),    // 中间点
    MODEL_POINT("模型点"),     // 模型点
    TRANSITION_POINT("过渡点"), // 过渡点
    END_POINT("结束点")        // 结束点
} 