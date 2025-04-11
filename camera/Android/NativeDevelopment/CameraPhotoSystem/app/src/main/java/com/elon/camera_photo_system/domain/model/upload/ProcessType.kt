package com.elon.camera_photo_system.domain.model.upload

import java.util.UUID

/**
 * 工艺类型数据模型
 */
data class ProcessType(
    val id: String = UUID.randomUUID().toString(),
    val name: String, // 工艺名称
    val description: String = "", // 工艺描述
    val createdAt: Long = System.currentTimeMillis() // 创建时间
) {
    companion object {
        // 默认工艺
        val DEFAULT = ProcessType(
            id = "default",
            name = "默认工艺",
            description = "系统默认工艺"
        )
    }
} 