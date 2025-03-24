package com.camera.photo.system.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

// 深色主题配色
private val DarkColorScheme = darkColorScheme(
    primary = LightBlue,
    secondary = AquaBlue,
    tertiary = MediumBlue,
    background = DarkBlue,
    surface = DeepBlue,
    onPrimary = Color.White,
    onSecondary = Color.White,
    onTertiary = Color.White,
    onBackground = Color.White,
    onSurface = Color.White,
    error = AccentRed
)

// 亮色主题配色
private val LightColorScheme = lightColorScheme(
    primary = Teal,
    secondary = LightTeal,
    tertiary = Navy,
    background = IvoryWhite,
    surface = Sand,
    onPrimary = Color.White,
    onSecondary = Color.White,
    onTertiary = Color.White,
    onBackground = DarkBlue,
    onSurface = Navy,
    error = AccentRed
)

/**
 * 应用主题
 * 支持动态颜色和沉浸式UI
 */
@Composable
fun CameraPhotoSystemTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    // 动态颜色在Android 12+上可用
    dynamicColor: Boolean = true,
    // 是否使用沉浸式UI（透明状态栏和导航栏）
    isImmersiveUi: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }
    
    // 获取当前窗口
    val view = LocalView.current
    if (!view.isInEditMode) {
        // 设置沉浸式UI
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = Color.Transparent.toArgb()
            
            // 启用边到边布局
            WindowCompat.setDecorFitsSystemWindows(window, false)
            
            // 设置状态栏和导航栏图标颜色
            val isLightTheme = !darkTheme
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = isLightTheme
            WindowCompat.getInsetsController(window, view).isAppearanceLightNavigationBars = isLightTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}