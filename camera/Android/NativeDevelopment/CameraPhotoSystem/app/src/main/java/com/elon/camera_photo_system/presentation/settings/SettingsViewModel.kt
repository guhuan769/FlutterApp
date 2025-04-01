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
import java.net.URL
import java.net.UnknownHostException

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
                try {
                    // 同时更新 UI 状态和 ApiConfig
                    apiConfig.updateBaseUrl(url)
                    _settingsUiState.update { currentState ->
                        currentState.copy(
                            apiUrl = url,
                            savedApiUrl = url,
                            hasUrlError = false,
                            urlErrorMessage = null
                        )
                    }
                    Log.d("SettingsViewModel", "初始化 URL: $url")
                } catch (e: Exception) {
                    // 即使初始URL有问题，也要显示它，但标记为错误
                    _settingsUiState.update { currentState ->
                        currentState.copy(
                            apiUrl = url,
                            savedApiUrl = url,
                            hasUrlError = true,
                            urlErrorMessage = "保存的URL格式不正确: ${e.message}"
                        )
                    }
                    Log.e("SettingsViewModel", "初始化URL格式错误: $url", e)
                }
            }
        }
    }
    
    /**
     * 更新API URL
     *
     * @param url 新的API URL
     */
    fun updateApiUrl(url: String) {
        val urlValidation = validateUrl(url)
        
        _settingsUiState.update { currentState ->
            currentState.copy(
                apiUrl = url,
                showSaveButton = url != currentState.savedApiUrl,
                hasUrlError = !urlValidation.isValid,
                urlErrorMessage = urlValidation.errorMessage
            )
        }
    }
    
    /**
     * 清除当前输入的URL
     */
    fun clearApiUrl() {
        _settingsUiState.update { currentState ->
            currentState.copy(
                apiUrl = "",
                showSaveButton = "" != currentState.savedApiUrl,
                hasUrlError = false,
                urlErrorMessage = null
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
                
                // 先验证URL
                val urlValidation = validateUrl(url)
                if (!urlValidation.isValid) {
                    _settingsUiState.update { currentState ->
                        currentState.copy(
                            hasUrlError = true,
                            urlErrorMessage = urlValidation.errorMessage,
                            errorMessage = "URL格式不正确: ${urlValidation.errorMessage}"
                        )
                    }
                    return@launch
                }
                
                // 更新 ApiConfig
                apiConfig.updateBaseUrl(url)
                Log.d("SettingsViewModel", "更新 ApiConfig.baseUrl: ${apiConfig.baseUrl}")
                
                // 保存到持久化存储
                settingsRepository.saveApiUrl(url)
                
                _settingsUiState.update { currentState ->
                    currentState.copy(
                        showSaveButton = false,
                        saveSuccess = true,
                        savedApiUrl = url,
                        hasUrlError = false,
                        urlErrorMessage = null
                    )
                }
            } catch (e: Exception) {
                Log.e("SettingsViewModel", "保存API URL失败", e)
                _settingsUiState.update { currentState ->
                    currentState.copy(
                        errorMessage = "保存失败: ${e.message}",
                        hasUrlError = true,
                        urlErrorMessage = e.message
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
                val url = _settingsUiState.value.apiUrl
                Log.d("SettingsViewModel", "开始测试连接: $url")
                
                // 基本URL格式验证
                val urlValidation = validateUrl(url)
                if (!urlValidation.isValid) {
                    _settingsUiState.update { currentState ->
                        currentState.copy(
                            isTesting = false,
                            testResult = TestResult(
                                success = false,
                                message = "URL格式不正确: ${urlValidation.errorMessage}"
                            ),
                            hasUrlError = true,
                            urlErrorMessage = urlValidation.errorMessage
                        )
                    }
                    return@launch
                }
                
                // 先更新ApiConfig确保使用最新的URL
                apiConfig.updateBaseUrl(url)
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
                            ),
                            hasUrlError = false,
                            urlErrorMessage = null
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
                    is UnknownHostException -> {
                        Log.e("SettingsViewModel", "无法解析主机名", e)
                        "无法解析主机名，请检查URL是否正确"
                    }
                    is IOException -> {
                        Log.e("SettingsViewModel", "网络连接失败", e)
                        "网络连接失败，请检查网络设置和服务器是否运行: ${e.message}"
                    }
                    is HttpException -> {
                        Log.e("SettingsViewModel", "HTTP错误: ${e.code()}", e)
                        "服务器错误: ${e.code()}"
                    }
                    is IllegalArgumentException -> {
                        Log.e("SettingsViewModel", "URL格式错误", e)
                        "URL格式错误: ${e.message}"
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
    
    /**
     * 验证URL并返回验证结果
     */
    private fun validateUrl(url: String): UrlValidationResult {
        if (url.isBlank()) {
            return UrlValidationResult(false, "URL不能为空")
        }
        
        try {
            // 尝试创建URL对象，如果格式不正确会抛出异常
            val formattedUrl = if (!url.startsWith("http://") && !url.startsWith("https://")) {
                "http://$url"
            } else url
            
            val urlObj = URL(formattedUrl)
            
            // 检查主机名
            if (urlObj.host.isBlank()) {
                return UrlValidationResult(false, "主机名不能为空")
            }
            
            if (!urlObj.host.contains(".")) {
                return UrlValidationResult(false, "主机名格式不正确，应包含域名部分")
            }
            
            if (urlObj.host.startsWith(".")) {
                return UrlValidationResult(false, "主机名不能以'.'开头")
            }
            
            // 检查端口
            if (urlObj.port > 0 && (urlObj.port < 1 || urlObj.port > 65535)) {
                return UrlValidationResult(false, "端口号无效，有效范围: 1-65535")
            }
            
            return UrlValidationResult(true, null)
        } catch (e: Exception) {
            Log.e("SettingsViewModel", "URL验证失败: $url", e)
            return UrlValidationResult(false, e.message ?: "URL格式不正确")
        }
    }
}

/**
 * URL验证结果
 */
data class UrlValidationResult(
    val isValid: Boolean,
    val errorMessage: String?
)

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
    val testResult: TestResult? = null,
    val hasUrlError: Boolean = false,
    val urlErrorMessage: String? = null
)

data class TestResult(
    val success: Boolean,
    val message: String
) 