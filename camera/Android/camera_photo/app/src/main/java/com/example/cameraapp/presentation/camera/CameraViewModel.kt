package com.example.cameraapp.presentation.camera

import android.content.Context
import androidx.camera.core.Preview
import androidx.camera.view.PreviewView
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.cameraapp.domain.model.CameraState
import com.example.cameraapp.domain.usecase.GetCurrentLensFacingUseCase
import com.example.cameraapp.domain.usecase.InitCameraUseCase
import com.example.cameraapp.domain.usecase.TakePhotoUseCase
import com.example.cameraapp.domain.usecase.ToggleCameraUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class CameraViewModel @Inject constructor(
    private val initCameraUseCase: InitCameraUseCase,
    private val takePhotoUseCase: TakePhotoUseCase,
    private val toggleCameraUseCase: ToggleCameraUseCase,
    private val getCurrentLensFacingUseCase: GetCurrentLensFacingUseCase
) : ViewModel() {

    private val _cameraState = MutableLiveData<CameraState>(CameraState.Initial)
    val cameraState: LiveData<CameraState> = _cameraState
    
    private lateinit var preview: Preview
    
    fun initializeCamera(previewView: PreviewView) {
        _cameraState.value = CameraState.Loading
        
        val lifecycleOwner = previewView.findViewTreeLifecycleOwner() ?: return
        val lensFacing = getCurrentLensFacingUseCase()
        
        initCameraUseCase(
            lifecycleOwner,
            previewView,
            lensFacing
        ).onEach { cameraProvider ->
            if (cameraProvider != null) {
                _cameraState.value = CameraState.Ready
            } else {
                _cameraState.value = CameraState.Error("无法初始化相机")
            }
        }.catch { e ->
            _cameraState.value = CameraState.Error(e.message ?: "未知错误")
        }.launchIn(viewModelScope)
    }
    
    fun takePhoto(context: Context) {
        viewModelScope.launch {
            _cameraState.value = CameraState.Loading
            
            takePhotoUseCase(context)
                .onEach { uri ->
                    if (uri != null) {
                        _cameraState.value = CameraState.PhotoCaptured(uri)
                    } else {
                        _cameraState.value = CameraState.Error("无法保存照片")
                    }
                }
                .catch { e ->
                    _cameraState.value = CameraState.Error(e.message ?: "拍照过程中出错")
                }
                .launchIn(this)
        }
    }
    
    fun toggleCamera() {
        toggleCameraUseCase(preview)
        
        // 重新初始化相机
        if (_cameraState.value is CameraState.Ready) {
            _cameraState.value = CameraState.Initial
        }
    }
} 