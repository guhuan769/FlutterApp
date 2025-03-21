package com.elon.camera_photo_system.presentation.camera.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.selection.selectable
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.elon.camera_photo_system.R

@Composable
fun CameraControls(
    onCaptureClick: () -> Unit,
    onResolutionClick: () -> Unit,
    onBluetoothClick: () -> Unit,
    isBluetoothConnected: Boolean,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .background(Color.Black.copy(alpha = 0.6f))
            .padding(16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // 分辨率设置按钮
            IconButton(
                onClick = onResolutionClick,
                modifier = Modifier.size(48.dp)
            ) {
                Icon(
                    painter = painterResource(R.drawable.ic_resolution),
                    contentDescription = "分辨率设置",
                    tint = Color.White
                )
            }

            // 拍照按钮
            FloatingActionButton(
                onClick = onCaptureClick,
                modifier = Modifier.size(72.dp),
                containerColor = MaterialTheme.colorScheme.primary
            ) {
                Icon(
                    painter = painterResource(R.drawable.ic_camera_shutter),
                    contentDescription = "拍照",
                    modifier = Modifier.size(36.dp)
                )
            }

            // 蓝牙自拍杆连接按钮
            IconButton(
                onClick = onBluetoothClick,
                modifier = Modifier.size(48.dp)
            ) {
                Icon(
                    painter = painterResource(
                        if (isBluetoothConnected) R.drawable.ic_bluetooth_connected
                        else R.drawable.ic_bluetooth_disconnected
                    ),
                    contentDescription = if (isBluetoothConnected) "蓝牙已连接" else "蓝牙未连接",
                    tint = if (isBluetoothConnected) Color.Green else Color.White
                )
            }
        }
    }
}

@Composable
fun ResolutionDialog(
    onDismiss: () -> Unit,
    onResolutionSelected: (String) -> Unit,
    currentResolution: String
) {
    val resolutions = listOf("4K (3840x2160)", "1080p (1920x1080)", "720p (1280x720)")

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("选择分辨率") },
        text = {
            Column {
                resolutions.forEach { resolution ->
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .selectable(
                                selected = resolution == currentResolution,
                                onClick = { 
                                    onResolutionSelected(resolution)
                                    onDismiss()
                                }
                            )
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                    ) {
                        RadioButton(
                            selected = resolution == currentResolution,
                            onClick = null
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(resolution)
                    }
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("取消")
            }
        }
    )
} 