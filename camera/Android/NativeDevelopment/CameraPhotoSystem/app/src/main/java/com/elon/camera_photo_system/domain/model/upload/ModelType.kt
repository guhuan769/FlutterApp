package com.elon.camera_photo_system.domain.model.upload

import java.util.UUID

/**
 * 模型类型数据模型
 */
data class ModelType(
    val id: String = UUID.randomUUID().toString(),
    val name: String, // 模型名称
    val description: String = "", // 模型描述
    val createdAt: Long = System.currentTimeMillis() // 创建时间
) {
    companion object {
        // 默认模型
        val DEFAULT = ModelType(
            id = "default",
            name = "默认模型",
            description = "系统默认模型"
        )
    }
} 