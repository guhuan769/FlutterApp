package com.elon.camera_photo

import android.Manifest
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.provider.MediaScannerConnection
import android.util.Log
import android.widget.Button
import android.widget.ImageView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : AppCompatActivity() {
    private lateinit var imageView: ImageView
    private lateinit var btnTakePhoto: Button
    private lateinit var btnCustomCamera: Button
    
    private var customCameraPhotoUri: Uri? = null
    private var systemCameraPhotoUri: Uri? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        imageView = findViewById(R.id.imageView)
        btnTakePhoto = findViewById(R.id.btnTakePhoto)
        btnCustomCamera = findViewById(R.id.btnCustomCamera)
        
        // 检查是否有相机权限
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, 
                arrayOf(Manifest.permission.CAMERA, Manifest.permission.WRITE_EXTERNAL_STORAGE), 
                100)
        }
        
        // 系统相机按钮点击事件
        btnTakePhoto.setOnClickListener {
            val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
            startActivityForResult(intent, 1)
        }
        
        // 自定义相机按钮点击事件
        btnCustomCamera.setOnClickListener {
            val intent = Intent(this, CameraActivity::class.java)
            startActivity(intent)
        }
        
        // 检查是否有从相机返回的照片URI
        intent.getStringExtra("PHOTO_URI")?.let { uriString ->
            val uri = Uri.parse(uriString)
            imageView.setImageURI(uri)
        }
    }
    
    // 处理系统相机返回的结果
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 1 && resultCode == RESULT_OK) {
            Log.d("MainActivity", "系统相机返回结果")
            
            // 获取缩略图
            val imageBitmap = data?.extras?.get("data") as? Bitmap
            if (imageBitmap != null) {
                Log.d("MainActivity", "系统相机返回缩略图，尺寸: ${imageBitmap.width} x ${imageBitmap.height}")
                
                try {
                    // 保存到系统相册
                    val photoUri = saveImageToGallery(imageBitmap)
                    systemCameraPhotoUri = photoUri
                    
                    // 显示成功消息
                    Toast.makeText(this, "照片已保存到相册", Toast.LENGTH_SHORT).show()
                    
                    // 更新UI
                    val intent = Intent(this, MainActivity::class.java)
                    intent.putExtra("PHOTO_URI", photoUri.toString())
                    startActivity(intent)
                    finish()
                } catch (e: Exception) {
                    Log.e("MainActivity", "保存系统相机照片失败: ${e.message}", e)
                    Toast.makeText(this, "保存照片失败: ${e.message}", Toast.LENGTH_LONG).show()
                }
            } else {
                Toast.makeText(this, "系统相机返回的数据为空", Toast.LENGTH_SHORT).show()
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
    
    // 处理权限请求结果
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 100) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Toast.makeText(this, "相机权限已授予", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(this, "需要相机权限才能使用此功能", Toast.LENGTH_LONG).show()
            }
        }
    }
}