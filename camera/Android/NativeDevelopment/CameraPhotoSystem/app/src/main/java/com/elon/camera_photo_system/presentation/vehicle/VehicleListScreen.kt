package com.elon.camera_photo_system.presentation.vehicle

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.elon.camera_photo_system.domain.model.Vehicle
import com.google.accompanist.swiperefresh.SwipeRefresh
import com.google.accompanist.swiperefresh.rememberSwipeRefreshState

/**
 * 车辆列表界面
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VehicleListScreen(
    projectId: Long,
    vehicles: List<Vehicle>,
    isLoading: Boolean,
    error: String?,
    onNavigateBack: () -> Unit,
    onVehicleClick: (Vehicle) -> Unit,
    onRefresh: () -> Unit,
    addVehicleState: AddVehicleState,
    onAddVehicleClick: () -> Unit,
    onAddVehicleDismiss: () -> Unit,
    onAddVehicleFieldChanged: (AddVehicleField, String) -> Unit,
    onAddVehicleSubmit: () -> Unit,
    onDeleteVehicle: (Vehicle) -> Unit
) {
    val swipeRefreshState = rememberSwipeRefreshState(isLoading)
    
    var showAddVehicleDialog by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf<Vehicle?>(null) }
    
    LaunchedEffect(addVehicleState.isSuccess) {
        if (addVehicleState.isSuccess) {
            showAddVehicleDialog = false
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("车辆列表") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "返回")
                    }
                },
                actions = {
                    IconButton(onClick = { 
                        showAddVehicleDialog = true
                        onAddVehicleClick()
                    }) {
                        Icon(Icons.Default.Add, contentDescription = "添加车辆")
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { 
                    showAddVehicleDialog = true
                    onAddVehicleClick()
                }
            ) {
                Icon(Icons.Default.Add, contentDescription = "添加车辆")
            }
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // 导航路径提示
            NavigationPathBar(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp)
            )
            
            SwipeRefresh(
                state = swipeRefreshState,
                onRefresh = onRefresh,
                modifier = Modifier
                    .fillMaxSize()
                    .padding(top = 56.dp) // 为导航路径提示预留空间
            ) {
                if (vehicles.isEmpty() && !isLoading) {
                    // 空状态
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.Info,
                                contentDescription = null,
                                modifier = Modifier.size(48.dp),
                                tint = MaterialTheme.colorScheme.primary
                            )
                            
                            Spacer(modifier = Modifier.height(16.dp))
                            
                            Text(
                                text = "暂无车辆",
                                style = MaterialTheme.typography.titleLarge,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            
                            Spacer(modifier = Modifier.height(8.dp))
                            
                            Text(
                                text = "点击右下角按钮添加车辆",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                } else {
                    // 车辆列表
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        items(vehicles) { vehicle ->
                            VehicleItem(
                                vehicle = vehicle,
                                onClick = { onVehicleClick(vehicle) },
                                onDelete = { showDeleteDialog = vehicle }
                            )
                        }
                    }
                }
            }
            
            // 加载指示器
            AnimatedVisibility(
                visible = isLoading,
                enter = fadeIn(),
                exit = fadeOut(),
                modifier = Modifier.align(Alignment.Center)
            ) {
                CircularProgressIndicator()
            }
            
            // 错误提示
            AnimatedVisibility(
                visible = error != null,
                enter = fadeIn(),
                exit = fadeOut(),
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(16.dp)
            ) {
                error?.let {
                    Snackbar(
                        action = {
                            TextButton(onClick = onRefresh) {
                                Text("重试")
                            }
                        }
                    ) {
                        Text(it)
                    }
                }
            }
            
            // 添加车辆对话框
            if (showAddVehicleDialog) {
                AddVehicleDialog(
                    isSubmitting = addVehicleState.isSubmitting,
                    error = addVehicleState.error,
                    nameValue = addVehicleState.name,
                    nameError = addVehicleState.nameError,
                    plateNumberValue = addVehicleState.plateNumber,
                    plateNumberError = addVehicleState.plateNumberError,
                    brandValue = addVehicleState.brand,
                    modelValue = addVehicleState.model,
                    onNameChanged = { onAddVehicleFieldChanged(AddVehicleField.NAME, it) },
                    onPlateNumberChanged = { onAddVehicleFieldChanged(AddVehicleField.PLATE_NUMBER, it) },
                    onBrandChanged = { onAddVehicleFieldChanged(AddVehicleField.BRAND, it) },
                    onModelChanged = { onAddVehicleFieldChanged(AddVehicleField.MODEL, it) },
                    onDismissRequest = {
                        showAddVehicleDialog = false
                        onAddVehicleDismiss()
                    },
                    onAddClick = onAddVehicleSubmit
                )
            }
            
            // 删除确认对话框
            showDeleteDialog?.let { vehicle ->
                AlertDialog(
                    onDismissRequest = { showDeleteDialog = null },
                    icon = {
                        Icon(
                            imageVector = Icons.Default.Delete,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.error
                        )
                    },
                    title = {
                        Text(
                            text = "确认删除车辆",
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold
                        )
                    },
                    text = {
                        Column {
                            Text(
                                text = "您确定要删除车辆\"${vehicle.plateNumber}\"吗？",
                                style = MaterialTheme.typography.bodyLarge
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "此操作将同时删除：",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            BulletText("所有关联的轨迹数据")
                            BulletText("所有关联的照片数据")
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "此操作不可撤销！",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.error,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    },
                    confirmButton = {
                        Button(
                            onClick = {
                                onDeleteVehicle(vehicle)
                                showDeleteDialog = null
                            },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.error
                            )
                        ) {
                            Text("确认删除")
                        }
                    },
                    dismissButton = {
                        OutlinedButton(onClick = { showDeleteDialog = null }) {
                            Text("取消")
                        }
                    }
                )
            }
        }
    }
}

/**
 * 导航路径提示栏
 */
@Composable
private fun NavigationPathBar(modifier: Modifier = Modifier) {
    Surface(
        modifier = modifier,
        color = MaterialTheme.colorScheme.surfaceVariant,
        shape = RoundedCornerShape(8.dp),
        tonalElevation = 2.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "项目 > 车辆列表",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun BulletText(text: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.padding(vertical = 2.dp)
    ) {
        Box(
            modifier = Modifier
                .size(4.dp)
                .background(
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    shape = CircleShape
                )
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = text,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

/**
 * 车辆列表项
 */
@Composable
fun VehicleItem(
    vehicle: Vehicle,
    onClick: () -> Unit,
    onDelete: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            // 左侧：车辆信息
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.weight(1f)
            ) {
                // 车辆图标
                Card(
                    modifier = Modifier
                        .size(56.dp)
                        .clip(RoundedCornerShape(8.dp)),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.secondaryContainer
                    )
                ) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.DirectionsCar,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSecondaryContainer,
                            modifier = Modifier.size(28.dp)
                        )
                    }
                }
                
                Spacer(modifier = Modifier.width(16.dp))
                
                // 车辆信息
                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        text = vehicle.plateNumber,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    
                    Spacer(modifier = Modifier.height(4.dp))
                    
                    Text(
                        text = "${vehicle.brand} ${vehicle.model}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    
                    Spacer(modifier = Modifier.height(4.dp))
                    
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Text(
                            text = "轨迹: ${vehicle.trackCount}",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        
                        Text(
                            text = "照片: ${vehicle.photoCount}",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
            
            // 右侧：删除按钮
            IconButton(
                onClick = onDelete,
                colors = IconButtonDefaults.iconButtonColors(
                    contentColor = MaterialTheme.colorScheme.error
                )
            ) {
                Icon(
                    imageVector = Icons.Default.Delete,
                    contentDescription = "删除车辆"
                )
            }
        }
    }
} 