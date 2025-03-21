// Top-level build file where you can add configuration options common to all sub-projects/modules.
// plugins {
//     id("com.android.application") version "8.2.2" apply false
//     id("org.jetbrains.kotlin.android") version "1.9.22" apply false
// }
//

// 定义 Kotlin 版本
val kotlinVersion = "1.9.22"

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}