package com.example.cameraapp.domain.model

import android.net.Uri

sealed class CameraState {
    object Initial : CameraState()
    object Loading : CameraState()
    object Ready : CameraState() 
    data class Error(val message: String) : CameraState()
    data class PhotoCaptured(val uri: Uri) : CameraState()
} 