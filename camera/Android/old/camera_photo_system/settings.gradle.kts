pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    plugins {
        id("com.android.application") version "7.4.2" 
        id("com.android.library") version "7.4.2"
        id("org.jetbrains.kotlin.android") version "1.8.0"
        id("com.google.dagger.hilt.android") version "2.44"
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}

rootProject.name = "camera_photo_system"
include(":app")
