package com.elon.camera_photo_system.util

import androidx.room.TypeConverter
import java.util.Date

/**
 * 日期转换器，用于Room数据库中存储日期
 */
class DateConverter {
    
    /**
     * 将时间戳转换为日期
     * @param value 时间戳
     * @return 日期
     */
    @TypeConverter
    fun fromTimestamp(value: Long?): Date? {
        return value?.let { Date(it) }
    }
    
    /**
     * 将日期转换为时间戳
     * @param date 日期
     * @return 时间戳
     */
    @TypeConverter
    fun dateToTimestamp(date: Date?): Long? {
        return date?.time
    }
} 