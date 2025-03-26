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
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.core.content.ContextCompat
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.presentation.camera.CameraScreen
import com.elon.camera_photo_system.presentation.camera.CameraViewModel
import com.elon.camera_photo_system.presentation.gallery.GalleryScreen
import com.elon.camera_photo_system.presentation.gallery.GalleryViewModel
import com.elon.camera_photo_system.ui.theme.CameraPhotoSystemTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    
    private val cameraViewModel: CameraViewModel by viewModels()
    private val galleryViewModel: GalleryViewModel by viewModels()
    
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
                    
                    // 示例：项目模块ID
                    val moduleId = 1L
                    val moduleType = ModuleType.PROJECT
                    
                    // 获取相机状态
                    val cameraUiState by cameraViewModel.cameraUIState.collectAsState()
                    val galleryUiState by galleryViewModel.galleryUIState.collectAsState()
                    
                    NavHost(navController = navController, startDestination = "camera") {
                        // 相机界面
                        composable("camera") {
                            CameraScreen(
                                moduleType = moduleType,
                                moduleId = moduleId,
                                onNavigateBack = { finish() },
                                onNavigateToGallery = {
                                    // 加载该模块的照片
                                    galleryViewModel.loadModulePhotos(moduleId, moduleType)
                                    navController.navigate("gallery")
                                },
                                onPhotoTaken = { filePath, fileName, photoType ->
                                    // 保存照片到数据库
                                    cameraViewModel.savePhoto(
                                        moduleId = moduleId,
                                        moduleType = moduleType,
                                        photoType = photoType,
                                        filePath = filePath,
                                        fileName = fileName
                                    )
                                    
                                    // 显示提示
                                    Toast.makeText(
                                        this@MainActivity, 
                                        "照片已保存", 
                                        Toast.LENGTH_SHORT
                                    ).show()
                                }
                            )
                        }
                        
                        // 相册界面
                        composable("gallery") {
                            GalleryScreen(
                                photos = galleryUiState.photos,
                                moduleType = moduleType,
                                onNavigateBack = { navController.popBackStack() },
                                onPhotoClick = { photo ->
                                    // 点击查看照片详情（可以扩展）
                                },
                                onDeletePhoto = { photo ->
                                    galleryViewModel.deletePhoto(photo)
                                }
                            )
                        }
                    }
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