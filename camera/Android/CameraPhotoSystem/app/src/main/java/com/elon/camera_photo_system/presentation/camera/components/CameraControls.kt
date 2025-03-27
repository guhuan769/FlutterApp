package com.elon.camera_photo_system.presentation.camera.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
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
            PhotoTypeSelector(
                selectedPhotoType = selectedPhotoType,
                onPhotoTypeSelected = onPhotoTypeSelected,
                isTrackStarted = isTrackStarted,
                isTrackEnded = isTrackEnded
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

@Composable
fun PhotoTypeSelector(
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
        // 起始点 - 只有在轨迹未开始时可用
        PhotoTypeButton(
            text = "起始点",
            isSelected = selectedPhotoType == PhotoType.START_POINT,
            onClick = { onPhotoTypeSelected(PhotoType.START_POINT) },
            enabled = !isTrackStarted
        )
        
        // 中间点 - 只有在轨迹已开始且未结束时可用
        PhotoTypeButton(
            text = "中间点",
            isSelected = selectedPhotoType == PhotoType.MIDDLE_POINT,
            onClick = { onPhotoTypeSelected(PhotoType.MIDDLE_POINT) },
            enabled = isTrackStarted && !isTrackEnded
        )
        
        // 模型点 - 随时可用
        PhotoTypeButton(
            text = "模型点",
            isSelected = selectedPhotoType == PhotoType.MODEL_POINT,
            onClick = { onPhotoTypeSelected(PhotoType.MODEL_POINT) },
            enabled = true
        )
        
        // 结束点 - 只有在轨迹已开始且未结束时可用
        PhotoTypeButton(
            text = "结束点",
            isSelected = selectedPhotoType == PhotoType.END_POINT,
            onClick = { onPhotoTypeSelected(PhotoType.END_POINT) },
            enabled = isTrackStarted && !isTrackEnded
        )
    }
}

@Composable
fun PhotoTypeButton(
    text: String,
    isSelected: Boolean,
    onClick: () -> Unit,
    enabled: Boolean = true
) {
    Button(
        onClick = onClick,
        modifier = Modifier.padding(horizontal = 4.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = if (isSelected) 
                MaterialTheme.colorScheme.primary 
            else 
                MaterialTheme.colorScheme.secondary,
            disabledContainerColor = MaterialTheme.colorScheme.secondary.copy(alpha = 0.3f)
        ),
        enabled = enabled
    ) {
        Text(
            text = text, 
            style = MaterialTheme.typography.bodySmall,
            color = if (enabled) 
                MaterialTheme.colorScheme.onPrimary 
            else 
                MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.5f)
        )
    }
} 