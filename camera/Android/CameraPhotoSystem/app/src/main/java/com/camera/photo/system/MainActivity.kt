package com.camera.photo.system

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity

/**
 * 此Activity仅用于重定向到实际的MainActivity
 * 解决包名不一致问题
 */
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 重定向到实际的MainActivity
        val intent = Intent(this, com.elon.camera_photo_system.MainActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(intent)
        finish()
    }
} 