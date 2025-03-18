package com.elon.camera_photo_system.domain.model

/**
 * 相机状态类，用于表示相机的各种状态和配置
 * @property flashMode 闪光灯模式
 * @property lensFacing 相机镜头方向
 * @property captureMode 拍摄模式
 * @property zoomRatio 缩放比例
 * @property hasFlashUnit 是否有闪光灯
 * @property isCapturing 是否正在拍照
 * @property isInitialized 相机是否已初始化
 */
data class CameraState(
    val flashMode: FlashMode = FlashMode.OFF,
    val lensFacing: LensFacing = LensFacing.BACK,
    val captureMode: CaptureMode = CaptureMode.PHOTO,
    val zoomRatio: Float = 1.0f,
    val hasFlashUnit: Boolean = false,
    val isCapturing: Boolean = false,
    val isInitialized: Boolean = false
)

/**
 * 闪光灯模式
 */
enum class FlashMode {
    AUTO, ON, OFF
}

/**
 * 相机镜头方向
 */
enum class LensFacing {
    FRONT, BACK
}

/**
 * 拍摄模式
 */
enum class CaptureMode {
    PHOTO, VIDEO
} 