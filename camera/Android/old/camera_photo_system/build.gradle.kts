// Top-level build file where you can add configuration options common to all sub-projects/modules.
plugins {
    id("com.android.application") version "7.4.2" apply false
    id("com.android.library") version "7.4.2" apply false
    id("org.jetbrains.kotlin.android") version "1.8.0" apply false
    id("com.google.dagger.hilt.android") version "2.44" apply false
}

// 不要在这里定义dependencyResolutionManagement，它应该只在settings.gradle.kts中定义
// 原因：在多个位置定义versionCatalogs会导致错误

// 使用Gradle任务配置
tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}