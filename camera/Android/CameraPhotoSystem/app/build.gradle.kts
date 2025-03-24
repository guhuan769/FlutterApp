//CameraPhotoSystem/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("kotlin-kapt") // 添加此行
    id("com.google.dagger.hilt.android") // 添加 Hilt 插件
    id("org.jetbrains.kotlin.plugin.compose") version "2.1.10" // 添加 Compose 编译器插件
}

android {
    namespace = "com.camera.photo.system"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.camera.photo.system"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    buildFeatures {
        viewBinding = true
        compose = true
        buildConfig = true
    }
    composeOptions {
        kotlinCompilerExtensionVersion = "2.1.10" // 更新Kotlin编译器扩展版本
    }
}

dependencies {
    implementation(libs.androidx.core.ktx.v1120)
    implementation(libs.androidx.appcompat)
    implementation(libs.material)
    implementation(libs.androidx.constraintlayout)
    implementation(libs.androidx.material.icons.extended)
    
    // Jetpack Compose
    val composeVersion = "1.5.4"
    implementation(libs.ui)
    implementation(libs.androidx.material)
    implementation(libs.material3)
    implementation(libs.ui.tooling.preview)
    implementation(libs.androidx.activity.compose.v182)
    debugImplementation(libs.ui.tooling)
    
    // CameraX
    val cameraxVersion = "1.3.1"
    implementation(libs.androidx.camera.core)
    implementation(libs.androidx.camera.camera2)
    implementation(libs.androidx.camera.lifecycle)
    implementation(libs.androidx.camera.view)
    
    // ViewModel和LiveData
    val lifecycleVersion = "2.7.0"
    implementation(libs.androidx.lifecycle.viewmodel.ktx)
    implementation(libs.androidx.lifecycle.livedata.ktx)
    
    // Coroutines
    implementation(libs.kotlinx.coroutines.android)
    
    // Hilt依赖注入
    val hiltVersion = "2.56" // 与项目级别一致
    implementation(libs.hilt.android)
    kapt(libs.hilt.android.compiler)

    // Hilt Compose 导航支持
    implementation(libs.androidx.hilt.navigation.compose)
    // Compose 与 LiveData 集成
    implementation(libs.androidx.runtime.livedata)
    
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit.v115)
    androidTestImplementation(libs.androidx.espresso.core.v351)

    // 确保使用正确版本的Kotlin标准库
    implementation(libs.org.jetbrains.kotlin.kotlin.stdlib)
}