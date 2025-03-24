// Top-level build file where you can add configuration options common to all sub-projects/modules.
//CameraPhotoSystem/build.gradle.kts
plugins {
    id ("com.android.application") version "8.5.1" apply false
    id("com.google.dagger.hilt.android") version "2.56" apply false
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
//        classpath(libs.gradle)
        classpath(libs.kotlin.gradle.plugin)
        classpath(libs.gradle.v851)
    }
}

// 在settings.gradle.kts中应该已经定义了repositories