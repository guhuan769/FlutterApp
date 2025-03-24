package com.camera.photo.system

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.camera.photo.system.domain.model.PhotoType
import com.camera.photo.system.presentation.ui.CameraScreen
import com.camera.photo.system.presentation.ui.HomeScreen
import com.camera.photo.system.ui.theme.CameraPhotoSystemTheme
import dagger.hilt.android.AndroidEntryPoint

// 导航路由
object NavRoutes {
    const val HOME = "home"
    const val CAMERA = "camera/{photoType}"
    const val GALLERY = "gallery"
    const val SETTINGS = "settings"
    
    // 带参数的导航
    fun cameraRoute(photoType: PhotoType) = "camera/$photoType"
}

/**
 * 主Activity，使用Compose Navigation实现导航
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            CameraPhotoSystemTheme(isImmersiveUi = true) {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    CameraAppNavHost()
                }
            }
        }
    }
}

/**
 * 应用导航组件
 */
@Composable
fun CameraAppNavHost(
    modifier: Modifier = Modifier,
    navController: NavHostController = rememberNavController(),
    startDestination: String = NavRoutes.HOME
) {
    NavHost(
        navController = navController,
        startDestination = startDestination,
        modifier = modifier
    ) {
        // 首页
        composable(NavRoutes.HOME) {
            HomeScreen(
                navigateToCamera = { photoType ->
                    navController.navigate(NavRoutes.cameraRoute(photoType))
                },
                navigateToGallery = {
                    navController.navigate(NavRoutes.GALLERY)
                },
                navigateToSettings = {
                    navController.navigate(NavRoutes.SETTINGS)
                }
            )
        }
        
        // 相机页面
        composable(NavRoutes.CAMERA) { backStackEntry ->
            val photoTypeArg = backStackEntry.arguments?.getString("photoType") ?: PhotoType.PROJECT_MODEL.name
            val photoType = try {
                PhotoType.valueOf(photoTypeArg)
            } catch (e: IllegalArgumentException) {
                PhotoType.PROJECT_MODEL
            }
            
            CameraScreen(
                navigateToGallery = {
                    navController.navigate(NavRoutes.GALLERY) {
                        // 清除返回栈中的相机页面
                        popUpTo(NavRoutes.CAMERA) { inclusive = true }
                    }
                }
            )
        }
        
        // 相册页面 - 需要实现
        composable(NavRoutes.GALLERY) {
            // TODO: 实现GalleryScreen
            Surface(color = MaterialTheme.colorScheme.background) {
                // 暂时返回首页的临时UI
            }
        }
        
        // 设置页面 - 需要实现
        composable(NavRoutes.SETTINGS) {
            // TODO: 实现SettingsScreen
            Surface(color = MaterialTheme.colorScheme.background) {
                // 暂时返回首页的临时UI
            }
        }
    }
} 