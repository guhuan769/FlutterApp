package com.elon.camera_photo_system.presentation.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
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
import androidx.compose.foundation.clickable
import androidx.compose.ui.text.font.FontWeight

/**
 * 设置界面
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    viewModel: SettingsViewModel,
    onNavigateBack: () -> Unit,
    onNavigateToTypeManagement: () -> Unit
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
                "连接测试成功：${result.message}"
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
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "API 服务器设置",
                style = MaterialTheme.typography.titleLarge,
                modifier = Modifier.padding(bottom = 16.dp)
            )
            
            // URL输入字段
            OutlinedTextField(
                value = settingsUiState.apiUrl,
                onValueChange = { viewModel.updateApiUrl(it) },
                label = { Text("API 服务器 URL") },
                modifier = Modifier.fillMaxWidth(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri),
                singleLine = true,
                isError = settingsUiState.hasUrlError,
                supportingText = {
                    if (settingsUiState.hasUrlError) {
                        Text(
                            text = settingsUiState.urlErrorMessage ?: "URL格式不正确",
                            color = MaterialTheme.colorScheme.error
                        )
                    } else {
                        Text(
                            text = "提示：模拟器使用10.0.2.2，真机使用实际IP地址",
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                },
                trailingIcon = {
                    if (settingsUiState.apiUrl.isNotEmpty()) {
                        IconButton(onClick = { viewModel.clearApiUrl() }) {
                            Icon(
                                imageVector = Icons.Default.Clear,
                                contentDescription = "清除"
                            )
                        }
                    }
                }
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // 快速选择常用URL
            Text(
                text = "常用URL选择",
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.align(Alignment.Start)
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // 常用URL选项
            UrlOptionButton(
                text = "模拟器地址 (10.0.2.2:5000)",
                url = "http://10.0.2.2:5000/",
                onClick = { viewModel.updateApiUrl(it) }
            )
            
            UrlOptionButton(
                text = "本机地址 (127.0.0.1:5000)",
                url = "http://127.0.0.1:5000/",
                onClick = { viewModel.updateApiUrl(it) }
            )
            
            UrlOptionButton(
                text = "默认开发地址 (192.168.101.21:5000)",
                url = "http://192.168.101.21:5000/",
                onClick = { viewModel.updateApiUrl(it) }
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // 测试连接按钮
            Button(
                onClick = { viewModel.testConnection() },
                modifier = Modifier.fillMaxWidth(),
                enabled = !settingsUiState.hasUrlError && settingsUiState.apiUrl.isNotEmpty()
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
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Text(
                        text = "当前设置信息",
                        style = MaterialTheme.typography.titleMedium
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    Text(
                        text = "API URL: ${settingsUiState.savedApiUrl}",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
            
            // 显示测试结果
            settingsUiState.testResult?.let { result ->
                Spacer(modifier = Modifier.height(16.dp))
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = if (result.success) 
                            MaterialTheme.colorScheme.primaryContainer
                        else 
                            MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = if (result.success) Icons.Default.CheckCircle else Icons.Default.Error,
                            contentDescription = null,
                            tint = if (result.success) 
                                MaterialTheme.colorScheme.primary 
                            else 
                                MaterialTheme.colorScheme.error,
                            modifier = Modifier.padding(end = 16.dp)
                        )
                        Column {
                            Text(
                                text = if (result.success) "连接成功" else "连接失败",
                                style = MaterialTheme.typography.titleMedium,
                                color = if (result.success) 
                                    MaterialTheme.colorScheme.primary 
                                else 
                                    MaterialTheme.colorScheme.error
                            )
                            Text(
                                text = result.message,
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
                    }
                }
            }
            
            // 添加照片分类设置区域
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Text(
                        text = "照片分类管理",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    ListItem(
                        leadingContent = {
                            Icon(
                                imageVector = Icons.Default.Category,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary
                            )
                        },
                        headlineContent = { Text("管理照片分类类型") },
                        supportingContent = { Text("添加、编辑或删除模型和工艺类型") },
                        trailingContent = {
                            IconButton(onClick = onNavigateToTypeManagement) {
                                Icon(
                                    imageVector = Icons.Default.ArrowForward,
                                    contentDescription = "前往"
                                )
                            }
                        },
                        modifier = Modifier.clickable { onNavigateToTypeManagement() }
                    )
                }
            }
        }
    }
}

@Composable
fun UrlOptionButton(
    text: String,
    url: String,
    onClick: (String) -> Unit
) {
    OutlinedButton(
        onClick = { onClick(url) },
        modifier = Modifier.fillMaxWidth(),
        colors = ButtonDefaults.outlinedButtonColors(
            contentColor = MaterialTheme.colorScheme.primary
        )
    ) {
        Icon(
            imageVector = Icons.Default.Link,
            contentDescription = null,
            modifier = Modifier.padding(end = 8.dp)
        )
        Text(text = text)
    }
} 