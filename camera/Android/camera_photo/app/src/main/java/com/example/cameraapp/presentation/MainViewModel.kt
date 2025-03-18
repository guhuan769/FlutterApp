package com.example.cameraapp.presentation

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class MainViewModel @Inject constructor() : ViewModel() {

    private val _permissionsGranted = MutableLiveData<Boolean>()
    val permissionsGranted: LiveData<Boolean> get() = _permissionsGranted

    init {
        _permissionsGranted.value = false
    }

    fun setPermissionsGranted(granted: Boolean) {
        _permissionsGranted.value = granted
    }
} 