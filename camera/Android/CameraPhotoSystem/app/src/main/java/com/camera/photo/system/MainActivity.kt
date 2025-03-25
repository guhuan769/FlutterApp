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
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.camera.photo.system.domain.model.PhotoType
import com.camera.photo.system.presentation.ui.CameraScreen
import com.camera.photo.system.presentation.ui.HomeScreen
import com.camera.photo.system.presentation.ui.ProjectFormScreen
import com.camera.photo.system.presentation.ui.ProjectListScreen
import com.camera.photo.system.presentation.ui.TrackListScreen
import com.camera.photo.system.presentation.ui.VehicleListScreen
import com.camera.photo.system.ui.theme.CameraPhotoSystemTheme
import dagger.hilt.android.AndroidEntryPoint

// 导航路由
object NavRoutes {
    const val HOME = "home"
    const val CAMERA = "camera/{photoType}"
    const val GALLERY = "gallery?projectId={projectId}"
    const val SETTINGS = "settings"
    const val PROJECT_LIST = "projects"
    const val PROJECT_FORM = "projects/create"
    const val PROJECT_DETAIL = "projects/{projectId}"
    const val VEHICLE_LIST = "projects/{projectId}/vehicles"
    const val VEHICLE_FORM = "projects/{projectId}/vehicles/create"
    const val VEHICLE_DETAIL = "vehicles/{vehicleId}"
    const val TRACK_LIST = "vehicles/{vehicleId}/tracks"
    const val TRACK_FORM = "vehicles/{vehicleId}/tracks/create"
    const val TRACK_DETAIL = "tracks/{trackId}"
    const val UPLOAD = "upload?projectId={projectId}"
    
    // 带参数的导航
    fun cameraRoute(photoType: PhotoType) = "camera/$photoType"
    fun galleryRoute(projectId: String? = null) = projectId?.let { "gallery?projectId=$it" } ?: "gallery"
    fun projectDetailRoute(projectId: String) = "projects/$projectId"
    fun vehicleListRoute(projectId: String) = "projects/$projectId/vehicles"
    fun vehicleFormRoute(projectId: String) = "projects/$projectId/vehicles/create"
    fun vehicleDetailRoute(vehicleId: String) = "vehicles/$vehicleId"
    fun trackListRoute(vehicleId: String) = "vehicles/$vehicleId/tracks"
    fun trackFormRoute(vehicleId: String) = "vehicles/$vehicleId/tracks/create" 
    fun trackDetailRoute(trackId: String) = "tracks/$trackId"
    fun uploadRoute(projectId: String? = null) = projectId?.let { "upload?projectId=$it" } ?: "upload"
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
    startDestination: String = NavRoutes.PROJECT_LIST
) {
    NavHost(
        navController = navController,
        startDestination = startDestination,
        modifier = modifier
    ) {
        // 项目列表
        composable(NavRoutes.PROJECT_LIST) {
            ProjectListScreen(
                navigateToCreateProject = { navController.navigate(NavRoutes.PROJECT_FORM) },
                navigateToProjectDetail = { projectId -> navController.navigate(NavRoutes.projectDetailRoute(projectId)) },
                navigateToVehicleList = { projectId -> navController.navigate(NavRoutes.vehicleListRoute(projectId)) },
                navigateToCamera = { photoType -> navController.navigate(NavRoutes.cameraRoute(photoType)) },
                navigateToGallery = { projectId -> navController.navigate(NavRoutes.galleryRoute(projectId)) },
                navigateToUpload = { projectId -> navController.navigate(NavRoutes.uploadRoute(projectId)) },
                navigateToSettings = { navController.navigate(NavRoutes.SETTINGS) }
            )
        }
        
        // 创建项目表单
        composable(NavRoutes.PROJECT_FORM) {
            ProjectFormScreen(
                onNavigateBack = { navController.popBackStack() },
                onProjectCreated = { navController.popBackStack() }
            )
        }
        
        // 项目详情页面
        composable(
            route = NavRoutes.PROJECT_DETAIL,
            arguments = listOf(navArgument("projectId") { type = NavType.StringType })
        ) { backStackEntry ->
            val projectId = backStackEntry.arguments?.getString("projectId") ?: ""
            // TODO: 实现ProjectDetailScreen
            Surface(color = MaterialTheme.colorScheme.background) {
                // 暂时显示项目详情的临时UI
            }
        }
        
        // 车辆列表
        composable(
            route = NavRoutes.VEHICLE_LIST,
            arguments = listOf(navArgument("projectId") { type = NavType.StringType })
        ) { backStackEntry ->
            val projectId = backStackEntry.arguments?.getString("projectId") ?: ""
            VehicleListScreen(
                projectId = projectId,
                onNavigateBack = { navController.popBackStack() },
                navigateToCreateVehicle = { projectId -> navController.navigate(NavRoutes.vehicleFormRoute(projectId)) },
                navigateToVehicleDetail = { vehicleId -> navController.navigate(NavRoutes.vehicleDetailRoute(vehicleId)) },
                navigateToTrackList = { vehicleId -> navController.navigate(NavRoutes.trackListRoute(vehicleId)) }
            )
        }
        
        // 轨迹列表
        composable(
            route = NavRoutes.TRACK_LIST,
            arguments = listOf(navArgument("vehicleId") { type = NavType.StringType })
        ) { backStackEntry ->
            val vehicleId = backStackEntry.arguments?.getString("vehicleId") ?: ""
            TrackListScreen(
                vehicleId = vehicleId,
                onNavigateBack = { navController.popBackStack() },
                navigateToCreateTrack = { vehicleId -> navController.navigate(NavRoutes.trackFormRoute(vehicleId)) },
                navigateToTrackDetail = { trackId -> navController.navigate(NavRoutes.trackDetailRoute(trackId)) },
                navigateToCamera = { photoType -> navController.navigate(NavRoutes.cameraRoute(photoType)) }
            )
        }
        
        // 相机页面
        composable(
            route = NavRoutes.CAMERA,
            arguments = listOf(navArgument("photoType") { type = NavType.StringType })
        ) { backStackEntry ->
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
        
        // 首页 - 已替换为项目列表
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
        
        // 相册页面 - 需要实现
        composable(
            route = NavRoutes.GALLERY,
            arguments = listOf(navArgument("projectId") { 
                type = NavType.StringType 
                nullable = true
                defaultValue = null
            })
        ) {
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
        
        // 上传页面 - 需要实现
        composable(
            route = NavRoutes.UPLOAD,
            arguments = listOf(navArgument("projectId") { 
                type = NavType.StringType 
                nullable = true
                defaultValue = null
            })
        ) {
            // TODO: 实现UploadScreen
            Surface(color = MaterialTheme.colorScheme.background) {
                // 暂时返回首页的临时UI
            }
        }
    }
} 