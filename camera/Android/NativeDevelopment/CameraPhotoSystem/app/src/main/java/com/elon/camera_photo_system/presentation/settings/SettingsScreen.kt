package com.elon.camera_photo_system.presentation.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.launch

/**
 * 设置界面
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    viewModel: SettingsViewModel,
    onNavigateBack: () -> Unit
) {
    val settingsUiState by viewModel.settingsUiState.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    
    // 显示保存成功或失败的消息
    LaunchedEffect(settingsUiState.saveSuccess, settingsUiState.errorMessage) {
        if (settingsUiState.saveSuccess) {
            snackbarHostState.showSnackbar("API URL保存成功")
            viewModel.clearSaveStatus()
        } else if (settingsUiState.errorMessage != null) {
            snackbarHostState.showSnackbar(settingsUiState.errorMessage ?: "保存失败")
            viewModel.clearSaveStatus()
        }
    }
    
    // 显示测试结果
    LaunchedEffect(settingsUiState.testResult) {
        settingsUiState.testResult?.let { result ->
            val message = if (result.success) {
                "连接测试成功"
            } else {
                "连接测试失败: ${result.message}"
            }
            snackbarHostState.showSnackbar(message)
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("设置") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.Default.ArrowBack,
                            contentDescription = "返回"
                        )
                    }
                },
                actions = {
                    if (settingsUiState.showSaveButton) {
                        IconButton(onClick = { viewModel.saveApiUrlSettings() }) {
                            Icon(
                                imageVector = Icons.Default.Check,
                                contentDescription = "保存"
                            )
                        }
                    }
                }
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "API 服务器设置",
                style = MaterialTheme.typography.titleLarge,
                modifier = Modifier.padding(bottom = 16.dp)
            )
            
            OutlinedTextField(
                value = settingsUiState.apiUrl,
                onValueChange = { viewModel.updateApiUrl(it) },
                label = { Text("API 服务器 URL") },
                modifier = Modifier.fillMaxWidth(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri),
                singleLine = true,
                supportingText = {
                    Text(
                        text = "提示：模拟器使用10.0.2.2，真机使用实际IP地址",
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // 测试连接按钮
            Button(
                onClick = { viewModel.testConnection() },
                modifier = Modifier.fillMaxWidth(),
                enabled = true
            ) {
                if (settingsUiState.isTesting) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                } else {
                    Row(
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Refresh,
                            contentDescription = null,
                            modifier = Modifier.padding(end = 8.dp)
                        )
                        Text("测试连接")
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // 显示当前保存的API URL
            Text(
                text = "当前API URL: ${settingsUiState.savedApiUrl}",
                style = MaterialTheme.typography.bodyMedium
            )
            
            // 显示测试结果
            settingsUiState.testResult?.let { result ->
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    Icon(
                        imageVector = if (result.success) Icons.Default.CheckCircle else Icons.Default.Error,
                        contentDescription = null,
                        tint = if (result.success) 
                            MaterialTheme.colorScheme.primary 
                        else 
                            MaterialTheme.colorScheme.error,
                        modifier = Modifier.padding(end = 8.dp)
                    )
                    Text(
                        text = if (result.success) "连接成功" else "连接失败: ${result.message}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = if (result.success) 
                            MaterialTheme.colorScheme.primary 
                        else 
                            MaterialTheme.colorScheme.error
                    )
                }
            }
        }
    }
} 