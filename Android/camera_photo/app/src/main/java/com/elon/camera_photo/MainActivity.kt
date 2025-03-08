package com.elon.camera_photo

import android.Manifest
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import coil.compose.rememberAsyncImagePainter
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : ComponentActivity() {
    private var customCameraPhotoUri: Uri? = null
    private var systemCameraPhotoUri: Uri? = null
    
    // 使用ActivityResultLauncher替代startActivityForResult
    private val takePictureLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        if (result.resultCode == RESULT_OK) {
            Log.d("MainActivity", "系统相机返回结果")
            
            // 获取缩略图
            val imageBitmap = result.data?.extras?.get("data") as? Bitmap
            if (imageBitmap != null) {
                Log.d("MainActivity", "系统相机返回缩略图，尺寸: ${imageBitmap.width} x ${imageBitmap.height}")
                
                try {
                    // 保存到系统相册
                    val photoUri = saveImageToGallery(imageBitmap)
                    systemCameraPhotoUri = photoUri
                    
                    // 显示成功消息
                    Toast.makeText(this, "照片已保存到相册", Toast.LENGTH_SHORT).show()
                    
                    // 更新UI
                    recreateWithPhotoUri(photoUri)
                } catch (e: Exception) {
                    Log.e("MainActivity", "保存系统相机照片失败: ${e.message}", e)
                    Toast.makeText(this, "保存照片失败: ${e.message}", Toast.LENGTH_LONG).show()
                }
            } else {
                Toast.makeText(this, "系统相机返回的数据为空", Toast.LENGTH_SHORT).show()
            }
        }
    }
    
    // 使用ActivityResultLauncher处理权限请求
    private val requestPermissionLauncher = registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { permissions ->
        val allGranted = permissions.entries.all { it.value }
        if (allGranted) {
            Toast.makeText(this, "所有权限已授予", Toast.LENGTH_SHORT).show()
        } else {
            Toast.makeText(this, "需要相机和存储权限才能使用此功能", Toast.LENGTH_LONG).show()
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 检查并请求权限
        checkAndRequestPermissions()
        
        // 检查是否有从相机返回的照片URI
        val photoUriString = intent.getStringExtra("PHOTO_URI")
        val photoUri = if (photoUriString != null) Uri.parse(photoUriString) else null
        
        setContent {
            MaterialTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    MainScreen(
                        photoUri = photoUri,
                        onTakePhotoClick = {
                            launchSystemCamera()
                        },
                        onCustomCameraClick = {
                            launchCustomCamera()
                        }
                    )
                }
            }
        }
    }
    
    private fun checkAndRequestPermissions() {
        val permissionsToRequest = mutableListOf<String>()
        
        // 检查相机权限
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            permissionsToRequest.add(Manifest.permission.CAMERA)
        }
        
        // 根据Android版本检查存储权限
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
            // Android 9 (API 28)及以下需要WRITE_EXTERNAL_STORAGE权限
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Android 13 (API 33)及以上需要READ_MEDIA_IMAGES权限
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_MEDIA_IMAGES) != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.READ_MEDIA_IMAGES)
            }
        }
        
        // 请求所需权限
        if (permissionsToRequest.isNotEmpty()) {
            requestPermissionLauncher.launch(permissionsToRequest.toTypedArray())
        }
    }
    
    private fun launchSystemCamera() {
        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        takePictureLauncher.launch(intent)
    }
    
    private fun launchCustomCamera() {
        val intent = Intent(this, CameraActivity::class.java)
        startActivity(intent)
    }
    
    private fun recreateWithPhotoUri(photoUri: Uri) {
        val intent = Intent(this, MainActivity::class.java)
        intent.putExtra("PHOTO_URI", photoUri.toString())
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        startActivity(intent)
        finish()
    }
    
    @Composable
    fun MainScreen(
        photoUri: Uri?,
        onTakePhotoClick: () -> Unit,
        onCustomCameraClick: () -> Unit
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // 显示照片
            if (photoUri != null) {
                Image(
                    painter = rememberAsyncImagePainter(photoUri),
                    contentDescription = "Photo",
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                )
            } else {
                Spacer(modifier = Modifier.weight(1f))
            }
            
            // 按钮
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 16.dp)
            ) {
                Button(
                    onClick = onTakePhotoClick,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("拍照")
                }
                
                Spacer(modifier = Modifier.width(16.dp))
                
                Button(
                    onClick = onCustomCameraClick,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("自定义相机")
                }
            }
        }
    }
    
    // 保存图片到系统相册
    private fun saveImageToGallery(bitmap: Bitmap): Uri {
        val filename = "IMG_${System.currentTimeMillis()}.jpg"
        var uri: Uri? = null
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10及以上使用MediaStore
                val contentValues = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, filename)
                    put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
                    put(MediaStore.MediaColumns.RELATIVE_PATH, "Pictures/CameraPhoto")
                }
                
                contentResolver.also { resolver ->
                    uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
                    uri?.let { imageUri ->
                        resolver.openOutputStream(imageUri)?.use { outputStream ->
                            bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream)
                        }
                    }
                }
            } else {
                // Android 9及以下使用文件系统
                val imagesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES).toString() + File.separator + "CameraPhoto"
                val dir = File(imagesDir)
                if (!dir.exists()) dir.mkdirs()
                
                val file = File(imagesDir, filename)
                FileOutputStream(file).use { outputStream ->
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream)
                }
                
                // 通知系统图库更新
                MediaScannerConnection.scanFile(
                    this,
                    arrayOf(file.absolutePath),
                    arrayOf("image/jpeg"),
                    null
                )
                
                uri = Uri.fromFile(file)
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "保存图片到相册失败: ${e.message}", e)
            throw e
        }
        
        return uri ?: throw IllegalStateException("无法创建图片URI")
    }
}