package com.elon.camera_photo_system.presentation.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import com.elon.camera_photo_system.domain.model.upload.ModelType
import com.elon.camera_photo_system.domain.model.upload.ProcessType
import java.util.*

/**
 * 类型管理屏幕
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TypeManagementScreen(
    state: TypeManagementState,
    onAddModelType: (ModelType) -> Unit,
    onUpdateModelType: (ModelType) -> Unit,
    onDeleteModelType: (ModelType) -> Unit,
    onAddProcessType: (ProcessType) -> Unit,
    onUpdateProcessType: (ProcessType) -> Unit,
    onDeleteProcessType: (ProcessType) -> Unit,
    onNavigateBack: () -> Unit
) {
    val tabOptions = listOf("模型类型", "工艺类型")
    var selectedTabIndex by remember { mutableStateOf(0) }
    
    // 添加/编辑对话框状态
    var showModelTypeDialog by remember { mutableStateOf(false) }
    var editingModelType by remember { mutableStateOf<ModelType?>(null) }
    
    var showProcessTypeDialog by remember { mutableStateOf(false) }
    var editingProcessType by remember { mutableStateOf<ProcessType?>(null) }
    
    // 确认删除对话框状态
    var showDeleteModelTypeDialog by remember { mutableStateOf<ModelType?>(null) }
    var showDeleteProcessTypeDialog by remember { mutableStateOf<ProcessType?>(null) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("类型管理") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "返回")
                    }
                },
                actions = {
                    IconButton(
                        onClick = {
                            if (selectedTabIndex == 0) {
                                // 添加模型类型
                                editingModelType = null
                                showModelTypeDialog = true
                            } else {
                                // 添加工艺类型
                                editingProcessType = null
                                showProcessTypeDialog = true
                            }
                        }
                    ) {
                        Icon(Icons.Default.Add, contentDescription = "添加")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // 标签栏
            TabRow(
                selectedTabIndex = selectedTabIndex
            ) {
                tabOptions.forEachIndexed { index, text ->
                    Tab(
                        selected = selectedTabIndex == index,
                        onClick = { selectedTabIndex = index },
                        text = { Text(text) }
                    )
                }
            }
            
            // 错误信息
            if (state.error != null) {
                Text(
                    text = state.error,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                )
            }
            
            // 加载提示
            if (state.isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            } else {
                // 内容区域
                when (selectedTabIndex) {
                    0 -> {
                        // 模型类型列表
                        if (state.modelTypes.isEmpty()) {
                            Box(
                                modifier = Modifier.fillMaxSize(),
                                contentAlignment = Alignment.Center
                            ) {
                                Text("暂无模型类型，点击右上角添加")
                            }
                        } else {
                            LazyColumn(
                                modifier = Modifier.fillMaxSize(),
                                contentPadding = PaddingValues(16.dp),
                                verticalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                items(state.modelTypes) { modelType ->
                                    TypeItem(
                                        name = modelType.name,
                                        description = modelType.description,
                                        isDefault = modelType.id == ModelType.DEFAULT.id,
                                        onEdit = {
                                            editingModelType = modelType
                                            showModelTypeDialog = true
                                        },
                                        onDelete = {
                                            showDeleteModelTypeDialog = modelType
                                        }
                                    )
                                }
                            }
                        }
                    }
                    1 -> {
                        // 工艺类型列表
                        if (state.processTypes.isEmpty()) {
                            Box(
                                modifier = Modifier.fillMaxSize(),
                                contentAlignment = Alignment.Center
                            ) {
                                Text("暂无工艺类型，点击右上角添加")
                            }
                        } else {
                            LazyColumn(
                                modifier = Modifier.fillMaxSize(),
                                contentPadding = PaddingValues(16.dp),
                                verticalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                items(state.processTypes) { processType ->
                                    TypeItem(
                                        name = processType.name,
                                        description = processType.description,
                                        isDefault = processType.id == ProcessType.DEFAULT.id,
                                        onEdit = {
                                            editingProcessType = processType
                                            showProcessTypeDialog = true
                                        },
                                        onDelete = {
                                            showDeleteProcessTypeDialog = processType
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 模型类型编辑/添加对话框
    if (showModelTypeDialog) {
        TypeEditDialog(
            title = if (editingModelType == null) "添加模型类型" else "编辑模型类型",
            initialName = editingModelType?.name ?: "",
            initialDescription = editingModelType?.description ?: "",
            onDismiss = { showModelTypeDialog = false },
            onConfirm = { name, description ->
                if (editingModelType == null) {
                    // 添加新类型
                    onAddModelType(
                        ModelType(
                            id = UUID.randomUUID().toString(),
                            name = name,
                            description = description
                        )
                    )
                } else {
                    // 更新现有类型
                    onUpdateModelType(
                        editingModelType!!.copy(
                            name = name,
                            description = description
                        )
                    )
                }
                showModelTypeDialog = false
            }
        )
    }
    
    // 工艺类型编辑/添加对话框
    if (showProcessTypeDialog) {
        TypeEditDialog(
            title = if (editingProcessType == null) "添加工艺类型" else "编辑工艺类型",
            initialName = editingProcessType?.name ?: "",
            initialDescription = editingProcessType?.description ?: "",
            onDismiss = { showProcessTypeDialog = false },
            onConfirm = { name, description ->
                if (editingProcessType == null) {
                    // 添加新类型
                    onAddProcessType(
                        ProcessType(
                            id = UUID.randomUUID().toString(),
                            name = name,
                            description = description
                        )
                    )
                } else {
                    // 更新现有类型
                    onUpdateProcessType(
                        editingProcessType!!.copy(
                            name = name,
                            description = description
                        )
                    )
                }
                showProcessTypeDialog = false
            }
        )
    }
    
    // 删除确认对话框 - 模型类型
    showDeleteModelTypeDialog?.let { modelType ->
        AlertDialog(
            onDismissRequest = { showDeleteModelTypeDialog = null },
            title = { Text("删除模型类型") },
            text = { Text("确定要删除模型类型${modelType.name}吗？此操作不可撤销。") },
            confirmButton = {
                Button(
                    onClick = {
                        onDeleteModelType(modelType)
                        showDeleteModelTypeDialog = null
                    },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("删除")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteModelTypeDialog = null }) {
                    Text("取消")
                }
            }
        )
    }
    
    // 删除确认对话框 - 工艺类型
    showDeleteProcessTypeDialog?.let { processType ->
        AlertDialog(
            onDismissRequest = { showDeleteProcessTypeDialog = null },
            title = { Text("删除工艺类型") },
            text = { Text("确定要删除工艺类型${processType.name}吗？此操作不可撤销。") },
            confirmButton = {
                Button(
                    onClick = {
                        onDeleteProcessType(processType)
                        showDeleteProcessTypeDialog = null
                    },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("删除")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteProcessTypeDialog = null }) {
                    Text("取消")
                }
            }
        )
    }
}

/**
 * 类型项UI组件
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TypeItem(
    name: String,
    description: String,
    isDefault: Boolean = false,
    onEdit: () -> Unit,
    onDelete: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = if (isDefault) Icons.Default.Star else Icons.Default.Label,
                        contentDescription = null,
                        tint = if (isDefault) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    Text(
                        text = name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    
                    if (isDefault) {
                        Spacer(modifier = Modifier.width(8.dp))
                        
                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.primaryContainer
                            ),
                            modifier = Modifier.padding(horizontal = 4.dp)
                        ) {
                            Text(
                                text = "默认",
                                style = MaterialTheme.typography.labelSmall,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                color = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                        }
                    }
                }
                
                Row {
                    // 编辑按钮
                    IconButton(onClick = onEdit) {
                        Icon(
                            imageVector = Icons.Default.Edit,
                            contentDescription = "编辑"
                        )
                    }
                    
                    // 删除按钮 (默认类型不能删除)
                    if (!isDefault) {
                        IconButton(onClick = onDelete) {
                            Icon(
                                imageVector = Icons.Default.Delete,
                                contentDescription = "删除",
                                tint = MaterialTheme.colorScheme.error
                            )
                        }
                    }
                }
            }
            
            if (description.isNotEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                
                Text(
                    text = description,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}

/**
 * 类型编辑对话框
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TypeEditDialog(
    title: String,
    initialName: String = "",
    initialDescription: String = "",
    onDismiss: () -> Unit,
    onConfirm: (name: String, description: String) -> Unit
) {
    var name by remember { mutableStateOf(initialName) }
    var description by remember { mutableStateOf(initialDescription) }
    
    // 表单验证
    val isNameValid = name.isNotBlank()
    
    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = MaterialTheme.shapes.medium
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                
                // 名称输入框
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("名称 *") },
                    isError = !isNameValid && name.isNotEmpty(),
                    supportingText = { 
                        if (!isNameValid && name.isNotEmpty()) {
                            Text("名称不能为空")
                        }
                    },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                
                // 描述输入框
                OutlinedTextField(
                    value = description,
                    onValueChange = { description = it },
                    label = { Text("描述") },
                    minLines = 3,
                    maxLines = 5,
                    modifier = Modifier.fillMaxWidth()
                )
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End
                ) {
                    TextButton(onClick = onDismiss) {
                        Text("取消")
                    }
                    
                    Button(
                        onClick = { onConfirm(name.trim(), description.trim()) },
                        enabled = isNameValid
                    ) {
                        Text("确定")
                    }
                }
            }
        }
    }
} 