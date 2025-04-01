package com.elon.camera_photo_system.data.repository

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
            preferences[apiUrlKey] ?: "http://10.0.2.2:5000/"
        }
    
    suspend fun saveApiUrl(url: String) {
        context.dataStore.edit { preferences ->
            preferences[apiUrlKey] = url
        }
    }
    
    suspend fun getApiUrl(): Flow<String> = apiUrl
} 