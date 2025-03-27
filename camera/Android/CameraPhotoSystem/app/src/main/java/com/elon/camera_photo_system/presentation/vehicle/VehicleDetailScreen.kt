package com.elon.camera_photo_system.presentation.vehicle

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.elon.camera_photo_system.domain.model.Vehicle
import java.time.format.DateTimeFormatter

/**
 * 车辆详情界面
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VehicleDetailScreen(
    projectId: Long,
    vehicle: Vehicle?,
    isLoading: Boolean,
    error: String?,
    onNavigateBack: () -> Unit,
    onNavigateToTracks: () -> Unit,
    onNavigateToCamera: () -> Unit,
    onNavigateToGallery: () -> Unit
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(vehicle?.plateNumber ?: "车辆详情") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "返回")
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            if (isLoading) {
                // 加载状态
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            } else if (vehicle == null && error == null) {
                // 车辆不存在
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            imageVector = Icons.Default.Error,
                            contentDescription = null,
                            modifier = Modifier.size(48.dp),
                            tint = MaterialTheme.colorScheme.error
                        )
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        Text(
                            text = "车辆不存在",
                            style = MaterialTheme.typography.titleLarge,
                            color = MaterialTheme.colorScheme.error
                        )
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        Button(
                            onClick = onNavigateBack
                        ) {
                            Text("返回车辆列表")
                        }
                    }
                }
            } else if (vehicle != null) {
                // 车辆详情内容
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .padding(16.dp)
                ) {
                    // 导航路径提示
                    NavigationPathIndicator(projectId = projectId, vehiclePlateNumber = vehicle.plateNumber)
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    // 车辆概览卡片
                    VehicleOverviewCard(vehicle = vehicle)
                    
                    Spacer(modifier = Modifier.height(24.dp))
                    
                    // 功能入口
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        FunctionCard(
                            icon = Icons.Default.Timeline,
                            title = "轨迹管理",
                            description = "${vehicle.trackCount}条轨迹",
                            onClick = onNavigateToTracks,
                            color = MaterialTheme.colorScheme.secondary
                        )
                        
                        FunctionCard(
                            icon = Icons.Default.PhotoCamera,
                            title = "拍照",
                            description = "车辆照片",
                            onClick = onNavigateToCamera,
                            color = MaterialTheme.colorScheme.primary
                        )
                        
                        FunctionCard(
                            icon = Icons.Default.Collections,
                            title = "相册",
                            description = "${vehicle.photoCount}张照片",
                            onClick = onNavigateToGallery,
                            color = MaterialTheme.colorScheme.tertiary
                        )
                    }
                }
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
                    Snackbar {
                        Text(it)
                    }
                }
            }
        }
    }
}

/**
 * 导航路径指示器
 */
@Composable
private fun NavigationPathIndicator(projectId: Long, vehiclePlateNumber: String) {
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
                    text = vehiclePlateNumber,
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
private fun VehicleOverviewCard(vehicle: Vehicle) {
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
                        text = vehicle.plateNumber,
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Spacer(modifier = Modifier.height(4.dp))
                    
                    Text(
                        text = "${vehicle.brand} ${vehicle.model}",
                        style = MaterialTheme.typography.titleMedium,
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
                    value = vehicle.creationDate.format(dateFormatter)
                )
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
    color: Color
) {
    Card(
        modifier = Modifier
            .width(100.dp)
            .height(120.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        onClick = onClick,
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(8.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(RoundedCornerShape(percent = 50))
                    .background(color.copy(alpha = 0.15f)),
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
                fontWeight = FontWeight.Bold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            
            Text(
                text = description,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
} 