package com.elon.camera_photo_system.presentation.camera.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.PhotoType

@Composable
fun CameraControls(
    moduleType: ModuleType,
    selectedPhotoType: PhotoType,
    onPhotoTypeSelected: (PhotoType) -> Unit,
    isCapturing: Boolean,
    onCaptureClick: () -> Unit,
    isTrackStarted: Boolean = false,
    isTrackEnded: Boolean = false
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // 照片类型选择器
        if (moduleType == ModuleType.TRACK) {
            TrackPhotoTypeSelector(
                selectedPhotoType = selectedPhotoType,
                onPhotoTypeSelected = onPhotoTypeSelected,
                isTrackStarted = isTrackStarted,
                isTrackEnded = isTrackEnded
            )
            Spacer(modifier = Modifier.height(24.dp))
        } else {
            PhotoTypeSelector(
                selectedPhotoType = selectedPhotoType,
                onPhotoTypeSelected = onPhotoTypeSelected
            )
            Spacer(modifier = Modifier.height(24.dp))
        }
        
        // 拍照按钮
        Box(
            modifier = Modifier
                .size(80.dp)
                .clip(CircleShape)
                .border(
                    width = 4.dp,
                    color = if (isCapturing) 
                        MaterialTheme.colorScheme.primary.copy(alpha = 0.5f)
                    else 
                        MaterialTheme.colorScheme.primary,
                    shape = CircleShape
                )
                .padding(4.dp)
        ) {
            Button(
                onClick = onCaptureClick,
                modifier = Modifier
                    .fillMaxSize()
                    .clip(CircleShape),
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (isCapturing)
                        MaterialTheme.colorScheme.primary.copy(alpha = 0.5f)
                    else
                        MaterialTheme.colorScheme.primary,
                    disabledContainerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.3f)
                ),
                enabled = !isCapturing
            ) {}
        }
    }
}

/**
 * 轨迹模式下的照片类型选择器
 */
@Composable
fun TrackPhotoTypeSelector(
    selectedPhotoType: PhotoType,
    onPhotoTypeSelected: (PhotoType) -> Unit,
    isTrackStarted: Boolean = false,
    isTrackEnded: Boolean = false
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        // 只显示四种特定点类型
        // 起始点 - 只有在轨迹未开始时可用
        TrackPhotoTypeButton(
            text = "起始点",
            isSelected = selectedPhotoType == PhotoType.START_POINT,
            color = MaterialTheme.colorScheme.primary,
            onClick = { onPhotoTypeSelected(PhotoType.START_POINT) },
            enabled = !isTrackStarted
        )
        
        // 中间点 - 只有在轨迹已开始且未结束时可用
        TrackPhotoTypeButton(
            text = "中间点",
            isSelected = selectedPhotoType == PhotoType.MIDDLE_POINT,
            color = MaterialTheme.colorScheme.secondary,
            onClick = { onPhotoTypeSelected(PhotoType.MIDDLE_POINT) },
            enabled = isTrackStarted && !isTrackEnded
        )
        
        // 模型点 - 随时可用
        TrackPhotoTypeButton(
            text = "模型点",
            isSelected = selectedPhotoType == PhotoType.MODEL_POINT,
            color = MaterialTheme.colorScheme.tertiary,
            onClick = { onPhotoTypeSelected(PhotoType.MODEL_POINT) },
            enabled = true
        )
        
        // 结束点 - 只有在轨迹已开始且未结束时可用
        TrackPhotoTypeButton(
            text = "结束点",
            isSelected = selectedPhotoType == PhotoType.END_POINT,
            color = MaterialTheme.colorScheme.error,
            onClick = { onPhotoTypeSelected(PhotoType.END_POINT) },
            enabled = isTrackStarted && !isTrackEnded
        )
    }
}

/**
 * 普通模式下的照片类型选择器
 */
@Composable
fun PhotoTypeSelector(
    selectedPhotoType: PhotoType,
    onPhotoTypeSelected: (PhotoType) -> Unit
) {
    Button(
        onClick = { onPhotoTypeSelected(PhotoType.MODEL_POINT) },
        modifier = Modifier
            .fillMaxWidth()
            .height(50.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = MaterialTheme.colorScheme.primary,
            contentColor = MaterialTheme.colorScheme.onPrimary
        )
    ) {
        Text(
            text = "模型点拍照", 
            style = MaterialTheme.typography.bodyMedium
        )
    }
}

/**
 * 轨迹照片类型按钮
 */
@Composable
fun TrackPhotoTypeButton(
    text: String,
    isSelected: Boolean,
    color: Color,
    onClick: () -> Unit,
    enabled: Boolean = true
) {
    Button(
        onClick = onClick,
        modifier = Modifier.padding(horizontal = 4.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = if (isSelected) color else color.copy(alpha = 0.6f),
            disabledContainerColor = color.copy(alpha = 0.3f)
        ),
        shape = RoundedCornerShape(8.dp),
        enabled = enabled
    ) {
        Text(
            text = text, 
            style = MaterialTheme.typography.bodySmall,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
            color = if (enabled) 
                MaterialTheme.colorScheme.onPrimary 
            else 
                MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.5f)
        )
    }
} 