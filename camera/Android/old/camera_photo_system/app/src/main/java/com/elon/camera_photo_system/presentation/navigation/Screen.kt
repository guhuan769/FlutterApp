package com.elon.camera_photo_system.presentation.navigation

sealed class Screen(val route: String) {
    object Home : Screen("home")
    
    // 项目模块
    object ProjectList : Screen("project_list")
    object ProjectCamera : Screen("project_camera")
    object ProjectGallery : Screen("project_gallery")
    
    // 车辆模块
    object VehicleList : Screen("vehicle_list")
    object VehicleCamera : Screen("vehicle_camera")
    object VehicleGallery : Screen("vehicle_gallery")
    
    // 轨迹模块
    object TrackList : Screen("track_list")
    object TrackCamera : Screen("track_camera")
    object TrackGallery : Screen("track_gallery")
} 