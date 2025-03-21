package com.elon.camera_photo_system.presentation.camera.components

import androidx.compose.foundation.Canvas
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp

@Composable
fun CrosshairOverlay(
    modifier: Modifier = Modifier,
    color: Color = Color.White,
    strokeWidth: Float = 2f,
    lineLength: Float = 20f
) {
    Canvas(modifier = modifier) {
        val centerX = size.width / 2
        val centerY = size.height / 2

        // 绘制水平线
        drawLine(
            color = color,
            start = Offset(centerX - lineLength, centerY),
            end = Offset(centerX + lineLength, centerY),
            strokeWidth = strokeWidth
        )

        // 绘制垂直线
        drawLine(
            color = color,
            start = Offset(centerX, centerY - lineLength),
            end = Offset(centerX, centerY + lineLength),
            strokeWidth = strokeWidth
        )
    }
} 