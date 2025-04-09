package com.elon.camera_photo_system.presentation.navigation

import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.core.tween
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.PhotoType
import com.elon.camera_photo_system.presentation.camera.CameraScreen
import com.elon.camera_photo_system.presentation.camera.CameraViewModel
import com.elon.camera_photo_system.presentation.gallery.GalleryScreen
import com.elon.camera_photo_system.presentation.gallery.GalleryViewModel
import com.elon.camera_photo_system.presentation.home.AddProjectDialog
import com.elon.camera_photo_system.presentation.home.HomeScreen
import com.elon.camera_photo_system.presentation.home.HomeScreenState
import com.elon.camera_photo_system.presentation.project.ProjectDetailScreen
import com.elon.camera_photo_system.presentation.project.ProjectViewModel
import com.elon.camera_photo_system.presentation.settings.SettingsScreen
import com.elon.camera_photo_system.presentation.settings.SettingsViewModel
import com.elon.camera_photo_system.presentation.track.AddTrackField
import com.elon.camera_photo_system.presentation.track.TrackDetailScreen
import com.elon.camera_photo_system.presentation.track.TrackListScreen
import com.elon.camera_photo_system.presentation.track.TrackViewModel
import com.elon.camera_photo_system.presentation.vehicle.VehicleDetailScreen
import com.elon.camera_photo_system.presentation.vehicle.VehicleListScreen
import com.elon.camera_photo_system.presentation.vehicle.VehicleViewModel

/**
 * 导航路由
 */
sealed class NavRoute(val route: String) {
    // 首页
    object Home : NavRoute("home")
    
    // 项目
    object ProjectDetail : NavRoute("project/{projectId}") {
        fun createRoute(projectId: Long): String = "project/$projectId"
    }
    
    // 车辆
    object VehicleList : NavRoute("project/{projectId}/vehicles") {
        fun createRoute(projectId: Long): String = "project/$projectId/vehicles"
    }
    
    object VehicleDetail : NavRoute("project/{projectId}/vehicle/{vehicleId}") {
        fun createRoute(projectId: Long, vehicleId: Long): String = "project/$projectId/vehicle/$vehicleId"
    }
    
    // 轨迹
    object TrackList : NavRoute("project/{projectId}/vehicle/{vehicleId}/tracks") {
        fun createRoute(projectId: Long, vehicleId: Long): String = "project/$projectId/vehicle/$vehicleId/tracks"
    }
    
    object TrackDetail : NavRoute("project/{projectId}/vehicle/{vehicleId}/track/{trackId}") {
        fun createRoute(projectId: Long, vehicleId: Long, trackId: Long): String = 
            "project/$projectId/vehicle/$vehicleId/track/$trackId"
    }
    
    // 拍照
    object ProjectCamera : NavRoute("camera/project/{projectId}") {
        fun createRoute(projectId: Long): String = "camera/project/$projectId"
    }
    
    object VehicleCamera : NavRoute("camera/project/{projectId}/vehicle/{vehicleId}") {
        fun createRoute(projectId: Long, vehicleId: Long): String = "camera/project/$projectId/vehicle/$vehicleId"
    }
    
    object TrackCamera : NavRoute("camera/project/{projectId}/vehicle/{vehicleId}/track/{trackId}") {
        fun createRoute(projectId: Long, vehicleId: Long, trackId: Long): String = 
            "camera/project/$projectId/vehicle/$vehicleId/track/$trackId"
    }
    
    // 相册
    object ProjectGallery : NavRoute("gallery/project/{projectId}") {
        fun createRoute(projectId: Long): String = "gallery/project/$projectId"
    }
    
    object VehicleGallery : NavRoute("gallery/project/{projectId}/vehicle/{vehicleId}") {
        fun createRoute(projectId: Long, vehicleId: Long): String = "gallery/project/$projectId/vehicle/$vehicleId"
    }
    
    object TrackGallery : NavRoute("gallery/project/{projectId}/vehicle/{vehicleId}/track/{trackId}") {
        fun createRoute(projectId: Long, vehicleId: Long, trackId: Long): String = 
            "gallery/project/$projectId/vehicle/$vehicleId/track/$trackId"
    }
    
    // 设置
    object Settings : NavRoute("settings")
}

/**
 * 导航图
 */
@Composable
fun NavGraph(
    navController: NavHostController,
    projectViewModel: ProjectViewModel,
    vehicleViewModel: VehicleViewModel,
    trackViewModel: TrackViewModel,
    cameraViewModel: CameraViewModel,
    galleryViewModel: GalleryViewModel,
    settingsViewModel: SettingsViewModel,
    onBackPressed: () -> Unit
) {
    // 动画持续时间
    val animDuration = 300
    
    NavHost(
        navController = navController,
        startDestination = NavRoute.Home.route,
        enterTransition = {
            slideIntoContainer(
                towards = AnimatedContentTransitionScope.SlideDirection.Left,
                animationSpec = tween(animDuration)
            )
        },
        exitTransition = {
            slideOutOfContainer(
                towards = AnimatedContentTransitionScope.SlideDirection.Left,
                animationSpec = tween(animDuration)
            )
        },
        popEnterTransition = {
            slideIntoContainer(
                towards = AnimatedContentTransitionScope.SlideDirection.Right,
                animationSpec = tween(animDuration)
            )
        },
        popExitTransition = {
            slideOutOfContainer(
                towards = AnimatedContentTransitionScope.SlideDirection.Right,
                animationSpec = tween(animDuration)
            )
        }
    ) {
        // 首页
        composable(NavRoute.Home.route) {
            val projectsState by projectViewModel.projectsState.collectAsState()
            val uploadState by projectViewModel.uploadState.collectAsState()
            var showAddProjectDialog by remember { mutableStateOf(false) }
            
            HomeScreen(
                state = HomeScreenState(
                    projects = projectsState.projects,
                    isLoading = projectsState.isLoading,
                    error = projectsState.error
                ),
                uploadState = uploadState,
                onProjectClick = { project ->
                    navController.navigate(NavRoute.ProjectDetail.createRoute(project.id))
                },
                onRefresh = {
                    projectViewModel.loadProjects()
                },
                onAddProject = {
                    // 显示创建项目对话框
                    showAddProjectDialog = true
                },
                onTakeModelPhoto = { project ->
                    // 跳转到项目模型拍照页面
                    navController.navigate(NavRoute.ProjectCamera.createRoute(project.id))
                },
                onOpenGallery = { project ->
                    // 跳转到项目相册页面
                    galleryViewModel.loadModulePhotos(project.id, ModuleType.PROJECT)
                    navController.navigate(NavRoute.ProjectGallery.createRoute(project.id))
                },
                onAddVehicle = { project ->
                    // 跳转到添加车辆页面
                    navController.navigate(NavRoute.VehicleList.createRoute(project.id))
                },
                onUploadProject = { project ->
                    // 上传项目功能
                    projectViewModel.uploadProjectPhotos(project)
                },
                onNavigateToSettings = {
                    // 跳转到设置界面
                    navController.navigate(NavRoute.Settings.route)
                }
            )
            
            // 添加项目对话框
            if (showAddProjectDialog) {
                AddProjectDialog(
                    onDismiss = { showAddProjectDialog = false },
                    onConfirm = { name, description ->
                        projectViewModel.createProject(name, description)
                        showAddProjectDialog = false
                    }
                )
            }
        }
        
        // 项目详情
        composable(
            route = NavRoute.ProjectDetail.route,
            arguments = listOf(
                navArgument("projectId") { type = NavType.LongType }
            )
        ) { backStackEntry ->
            val projectId = backStackEntry.arguments?.getLong("projectId") ?: 0L
            val projectState by projectViewModel.projectState.collectAsState()
            
            // 加载项目详情
            projectViewModel.loadProject(projectId)
            
            ProjectDetailScreen(
                project = projectState.project,
                isLoading = projectState.isLoading,
                error = projectState.error,
                onNavigateBack = { navController.popBackStack() },
                onNavigateToVehicles = {
                    navController.navigate(NavRoute.VehicleList.createRoute(projectId))
                },
                onNavigateToCamera = {
                    navController.navigate(NavRoute.ProjectCamera.createRoute(projectId))
                },
                onNavigateToGallery = {
                    galleryViewModel.loadModulePhotos(projectId, ModuleType.PROJECT)
                    navController.navigate(NavRoute.ProjectGallery.createRoute(projectId))
                }
            )
        }
        
        // 车辆列表
        composable(
            route = NavRoute.VehicleList.route,
            arguments = listOf(
                navArgument("projectId") { type = NavType.LongType }
            )
        ) { backStackEntry ->
            val projectId = backStackEntry.arguments?.getLong("projectId") ?: 0L
            val vehiclesState by vehicleViewModel.vehiclesState.collectAsState()
            val addVehicleState by vehicleViewModel.addVehicleState.collectAsState()
            
            // 加载该项目下的车辆
            vehicleViewModel.loadVehiclesByProject(projectId)
            
            VehicleListScreen(
                projectId = projectId,
                vehicles = vehiclesState.vehicles,
                isLoading = vehiclesState.isLoading,
                error = vehiclesState.error,
                onNavigateBack = { navController.popBackStack() },
                onVehicleClick = { vehicle ->
                    navController.navigate(NavRoute.VehicleDetail.createRoute(projectId, vehicle.id))
                },
                onRefresh = {
                    vehicleViewModel.loadVehiclesByProject(projectId)
                },
                addVehicleState = addVehicleState,
                onAddVehicleClick = {
                    vehicleViewModel.resetAddVehicleState()
                },
                onAddVehicleDismiss = {
                    vehicleViewModel.resetAddVehicleState()
                },
                onAddVehicleFieldChanged = { field, value ->
                    vehicleViewModel.updateAddVehicleField(field, value)
                },
                onAddVehicleSubmit = {
                    vehicleViewModel.addVehicle(projectId)
                }
            )
        }
        
        // 车辆详情
        composable(
            route = NavRoute.VehicleDetail.route,
            arguments = listOf(
                navArgument("projectId") { type = NavType.LongType },
                navArgument("vehicleId") { type = NavType.LongType }
            )
        ) { backStackEntry ->
            val projectId = backStackEntry.arguments?.getLong("projectId") ?: 0L
            val vehicleId = backStackEntry.arguments?.getLong("vehicleId") ?: 0L
            val vehicleState by vehicleViewModel.vehicleState.collectAsState()
            
            // 加载车辆详情
            vehicleViewModel.loadVehicle(vehicleId)
            
            VehicleDetailScreen(
                projectId = projectId,
                vehicle = vehicleState.vehicle,
                isLoading = vehicleState.isLoading,
                error = vehicleState.error,
                onNavigateBack = { navController.popBackStack() },
                onNavigateToTracks = {
                    navController.navigate(NavRoute.TrackList.createRoute(projectId, vehicleId))
                },
                onNavigateToCamera = {
                    navController.navigate(NavRoute.VehicleCamera.createRoute(projectId, vehicleId))
                },
                onNavigateToGallery = {
                    galleryViewModel.loadModulePhotos(vehicleId, ModuleType.VEHICLE)
                    navController.navigate(NavRoute.VehicleGallery.createRoute(projectId, vehicleId))
                }
            )
        }
        
        // 轨迹列表
        composable(
            route = NavRoute.TrackList.route,
            arguments = listOf(
                navArgument("projectId") { type = NavType.LongType },
                navArgument("vehicleId") { type = NavType.LongType }
            )
        ) { backStackEntry ->
            val projectId = backStackEntry.arguments?.getLong("projectId") ?: 0L
            val vehicleId = backStackEntry.arguments?.getLong("vehicleId") ?: 0L
            val tracksState by trackViewModel.tracksState.collectAsState()
            val addTrackState by trackViewModel.addTrackState.collectAsState()
            
            // 加载该车辆下的轨迹
            trackViewModel.loadTracksByVehicle(vehicleId)
            
            TrackListScreen(
                projectId = projectId,
                vehicleId = vehicleId,
                tracks = tracksState.tracks,
                isLoading = tracksState.isLoading,
                error = tracksState.error,
                onNavigateBack = { navController.popBackStack() },
                onTrackClick = { track ->
                    navController.navigate(NavRoute.TrackDetail.createRoute(projectId, vehicleId, track.id))
                },
                onRefresh = {
                    trackViewModel.loadTracksByVehicle(vehicleId)
                },
                addTrackState = addTrackState,
                onAddTrackClick = {
                    trackViewModel.resetAddTrackState()
                },
                onAddTrackNameChanged = { name ->
                    trackViewModel.updateAddTrackField(AddTrackField.NAME, name)
                },
                onAddTrackSubmit = {
                    trackViewModel.createTrack(addTrackState.name, vehicleId)
                },
                onAddTrackDismiss = {
                    trackViewModel.resetAddTrackState()
                }
            )
        }
        
        // 轨迹详情
        composable(
            route = NavRoute.TrackDetail.route,
            arguments = listOf(
                navArgument("projectId") { type = NavType.LongType },
                navArgument("vehicleId") { type = NavType.LongType },
                navArgument("trackId") { type = NavType.LongType }
            )
        ) { backStackEntry ->
            val projectId = backStackEntry.arguments?.getLong("projectId") ?: 0L
            val vehicleId = backStackEntry.arguments?.getLong("vehicleId") ?: 0L
            val trackId = backStackEntry.arguments?.getLong("trackId") ?: 0L
            val trackState by trackViewModel.trackState.collectAsState()
            
            // 加载轨迹详情
            trackViewModel.loadTrack(trackId)
            
            TrackDetailScreen(
                projectId = projectId,
                vehicleId = vehicleId,
                track = trackState.track,
                isLoading = trackState.isLoading,
                error = trackState.error,
                onNavigateBack = { navController.popBackStack() },
                onNavigateToCamera = { photoType ->
                    // 跳转到拍照界面，并传递照片类型
                    navController.navigate(NavRoute.TrackCamera.createRoute(projectId, vehicleId, trackId))
                },
                onNavigateToGallery = {
                    galleryViewModel.loadModulePhotos(trackId, ModuleType.TRACK)
                    navController.navigate(NavRoute.TrackGallery.createRoute(projectId, vehicleId, trackId))
                },
                onStartTrack = {
                    // 开始轨迹记录
                    trackViewModel.startTrack(trackId)
                },
                onEndTrack = {
                    // 结束轨迹记录
                    trackViewModel.endTrack(trackId)
                }
            )
        }
        
        // 项目拍照
        composable(
            route = NavRoute.ProjectCamera.route,
            arguments = listOf(
                navArgument("projectId") { type = NavType.LongType }
            )
        ) { backStackEntry ->
            val projectId = backStackEntry.arguments?.getLong("projectId") ?: 0L
            
            CameraScreen(
                moduleType = ModuleType.PROJECT,
                moduleId = projectId,
                onNavigateBack = { navController.popBackStack() },
                onNavigateToGallery = {
                    galleryViewModel.loadModulePhotos(projectId, ModuleType.PROJECT)
                    navController.navigate(NavRoute.ProjectGallery.createRoute(projectId))
                },
                onPhotoTaken = { filePath, fileName, photoType ->
                    cameraViewModel.savePhoto(
                        moduleId = projectId,
                        moduleType = ModuleType.PROJECT,
                        photoType = photoType,
                        filePath = filePath,
                        fileName = fileName
                    )
                },
                viewModel = cameraViewModel
            )
        }
        
        // 车辆拍照
        composable(
            route = NavRoute.VehicleCamera.route,
            arguments = listOf(
                navArgument("projectId") { type = NavType.LongType },
                navArgument("vehicleId") { type = NavType.LongType }
            )
        ) { backStackEntry ->
            val projectId = backStackEntry.arguments?.getLong("projectId") ?: 0L
            val vehicleId = backStackEntry.arguments?.getLong("vehicleId") ?: 0L
            
            CameraScreen(
                moduleType = ModuleType.VEHICLE,
                moduleId = vehicleId,
                onNavigateBack = { navController.popBackStack() },
                onNavigateToGallery = {
                    galleryViewModel.loadModulePhotos(vehicleId, ModuleType.VEHICLE)
                    navController.navigate(NavRoute.VehicleGallery.createRoute(projectId, vehicleId))
                },
                onPhotoTaken = { filePath, fileName, photoType ->
                    cameraViewModel.savePhoto(
                        moduleId = vehicleId,
                        moduleType = ModuleType.VEHICLE,
                        photoType = photoType,
                        filePath = filePath,
                        fileName = fileName
                    )
                },
                viewModel = cameraViewModel
            )
        }
        
        // 轨迹拍照
        composable(
            route = NavRoute.TrackCamera.route,
            arguments = listOf(
                navArgument("projectId") { type = NavType.LongType },
                navArgument("vehicleId") { type = NavType.LongType },
                navArgument("trackId") { type = NavType.LongType }
            )
        ) { backStackEntry ->
            val projectId = backStackEntry.arguments?.getLong("projectId") ?: 0L
            val vehicleId = backStackEntry.arguments?.getLong("vehicleId") ?: 0L
            val trackId = backStackEntry.arguments?.getLong("trackId") ?: 0L
            
            CameraScreen(
                moduleType = ModuleType.TRACK,
                moduleId = trackId,
                onNavigateBack = { navController.popBackStack() },
                onNavigateToGallery = {
                    galleryViewModel.loadModulePhotos(trackId, ModuleType.TRACK)
                    navController.navigate(NavRoute.TrackGallery.createRoute(projectId, vehicleId, trackId))
                },
                onPhotoTaken = { filePath, fileName, photoType ->
                    cameraViewModel.savePhoto(
                        moduleId = trackId,
                        moduleType = ModuleType.TRACK,
                        photoType = photoType,
                        filePath = filePath,
                        fileName = fileName
                    )
                },
                viewModel = cameraViewModel
            )
        }
        
        // 项目相册
        composable(
            route = NavRoute.ProjectGallery.route,
            arguments = listOf(
                navArgument("projectId") { type = NavType.LongType }
            )
        ) { backStackEntry ->
            val projectId = backStackEntry.arguments?.getLong("projectId") ?: 0L
            val galleryUiState by galleryViewModel.galleryUIState.collectAsState()
            
            GalleryScreen(
                photos = galleryUiState.photos,
                moduleType = ModuleType.PROJECT,
                onNavigateBack = { navController.popBackStack() },
                onPhotoClick = { /* 预览照片 */ },
                onDeletePhoto = { photo -> galleryViewModel.deletePhoto(photo) },
                isLoading = galleryUiState.isLoading,
                error = galleryUiState.error,
                onRefresh = { galleryViewModel.loadModulePhotos(projectId, ModuleType.PROJECT) }
            )
        }
        
        // 车辆相册
        composable(
            route = NavRoute.VehicleGallery.route,
            arguments = listOf(
                navArgument("projectId") { type = NavType.LongType },
                navArgument("vehicleId") { type = NavType.LongType }
            )
        ) { backStackEntry ->
            val projectId = backStackEntry.arguments?.getLong("projectId") ?: 0L
            val vehicleId = backStackEntry.arguments?.getLong("vehicleId") ?: 0L
            val galleryUiState by galleryViewModel.galleryUIState.collectAsState()
            
            GalleryScreen(
                photos = galleryUiState.photos,
                moduleType = ModuleType.VEHICLE,
                onNavigateBack = { navController.popBackStack() },
                onPhotoClick = { /* 预览照片 */ },
                onDeletePhoto = { photo -> galleryViewModel.deletePhoto(photo) },
                isLoading = galleryUiState.isLoading,
                error = galleryUiState.error,
                onRefresh = { galleryViewModel.loadModulePhotos(vehicleId, ModuleType.VEHICLE) }
            )
        }
        
        // 轨迹相册
        composable(
            route = NavRoute.TrackGallery.route,
            arguments = listOf(
                navArgument("projectId") { type = NavType.LongType },
                navArgument("vehicleId") { type = NavType.LongType },
                navArgument("trackId") { type = NavType.LongType }
            )
        ) { backStackEntry ->
            val projectId = backStackEntry.arguments?.getLong("projectId") ?: 0L
            val vehicleId = backStackEntry.arguments?.getLong("vehicleId") ?: 0L
            val trackId = backStackEntry.arguments?.getLong("trackId") ?: 0L
            val galleryUiState by galleryViewModel.galleryUIState.collectAsState()
            
            GalleryScreen(
                photos = galleryUiState.photos,
                moduleType = ModuleType.TRACK,
                onNavigateBack = { navController.popBackStack() },
                onPhotoClick = { /* 预览照片 */ },
                onDeletePhoto = { photo -> galleryViewModel.deletePhoto(photo) },
                isLoading = galleryUiState.isLoading,
                error = galleryUiState.error,
                onRefresh = { galleryViewModel.loadModulePhotos(trackId, ModuleType.TRACK) }
            )
        }
        
        // 设置界面
        composable(NavRoute.Settings.route) {
            SettingsScreen(
                viewModel = settingsViewModel,
                onNavigateBack = { navController.popBackStack() }
            )
        }
    }
} 