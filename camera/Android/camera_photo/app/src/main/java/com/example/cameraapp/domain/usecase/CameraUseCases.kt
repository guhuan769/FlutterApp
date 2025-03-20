package com.example.cameraapp.domain.usecase

import android.content.Context
import android.net.Uri
import androidx.camera.view.PreviewView
import androidx.lifecycle.LifecycleOwner
import com.example.cameraapp.domain.repository.CameraRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class InitCameraUseCase @Inject constructor(
    private val cameraRepository: CameraRepository
) {
    operator fun invoke(
        lifecycleOwner: LifecycleOwner,
        previewView: PreviewView,
        lensFacing: Int
    ) = cameraRepository.initCamera(lifecycleOwner, previewView, lensFacing)
}

class TakePhotoUseCase @Inject constructor(
    private val cameraRepository: CameraRepository
) {
    suspend operator fun invoke(context: Context): Flow<Uri?> {
        return cameraRepository.takePhoto(context)
    }
}

class ToggleCameraUseCase @Inject constructor(
    private val cameraRepository: CameraRepository
) {
    operator fun invoke(preview: androidx.camera.core.Preview) {
        cameraRepository.toggleCamera(preview)
    }
}

class GetCurrentLensFacingUseCase @Inject constructor(
    private val cameraRepository: CameraRepository
) {
    operator fun invoke(): Int {
        return cameraRepository.getCurrentLensFacing()
    }
} 