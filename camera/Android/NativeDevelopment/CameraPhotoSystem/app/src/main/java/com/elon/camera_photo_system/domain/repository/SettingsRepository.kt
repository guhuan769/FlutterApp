package com.elon.camera_photo_system.domain.repository

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "settings")

@Singleton
class SettingsRepository @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val apiUrlKey = stringPreferencesKey("api_url")
    
    val apiUrl: Flow<String> = context.dataStore.data
        .map { preferences ->
            preferences[apiUrlKey] ?: "http://192.168.101.21:5000/" // 默认使用真机地址
        }
    
    suspend fun saveApiUrl(url: String) {
        context.dataStore.edit { preferences ->
            preferences[apiUrlKey] = url
        }
    }
    
    suspend fun getApiUrl(): Flow<String> = apiUrl
    
    /**
     * 同步获取API基础URL，主要用于初始化
     * 注意：这应该只在构造函数等非挂起函数中使用，其他地方应优先使用Flow版本
     */
    fun getApiBaseUrl(): String {
        return "http://192.168.101.21:5000/" // 默认使用真机地址
    }

    // 尝试读取并添加需要的方法
} 