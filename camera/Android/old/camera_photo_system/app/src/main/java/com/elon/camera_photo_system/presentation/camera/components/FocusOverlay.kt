package com.elon.camera_photo_system.presentation.camera.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun FocusOverlay(
    onFocusRequest: (Offset) -> Unit,
    modifier: Modifier = Modifier
) {
    var focusPoint by remember { mutableStateOf<Offset?>(null) }
    val coroutineScope = rememberCoroutineScope()

    Canvas(
        modifier = modifier
            .fillMaxSize()
            .pointerInput(Unit) {
                detectTapGestures { offset ->
                    focusPoint = offset
                    onFocusRequest(offset)
                    coroutineScope.launch {
                        delay(1000) // 1秒后隐藏对焦框
                        focusPoint = null
                    }
                }
            }
    ) {
        focusPoint?.let { point ->
            val radius = 50f
            drawCircle(
                color = Color.White,
                center = point,
                radius = radius,
                style = Stroke(width = 2f)
            )
            drawCircle(
                color = Color.White,
                center = point,
                radius = radius / 2,
                style = Stroke(width = 1f)
            )
        }
    }
} 