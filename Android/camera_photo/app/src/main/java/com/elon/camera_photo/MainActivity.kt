package com.elon.camera_photo

import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.elon.camera_photo.ui.theme.Camera_photoTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            Camera_photoTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    CameraApp()
                }
            }
        }
    }
}

@Composable
fun CameraApp() {
    var currentScreen by remember { mutableStateOf<Screen>(Screen.Permission) }
    var photoUri by remember { mutableStateOf<Uri?>(null) }
    
    when (val screen = currentScreen) {
        is Screen.Permission -> {
            PermissionScreen(
                onPermissionsGranted = {
                    currentScreen = Screen.Camera
                }
            )
        }
        
        is Screen.Camera -> {
            CameraScreen(
                onPhotoTaken = { uri ->
                    photoUri = uri
                    currentScreen = Screen.Preview
                },
                onGalleryClick = {
                    currentScreen = Screen.Gallery
                }
            )
        }
        
        is Screen.Preview -> {
            photoUri?.let { uri ->
                PhotoPreviewScreen(
                    photoUri = uri,
                    onBackClick = {
                        currentScreen = Screen.Camera
                    }
                )
            }
        }
        
        is Screen.Gallery -> {
            GalleryScreen(
                onBackClick = {
                    currentScreen = Screen.Camera
                },
                onPhotoClick = { uri ->
                    photoUri = uri
                    currentScreen = Screen.Preview
                }
            )
        }
    }
}

sealed class Screen {
    object Permission : Screen()
    object Camera : Screen()
    object Preview : Screen()
    object Gallery : Screen()
}