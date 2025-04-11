package com.elon.camera_photo_system.presentation.vehicle

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.elon.camera_photo_system.domain.model.Vehicle
import java.time.format.DateTimeFormatter

/**
 * 加载状态组件
 */
@Composable
private fun LoadingState(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier,
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator()
    }
}

/**
 * 错误状态组件
 */
@Composable
private fun ErrorState(
    message: String,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = message,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.error
        )
        Spacer(modifier = Modifier.height(16.dp))
        Button(onClick = onRetry) {
            Text(text = "重试")
        }
    }
}

/**
 * 空车辆状态组件
 */
@Composable
private fun EmptyVehicleState(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier,
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = "未找到车辆信息",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

/**
 * 车辆详情界面
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VehicleDetailScreen(
    viewModel: VehicleViewModel,
    onNavigateBack: () -> Unit,
    onNavigateToEdit: (Long) -> Unit,
    onNavigateToTrackList: (Long) -> Unit,
    onNavigateToProjectList: (Long) -> Unit,
    onNavigateToCamera: (Long) -> Unit,
    onNavigateToGallery: (Long) -> Unit,
    modifier: Modifier = Modifier
) {
    val vehicleState by viewModel.vehicleState.collectAsState()
    val vehicle = vehicleState.vehicle
    val isLoading = vehicleState.isLoading
    val error = vehicleState.error
    
    // 缓存不变的颜色和样式以减少重组
    val surfaceColor = MaterialTheme.colorScheme.surface
    val topAppBarContainerColor = MaterialTheme.colorScheme.primary
    val topAppBarContentColor = MaterialTheme.colorScheme.onPrimary
    
    // 添加进入动画效果
    val contentAlpha by animateFloatAsState(
        targetValue = if (isLoading) 0f else 1f,
        animationSpec = tween(durationMillis = 300)
    )
    
    Scaffold(
        modifier = modifier.fillMaxSize(),
        containerColor = surfaceColor,
        topBar = {
            TopAppBar(
                title = { Text(text = "车辆详情") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.Default.ArrowBack,
                            contentDescription = "返回"
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = topAppBarContainerColor,
                    titleContentColor = topAppBarContentColor,
                    navigationIconContentColor = topAppBarContentColor
                )
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // 使用key为整个内容区域提供一个稳定的身份，减少不必要的重组
            key(vehicle?.id) {
                when {
                    isLoading -> {
                        LoadingState(
                            modifier = Modifier.fillMaxSize()
                        )
                    }
                    error != null -> {
                        AnimatedVisibility(
                            visible = true,
                            enter = fadeIn(tween(300)),
                            exit = fadeOut(tween(300))
                        ) {
                            ErrorState(
                                message = error,
                                onRetry = { viewModel.loadVehicle(vehicle?.id ?: 0L) },
                                modifier = Modifier.fillMaxSize()
                            )
                        }
                    }
                    vehicle != null -> {
                        // 显示车辆详情
                        Column(
                            modifier = Modifier
                                .fillMaxSize()
                                .verticalScroll(rememberScrollState())
                                .padding(16.dp)
                                .graphicsLayer(alpha = contentAlpha)
                        ) {
                            // 车辆概览卡片
                            VehicleOverviewCard(
                                vehicle = vehicle,
                                onEditClick = { onNavigateToEdit(vehicle.id) }
                            )
                            
                            Spacer(modifier = Modifier.height(24.dp))
                            
                            // 功能区域 - 第一行
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(16.dp)
                            ) {
                                // 缓存颜色，减少重组
                                val primaryColor = MaterialTheme.colorScheme.primary
                                val secondaryColor = MaterialTheme.colorScheme.secondary
                                
                                FunctionCard(
                                    icon = Icons.Default.Timeline,
                                    title = "轨迹记录",
                                    description = "${vehicle.trackCount}条轨迹",
                                    color = primaryColor,
                                    onClick = { onNavigateToTrackList(vehicle.id) },
                                    modifier = Modifier.weight(1f)
                                )
                                
                                FunctionCard(
                                    icon = Icons.Default.Assignment,
                                    title = "项目管理",
                                    description = "${vehicle.projectCount}个项目",
                                    color = secondaryColor,
                                    onClick = { onNavigateToProjectList(vehicle.id) },
                                    modifier = Modifier.weight(1f)
                                )
                            }
                            
                            Spacer(modifier = Modifier.height(16.dp))
                            
                            // 功能区域 - 第二行（相机和相册功能）
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(16.dp)
                            ) {
                                // 缓存颜色，减少重组
                                val cameraColor = MaterialTheme.colorScheme.tertiary
                                val galleryColor = MaterialTheme.colorScheme.secondary
                                
                                FunctionCard(
                                    icon = Icons.Default.PhotoCamera,
                                    title = "拍照",
                                    description = "车辆拍照",
                                    color = cameraColor,
                                    onClick = { onNavigateToCamera(vehicle.id) },
                                    modifier = Modifier.weight(1f)
                                )
                                
                                FunctionCard(
                                    icon = Icons.Default.PhotoLibrary,
                                    title = "相册",
                                    description = "${vehicle.photoCount}张照片",
                                    color = galleryColor,
                                    onClick = { onNavigateToGallery(vehicle.id) },
                                    modifier = Modifier.weight(1f)
                                )
                            }
                        }
                    }
                    else -> {
                        AnimatedVisibility(
                            visible = true,
                            enter = fadeIn(tween(300)),
                            exit = fadeOut(tween(300))
                        ) {
                            EmptyVehicleState(
                                modifier = Modifier.fillMaxSize()
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun VehicleContent(
    vehicle: Vehicle,
    onNavigateToEdit: (Long) -> Unit,
    onNavigateToTrackList: (Long) -> Unit,
    onNavigateToProjectList: (Long) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier.animateContentSize(
            animationSpec = spring(
                dampingRatio = Spring.DampingRatioMediumBouncy,
                stiffness = Spring.StiffnessMedium
            )
        ),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item(key = "overview") {
            VehicleOverviewCard(
                vehicle = vehicle,
                onEditClick = { onNavigateToEdit(vehicle.id) }
            )
        }
        
        item(key = "functions") {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // 缓存颜色，减少重组
                val primaryColor = MaterialTheme.colorScheme.primary
                val secondaryColor = MaterialTheme.colorScheme.secondary
                
                FunctionCard(
                    icon = Icons.Default.Timeline,
                    title = "轨迹记录",
                    description = "${vehicle.trackCount}条轨迹",
                    color = primaryColor,
                    onClick = { onNavigateToTrackList(vehicle.id) },
                    modifier = Modifier.weight(1f)
                )
                
                FunctionCard(
                    icon = Icons.Default.Assignment,
                    title = "项目管理",
                    description = "${vehicle.projectCount}个项目",
                    color = secondaryColor,
                    onClick = { onNavigateToProjectList(vehicle.id) },
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

/**
 * 导航路径指示器
 */
@Composable
private fun NavigationPathIndicator(projectId: Long, vehicleName: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "项目 > 车辆 > ",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.primary,
                    fontWeight = FontWeight.Bold
                )
                
                Text(
                    text = vehicleName,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Bold
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = "您当前位于车辆详情页面，可以管理轨迹、拍照和查看相册。",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

/**
 * 车辆概览卡片
 */
@Composable
private fun VehicleOverviewCard(vehicle: Vehicle, onEditClick: () -> Unit) {
    val dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")
    
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // 车辆基本信息
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // 车辆图标
                Box(
                    modifier = Modifier
                        .size(64.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .background(MaterialTheme.colorScheme.secondaryContainer),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.DirectionsCar,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSecondaryContainer,
                        modifier = Modifier.size(40.dp)
                    )
                }
                
                Spacer(modifier = Modifier.width(16.dp))
                
                // 车辆信息
                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        text = vehicle.name,
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Spacer(modifier = Modifier.height(4.dp))
                    
                    Text(
                        text = "${vehicle.brand} ${vehicle.model}",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    
                    Spacer(modifier = Modifier.height(4.dp))
                    
                    Text(
                        text = "车牌号: ${vehicle.plateNumber}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Divider()
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // 统计信息
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                InfoItem(
                    icon = Icons.Default.Timeline,
                    label = "轨迹数量",
                    value = "${vehicle.trackCount}"
                )
                
                InfoItem(
                    icon = Icons.Default.Photo,
                    label = "照片数量",
                    value = "${vehicle.photoCount}"
                )
                
                InfoItem(
                    icon = Icons.Default.CalendarToday,
                    label = "创建时间",
                    value = vehicle.createdAt.format(dateFormatter)
                )
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Button(
                onClick = onEditClick
            ) {
                Text("编辑车辆")
            }
        }
    }
}

/**
 * 信息项
 */
@Composable
private fun InfoItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    value: String
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.secondary
        )
        
        Spacer(modifier = Modifier.height(4.dp))
        
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Spacer(modifier = Modifier.height(2.dp))
        
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium
        )
    }
}

/**
 * 功能卡片
 */
@Composable
private fun FunctionCard(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    description: String,
    onClick: () -> Unit,
    color: Color,
    modifier: Modifier = Modifier
) {
    // 缓存不变的值，减少重组
    val cardElevation = 2.dp
    val cardShape = RoundedCornerShape(12.dp)
    val iconSize = 40.dp
    val iconBackgroundAlpha = 0.2f
    
    Card(
        onClick = onClick,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = cardElevation
        ),
        shape = cardShape,
        modifier = modifier
            .height(120.dp)
            .animateContentSize()
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Box(
                modifier = Modifier
                    .size(iconSize)
                    .clip(RoundedCornerShape(12.dp))
                    .background(color.copy(alpha = iconBackgroundAlpha)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = color,
                    modifier = Modifier.size(24.dp)
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface,
                fontWeight = FontWeight.Medium
            )
            
            // 使用AnimatedVisibility为描述文本添加动画
            AnimatedVisibility(
                visible = description.isNotEmpty(),
                enter = fadeIn() + expandVertically(),
                exit = fadeOut() + shrinkVertically()
            ) {
                Text(
                    text = description,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
} 