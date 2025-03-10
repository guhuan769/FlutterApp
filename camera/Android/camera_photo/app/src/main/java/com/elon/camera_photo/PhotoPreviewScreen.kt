package com.elon.camera_photo

import android.graphics.BitmapFactory
import android.net.Uri
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

@Composable
fun PhotoPreviewScreen(
    photoUri: Uri,
    onBackClick: () -> Unit
) {
    val context = LocalContext.current
    var width by remember { mutableStateOf(0) }
    var height by remember { mutableStateOf(0) }
    var bitmap by remember { mutableStateOf<android.graphics.Bitmap?>(null) }
    
    // 在协程中加载图片
    LaunchedEffect(photoUri) {
        withContext(Dispatchers.IO) {
            context.contentResolver.openInputStream(photoUri)?.use { inputStream ->
                // 获取图片的原始尺寸
                val options = BitmapFactory.Options().apply {
                    inJustDecodeBounds = true
                }
                BitmapFactory.decodeStream(inputStream, null, options)
                width = options.outWidth
                height = options.outHeight
            }
            
            // 加载实际图片用于显示
            context.contentResolver.openInputStream(photoUri)?.use { inputStream ->
                val loadedBitmap = BitmapFactory.decodeStream(inputStream)
                bitmap = loadedBitmap
            }
        }
    }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = stringResource(R.string.photo_preview),
            style = MaterialTheme.typography.headlineMedium
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        bitmap?.let { bmp ->
            Image(
                bitmap = bmp.asImageBitmap(),
                contentDescription = stringResource(R.string.photo_preview),
                modifier = Modifier.fillMaxWidth()
            )
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = stringResource(R.string.resolution, width, height),
            style = MaterialTheme.typography.bodyLarge
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Button(onClick = onBackClick) {
            Text(text = stringResource(R.string.back))
        }
    }
} 