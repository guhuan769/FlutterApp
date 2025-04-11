package com.elon.camera_photo_system.domain.usecase.photo

import com.elon.camera_photo_system.domain.model.ModuleType
import com.elon.camera_photo_system.domain.model.Photo
import com.elon.camera_photo_system.domain.model.PhotoType
import com.elon.camera_photo_system.domain.repository.PhotoRepository
import java.time.LocalDateTime
import javax.inject.Inject
import android.util.Log

/**
 * 保存照片用例
 */
class SavePhotoUseCase @Inject constructor(
    private val photoRepository: PhotoRepository
) {
    /**
     * 保存照片
     *
     * @param moduleId 模块ID
     * @param moduleType 模块类型
     * @param photoType 照片类型
     * @param filePath 文件路径
     * @param fileName 文件名
     * @param latitude 纬度
     * @param longitude 经度
     * @return 照片ID
     */
    suspend operator fun invoke(
        moduleId: Long,
        moduleType: ModuleType,
        photoType: PhotoType,
        filePath: String,
        fileName: String,
        latitude: Double? = null,
        longitude: Double? = null
    ): Long {
        // 从文件名中提取照片序号和角度
        val (photoNumber, angle) = extractPhotoInfoFromFileName(fileName, moduleType)
        
        Log.d("SavePhotoUseCase", "提取的照片信息: 序号=$photoNumber, 角度=$angle")
        
        val photo = Photo(
            moduleId = moduleId,
            moduleType = moduleType,
            photoType = photoType,
            filePath = filePath,
            fileName = fileName,
            photoNumber = photoNumber, // 设置序号
            angle = angle, // 设置角度
            createdAt = LocalDateTime.now(),
            latitude = latitude,
            longitude = longitude,
            isUploaded = false
        )
        
        return photoRepository.savePhoto(photo)
    }
    
    /**
     * 从文件名中提取照片序号和角度信息
     */
    private fun extractPhotoInfoFromFileName(fileName: String, moduleType: ModuleType): Pair<Int, Int> {
        try {
            Log.d("SavePhotoUseCase", "从文件名提取信息: $fileName")
            val parts = fileName.split("_")
            
            // 根据不同模块类型，序号位置不同
            val numIndex = when (moduleType) {
                ModuleType.PROJECT -> 2 // 项目名称_照片类型_序号_角度.jpg
                ModuleType.VEHICLE -> 3 // 项目名称_车辆名称_照片类型_序号_角度.jpg
                ModuleType.TRACK -> 4   // 项目名称_车辆名称_轨迹名称_照片类型_序号_角度.jpg
            }
            
            // 确保序号索引有效
            if (numIndex >= parts.size) {
                Log.e("SavePhotoUseCase", "无效的序号索引: $numIndex, 部分大小: ${parts.size}")
                return Pair(0, 0)
            }
            
            // 提取序号
            val photoNumber = parts[numIndex].toIntOrNull() ?: 0
            
            // 提取角度 - 更强健的方法
            val angle = if (numIndex + 1 < parts.size) {
                // 获取可能包含角度和扩展名的部分
                val anglePart = parts[numIndex + 1]
                // 使用正则表达式提取数字部分
                val angleMatch = Regex("(\\d+)").find(anglePart)
                angleMatch?.groupValues?.get(1)?.toIntOrNull() ?: 0
            } else 0
            
            Log.d("SavePhotoUseCase", "提取的序号: $photoNumber, 角度: $angle")
            return Pair(photoNumber, angle)
        } catch (e: Exception) {
            Log.e("SavePhotoUseCase", "提取照片信息错误: ${e.message}")
            return Pair(0, 0)
        }
    }
} 