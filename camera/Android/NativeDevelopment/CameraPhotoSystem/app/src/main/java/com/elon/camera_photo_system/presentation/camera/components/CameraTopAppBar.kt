package com.elon.camera_photo_system.presentation.camera.components

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Collections
import androidx.compose.material3.*
import androidx.compose.runtime.Composable

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CameraTopAppBar(
    onNavigateBack: () -> Unit,
    onNavigateToGallery: () -> Unit
) {
    TopAppBar(
        title = { Text("拍照") },
        navigationIcon = {
            IconButton(onClick = onNavigateBack) {
                Icon(Icons.Default.ArrowBack, contentDescription = "返回")
            }
        },
        actions = {
            IconButton(onClick = onNavigateToGallery) {
                Icon(Icons.Default.Collections, contentDescription = "相册")
            }
        }
    )
} 