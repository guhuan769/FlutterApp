package com.elon.camera_photo_system.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import com.elon.camera_photo_system.presentation.home.HomeScreen

@Composable
fun AppNavigation(
    navController: NavHostController,
    startDestination: String = Screen.Home.route
) {
    NavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        // 主页
        composable(Screen.Home.route) {
            HomeScreen(navController)
        }

        // 项目模块
        composable(Screen.ProjectList.route) {
            // TODO: 实现项目列表页面
        }
        composable(Screen.ProjectCamera.route) {
            // TODO: 实现项目相机页面
        }
        composable(Screen.ProjectGallery.route) {
            // TODO: 实现项目相册页面
        }

        // 车辆模块
        composable(Screen.VehicleList.route) {
            // TODO: 实现车辆列表页面
        }
        composable(Screen.VehicleCamera.route) {
            // TODO: 实现车辆相机页面
        }
        composable(Screen.VehicleGallery.route) {
            // TODO: 实现车辆相册页面
        }

        // 轨迹模块
        composable(Screen.TrackList.route) {
            // TODO: 实现轨迹列表页面
        }
        composable(Screen.TrackCamera.route) {
            // TODO: 实现轨迹相机页面
        }
        composable(Screen.TrackGallery.route) {
            // TODO: 实现轨迹相册页面
        }
    }
} 