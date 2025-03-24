package com.camera.photo.system.presentation.state

import com.camera.photo.system.domain.entity.Project

/**
 * 项目列表UI状态
 */
data class ProjectListState(
    val projects: List<Project> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)

/**
 * 项目详情UI状态
 */
data class ProjectDetailState(
    val project: Project? = null,
    val isLoading: Boolean = false,
    val error: String? = null
)

/**
 * 项目创建/编辑UI状态
 */
data class ProjectFormState(
    val name: String = "",
    val description: String = "",
    val isSubmitting: Boolean = false,
    val nameError: String? = null,
    val descriptionError: String? = null,
    val generalError: String? = null,
    val isSuccess: Boolean = false
) 