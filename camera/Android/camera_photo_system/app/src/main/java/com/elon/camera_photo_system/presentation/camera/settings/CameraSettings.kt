package com.elon.camera_photo_system.presentation.camera.settings

import android.content.Context
import androidx.camera.core.ImageCapture
import androidx.camera.core.ResolutionSelector
import androidx.camera.core.resolutionselector.AspectRatioStrategy
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import android.util.Size

private val Context.dataStore by preferencesDataStore(name = "camera_settings")

class CameraSettings(private val context: Context) {
    companion object {
        private val DEFAULT_RESOLUTION = stringPreferencesKey("default_resolution")
        private val ENABLE_BLUETOOTH = booleanPreferencesKey("enable_bluetooth")
        private val ENABLE_AUTO_FOCUS = booleanPreferencesKey("enable_auto_focus")
        private val ENABLE_GRID_LINES = booleanPreferencesKey("enable_grid_lines")

        private val RESOLUTION_MAP = mapOf(
            "4K (3840x2160)" to Size(3840, 2160),
            "1080p (1920x1080)" to Size(1920, 1080),
            "720p (1280x720)" to Size(1280, 720)
        )
    }

    val defaultResolution: Flow<String> = context.dataStore.data
        .map { preferences ->
            preferences[DEFAULT_RESOLUTION] ?: "1080p (1920x1080)"
        }

    val enableBluetooth: Flow<Boolean> = context.dataStore.data
        .map { preferences ->
            preferences[ENABLE_BLUETOOTH] ?: true
        }

    val enableAutoFocus: Flow<Boolean> = context.dataStore.data
        .map { preferences ->
            preferences[ENABLE_AUTO_FOCUS] ?: true
        }

    val enableGridLines: Flow<Boolean> = context.dataStore.data
        .map { preferences ->
            preferences[ENABLE_GRID_LINES] ?: true
        }

    suspend fun setDefaultResolution(resolution: String) {
        context.dataStore.edit { preferences ->
            preferences[DEFAULT_RESOLUTION] = resolution
        }
    }

    suspend fun setEnableBluetooth(enable: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[ENABLE_BLUETOOTH] = enable
        }
    }

    suspend fun setEnableAutoFocus(enable: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[ENABLE_AUTO_FOCUS] = enable
        }
    }

    suspend fun setEnableGridLines(enable: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[ENABLE_GRID_LINES] = enable
        }
    }

    fun getResolutionSelector(resolution: String): ResolutionSelector {
        val targetSize = RESOLUTION_MAP[resolution] ?: RESOLUTION_MAP["1080p (1920x1080)"]!!
        return ResolutionSelector.Builder()
            .setResolutionStrategy(
                ResolutionStrategy(
                    targetSize,
                    ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER
                )
            )
            .setAspectRatioStrategy(
                AspectRatioStrategy(
                    targetSize.width.toFloat() / targetSize.height.toFloat(),
                    AspectRatioStrategy.FALLBACK_RULE_AUTO
                )
            )
            .build()
    }

    fun getImageCaptureBuilder(resolution: String): ImageCapture.Builder {
        return ImageCapture.Builder()
            .setResolutionSelector(getResolutionSelector(resolution))
            .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
    }
} 