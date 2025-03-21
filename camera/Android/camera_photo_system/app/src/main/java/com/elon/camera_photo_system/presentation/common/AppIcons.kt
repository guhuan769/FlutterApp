package com.elon.camera_photo_system.presentation.common

import androidx.compose.material.icons.Icons
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import androidx.compose.runtime.Composable
import com.elon.camera_photo_system.R

/**
 * 应用程序自定义图标管理类
 */
object AppIcons {
    /**
     * 获取相机图标
     */
    @Composable
    fun camera(): ImageVector = ImageVector.vectorResource(R.drawable.ic_camera)

    /**
     * 获取相册图标
     */
    @Composable
    fun photoLibrary(): ImageVector = ImageVector.vectorResource(R.drawable.ic_photo_library)

    /**
     * 获取时间轴图标
     */
    @Composable
    fun timeline(): ImageVector = ImageVector.vectorResource(R.drawable.ic_timeline)

    /**
     * 获取右箭头图标
     */
    @Composable
    fun chevronRight(): ImageVector = ImageVector.vectorResource(R.drawable.ic_chevron_right)

    /**
     * 获取前进箭头图标
     */
    @Composable
    fun arrowForward(): ImageVector = ImageVector.vectorResource(R.drawable.ic_arrow_forward)
} 