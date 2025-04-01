package com.elon.camera_photo_system.presentation.settings

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.elon.camera_photo_system.data.api.ApiService
import com.elon.camera_photo_system.data.remote.ApiConfig
import com.elon.camera_photo_system.domain.repository.SettingsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject
import retrofit2.HttpException
import java.io.IOException

/**
 * 设置视图模型
 */
@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val settingsRepository: SettingsRepository,
    private val apiService: ApiService,
    private val apiConfig: ApiConfig
) : ViewModel() {
    
    private val _settingsUiState = MutableStateFlow(SettingsUiState())
    val settingsUiState: StateFlow<SettingsUiState> = _settingsUiState.asStateFlow()
    
    init {
        viewModelScope.launch {
            settingsRepository.getApiUrl().collect { url ->
                // 同时更新 UI 状态和 ApiConfig
                apiConfig.updateBaseUrl(url)
                _settingsUiState.update { currentState ->
                    currentState.copy(
                        apiUrl = url,
                        savedApiUrl = url
                    )
                }
                Log.d("SettingsViewModel", "初始化 URL: $url")
            }
        }
    }
    
    /**
     * 更新API URL
     *
     * @param url 新的API URL
     */
    fun updateApiUrl(url: String) {
        _settingsUiState.update { currentState ->
            currentState.copy(
                apiUrl = url,
                showSaveButton = url != currentState.savedApiUrl
            )
        }
    }
    
    /**
     * 保存API URL设置
     */
    fun saveApiUrlSettings() {
        viewModelScope.launch {
            try {
                val url = _settingsUiState.value.apiUrl
                // 先更新 ApiConfig
                apiConfig.updateBaseUrl(url)
                Log.d("SettingsViewModel", "更新 ApiConfig.baseUrl: ${apiConfig.baseUrl}")
                
                // 再保存到持久化存储
                settingsRepository.saveApiUrl(url)
                
                _settingsUiState.update { currentState ->
                    currentState.copy(
                        showSaveButton = false,
                        saveSuccess = true,
                        savedApiUrl = url
                    )
                }
            } catch (e: Exception) {
                Log.e("SettingsViewModel", "保存API URL失败", e)
                _settingsUiState.update { currentState ->
                    currentState.copy(
                        errorMessage = "保存失败: ${e.message}"
                    )
                }
            }
        }
    }
    
    /**
     * 清除保存状态
     */
    fun clearSaveStatus() {
        _settingsUiState.update { currentState ->
            currentState.copy(
                saveSuccess = false,
                errorMessage = null
            )
        }
    }

    /**
     * 测试API连接
     */
    fun testConnection() {
        viewModelScope.launch {
            _settingsUiState.update { currentState ->
                currentState.copy(
                    isTesting = true,
                    testResult = null
                )
            }
            
            try {
                Log.d("SettingsViewModel", "开始测试连接: ${_settingsUiState.value.apiUrl}")
                
                // 先更新ApiConfig确保使用最新的URL
                apiConfig.updateBaseUrl(_settingsUiState.value.apiUrl)
                Log.d("SettingsViewModel", "已更新ApiConfig: ${apiConfig.baseUrl}")
                
                val response = apiService.testConnection()
                
                if (response.isSuccessful) {
                    val testResponse = response.body()
                    Log.d("SettingsViewModel", "连接测试成功: ${testResponse?.message}")
                    _settingsUiState.update { currentState ->
                        currentState.copy(
                            isTesting = false,
                            testResult = TestResult(
                                success = true,
                                message = testResponse?.message ?: "连接成功"
                            )
                        )
                    }
                } else {
                    Log.e("SettingsViewModel", "服务器响应错误: ${response.code()}")
                    _settingsUiState.update { currentState ->
                        currentState.copy(
                            isTesting = false,
                            testResult = TestResult(
                                success = false,
                                message = "服务器响应错误: ${response.code()}"
                            )
                        )
                    }
                }
            } catch (e: Exception) {
                val errorMessage = when (e) {
                    is IOException -> {
                        Log.e("SettingsViewModel", "网络连接失败", e)
                        "网络连接失败，请检查网络设置和服务器是否运行"
                    }
                    is HttpException -> {
                        Log.e("SettingsViewModel", "HTTP错误: ${e.code()}", e)
                        "服务器错误: ${e.code()}"
                    }
                    else -> {
                        Log.e("SettingsViewModel", "未知错误", e)
                        "未知错误: ${e.message}"
                    }
                }
                
                _settingsUiState.update { currentState ->
                    currentState.copy(
                        isTesting = false,
                        testResult = TestResult(
                            success = false,
                            message = errorMessage
                        )
                    )
                }
            }
        }
    }
}

/**
 * 设置UI状态
 */
data class SettingsUiState(
    val apiUrl: String = "",
    val savedApiUrl: String = "",
    val showSaveButton: Boolean = false,
    val saveSuccess: Boolean = false,
    val errorMessage: String? = null,
    val isTesting: Boolean = false,
    val testResult: TestResult? = null
)

data class TestResult(
    val success: Boolean,
    val message: String
) 