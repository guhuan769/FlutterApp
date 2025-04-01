package com.elon.camera_photo_system.presentation.camera.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.PhotoType

@Composable
fun CameraOverlay(
    moduleType: ModuleType,
    selectedPhotoType: PhotoType,
    cameraZoom: Float
) {
    Box(modifier = Modifier.fillMaxSize()) {
        // 拍照提示
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.TopCenter)
                .padding(top = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = when (moduleType) {
                    ModuleType.PROJECT -> "项目照片"
                    ModuleType.VEHICLE -> "车辆照片"
                    ModuleType.TRACK -> when (selectedPhotoType) {
                        PhotoType.START_POINT -> "起始点拍照"
                        PhotoType.MIDDLE_POINT -> "中间点拍照"
                        PhotoType.MODEL_POINT -> "模型点拍照"
                        PhotoType.END_POINT -> "结束点拍照"
                    }
                },
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onBackground
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = "请将拍摄对象置于取景框中心",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f)
            )
            
            if (cameraZoom > 1f) {
                Text(
                    text = "当前缩放: ${String.format("%.1f", cameraZoom)}x",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }
        
        // 取景框和辅助线
        Canvas(modifier = Modifier.fillMaxSize()) {
            val canvasWidth = size.width
            val canvasHeight = size.height
            val centerX = canvasWidth / 2
            val centerY = canvasHeight / 2
            
            // 九宫格辅助线
            val gridSpacing = canvasWidth / 3
            for (i in 1..2) {
                drawLine(
                    color = Color.White.copy(alpha = 0.5f),
                    start = androidx.compose.ui.geometry.Offset(gridSpacing * i, 0f),
                    end = androidx.compose.ui.geometry.Offset(gridSpacing * i, canvasHeight),
                    strokeWidth = 1f
                )
                drawLine(
                    color = Color.White.copy(alpha = 0.5f),
                    start = androidx.compose.ui.geometry.Offset(0f, gridSpacing * i),
                    end = androidx.compose.ui.geometry.Offset(canvasWidth, gridSpacing * i),
                    strokeWidth = 1f
                )
            }
            
            // 中心十字标记
            val lineLength = 40.dp.toPx()
            drawLine(
                color = Color.White,
                start = androidx.compose.ui.geometry.Offset(centerX - lineLength / 2, centerY),
                end = androidx.compose.ui.geometry.Offset(centerX + lineLength / 2, centerY),
                strokeWidth = 3f
            )
            drawLine(
                color = Color.White,
                start = androidx.compose.ui.geometry.Offset(centerX, centerY - lineLength / 2),
                end = androidx.compose.ui.geometry.Offset(centerX, centerY + lineLength / 2),
                strokeWidth = 3f
            )
            
            // 中心圆圈
            drawCircle(
                color = Color.White,
                center = androidx.compose.ui.geometry.Offset(centerX, centerY),
                radius = 30.dp.toPx(),
                style = Stroke(width = 2.dp.toPx())
            )
        }
    }
} 