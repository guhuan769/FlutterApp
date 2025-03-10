//package com.example.camera_photo
//
//import android.app.Activity
//import android.content.Context
//import android.hardware.camera2.*
//import android.media.ImageReader
//import android.view.Surface
//import io.flutter.plugin.common.MethodChannel
//import java.io.File
//import java.util.concurrent.Executors
//
//class NativeCameraModule(private val context: Context) {
//    private var cameraDevice: CameraDevice? = null
//    private var imageReader: ImageReader? = null
//    private val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
//    private val backgroundThread = Executors.newSingleThreadExecutor()
//
//    fun openCamera(result: MethodChannel.Result) {
//        try {
//            val cameraId = cameraManager.cameraIdList[0] // 默认使用后置相机
//
//            // 获取相机特性
//            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
//
//            // 获取最大分辨率
//            val streamConfigurationMap = characteristics.get(
//                CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
//            val largestSize = streamConfigurationMap?.getOutputSizes(ImageFormat.JPEG)?.maxByOrNull {
//                it.width * it.height
//            }
//
//            // 创建 ImageReader
//            imageReader = ImageReader.newInstance(
//                largestSize!!.width,
//                largestSize.height,
//                ImageFormat.JPEG,
//                2
//            )
//
//            // 设置图片可用的监听器
//            imageReader?.setOnImageAvailableListener({ reader ->
//                val image = reader.acquireLatestImage()
//                // 处理图片...
//                image?.close()
//            }, backgroundThread)
//
//            // 打开相机
//            cameraManager.openCamera(cameraId, object : CameraDevice.StateCallback() {
//                override fun onOpened(camera: CameraDevice) {
//                    cameraDevice = camera
//                    result.success(true)
//                }
//
//                override fun onDisconnected(camera: CameraDevice) {
//                    camera.close()
//                    cameraDevice = null
//                }
//
//                override fun onError(camera: CameraDevice, error: Int) {
//                    camera.close()
//                    cameraDevice = null
//                    result.error("CAMERA_ERROR", "Failed to open camera", null)
//                }
//            }, null)
//        } catch (e: Exception) {
//            result.error("CAMERA_ERROR", e.message, null)
//        }
//    }
//
//    fun takePicture(path: String, result: MethodChannel.Result) {
//        try {
//            val captureBuilder = cameraDevice?.createCaptureRequest(
//                CameraDevice.TEMPLATE_STILL_CAPTURE)?.apply {
//                addTarget(imageReader!!.surface)
//                set(CaptureRequest.CONTROL_AF_MODE,
//                    CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE)
//                set(CaptureRequest.CONTROL_AE_MODE,
//                    CaptureRequest.CONTROL_AE_MODE_ON_AUTO_FLASH)
//            }
//
//            // 创建拍照会话
//            val surfaces = ArrayList<Surface>().apply {
//                add(imageReader!!.surface)
//            }
//
//            cameraDevice?.createCaptureSession(surfaces,
//                object : CameraCaptureSession.StateCallback() {
//                    override fun onConfigured(session: CameraCaptureSession) {
//                        session.capture(captureBuilder!!.build(),
//                            object : CameraCaptureSession.CaptureCallback() {
//                                override fun onCaptureCompleted(
//                                    session: CameraCaptureSession,
//                                    request: CaptureRequest,
//                                    result: TotalCaptureResult
//                                ) {
//                                    // 拍照完成，保存图片
//                                    result.success(true)
//                                }
//                            }, null)
//                    }
//
//                    override fun onConfigureFailed(session: CameraCaptureSession) {
//                        result.error("CAPTURE_ERROR", "Failed to configure capture session", null)
//                    }
//                }, null)
//        } catch (e: Exception) {
//            result.error("CAPTURE_ERROR", e.message, null)
//        }
//    }
//
//    fun closeCamera() {
//        try {
//            cameraDevice?.close()
//            cameraDevice = null
//            imageReader?.close()
//            imageReader = null
//            backgroundThread.shutdown()
//        } catch (e: Exception) {
//            // 处理关闭错误
//        }
//    }
//}