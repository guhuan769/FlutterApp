package com.elon.camera_photo_system

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.core.content.ContextCompat
import androidx.navigation.compose.rememberNavController
import com.elon.camera_photo_system.presentation.camera.CameraViewModel
import com.elon.camera_photo_system.presentation.gallery.GalleryViewModel
import com.elon.camera_photo_system.presentation.navigation.NavGraph
import com.elon.camera_photo_system.presentation.project.ProjectViewModel
import com.elon.camera_photo_system.presentation.settings.SettingsViewModel
import com.elon.camera_photo_system.presentation.track.TrackViewModel
import com.elon.camera_photo_system.presentation.vehicle.VehicleViewModel
import com.elon.camera_photo_system.ui.theme.CameraPhotoSystemTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    
    private val cameraViewModel: CameraViewModel by viewModels()
    private val galleryViewModel: GalleryViewModel by viewModels()
    private val projectViewModel: ProjectViewModel by viewModels()
    private val vehicleViewModel: VehicleViewModel by viewModels()
    private val trackViewModel: TrackViewModel by viewModels()
    private val settingsViewModel: SettingsViewModel by viewModels()
    
    // 权限请求
    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val allGranted = permissions.entries.all { it.value }
        if (allGranted) {
            // 权限已授予，可以使用相机
            Toast.makeText(this, "相机权限已授予", Toast.LENGTH_SHORT).show()
        } else {
            // 权限被拒绝
            Toast.makeText(this, "需要相机和存储权限才能使用应用", Toast.LENGTH_LONG).show()
            finish()
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 检查权限
        checkAndRequestPermissions()
        
        enableEdgeToEdge()
        setContent {
            CameraPhotoSystemTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    val navController = rememberNavController()
                    
                    // 使用NavGraph来处理所有导航逻辑
                    NavGraph(
                        navController = navController,
                        projectViewModel = projectViewModel,
                        vehicleViewModel = vehicleViewModel,
                        trackViewModel = trackViewModel,
                        cameraViewModel = cameraViewModel,
                        galleryViewModel = galleryViewModel,
                        settingsViewModel = settingsViewModel,
                        onBackPressed = { finish() }
                    )
                }
            }
        }
    }
    
    /**
     * 检查并请求权限
     */
    private fun checkAndRequestPermissions() {
        val permissions = arrayOf(
            Manifest.permission.CAMERA,
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
                Manifest.permission.READ_MEDIA_IMAGES
            } else {
                Manifest.permission.READ_EXTERNAL_STORAGE
            }
        )
        
        val allGranted = permissions.all {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }
        
        if (!allGranted) {
            requestPermissionLauncher.launch(permissions)
        }
    }
} 