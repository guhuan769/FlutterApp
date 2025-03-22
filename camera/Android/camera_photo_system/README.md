# Camera Photo System

## 依赖管理指南

本项目使用Gradle Version Catalog（Gradle版本目录）进行依赖管理，这是Gradle提供的一种集中管理依赖版本的方式，可以显著简化依赖管理并避免版本冲突。

### Version Catalog结构

Version Catalog配置位于以下文件中：
- `gradle/libs.versions.toml` - 主要的依赖定义文件，采用TOML格式
- `settings.gradle.kts` - 启用并配置Version Catalog
- `build.gradle.kts` (项目级) - 基础项目配置
- `app/build.gradle.kts` - 应用模块依赖声明

### TOML文件结构

`libs.versions.toml`文件分为以下几个部分：

1. **[versions]** - 定义所有依赖库的版本号
   ```toml
   [versions]
   core-ktx = "1.12.0"
   ```

2. **[libraries]** - 定义具体的库引用
   ```toml
   [libraries]
   core-ktx = { group = "androidx.core", name = "core-ktx", version.ref = "core-ktx" }
   ```

3. **[bundles]** - 定义库的组合包，方便一次引入多个相关库
   ```toml
   [bundles]
   androidx-core = ["core-ktx", "appcompat", "lifecycle-runtime-ktx"]
   ```

4. **[plugins]** - 定义Gradle插件
   ```toml
   [plugins]
   android-application = { id = "com.android.application", version = "8.1.0" }
   ```

### 如何使用

在`app/build.gradle.kts`中使用定义好的依赖：

```kotlin
// 使用依赖包
implementation(libs.bundles.androidx.core)

// 使用单个依赖
implementation(libs.core.ktx)

// 使用kapt处理器
kapt(libs.room.compiler)

// 使用平台依赖(BOM)
implementation(platform(libs.compose.bom))
```

### 如何添加新依赖

1. 在`gradle/libs.versions.toml`文件中添加版本：
   ```toml
   [versions]
   new-library = "1.0.0"
   ```

2. 添加库引用：
   ```toml
   [libraries]
   new-library = { group = "com.example", name = "library", version.ref = "new-library" }
   ```

3. 可选：将新库添加到现有bundle或创建新bundle：
   ```toml
   [bundles]
   my-bundle = ["existing-lib", "new-library"]
   ```

4. 在`app/build.gradle.kts`中使用：
   ```kotlin
   implementation(libs.new.library)
   // 或
   implementation(libs.bundles.my.bundle)
   ```

### 优势

- **集中管理版本** - 所有版本号在一处定义，便于维护
- **版本一致性** - 避免同一依赖在不同模块使用不同版本
- **简化依赖声明** - 使用简短引用替代完整坐标
- **依赖分组** - 通过bundle快速引入相关依赖组
- **代码自动完成** - IDE提供依赖引用的代码自动完成

### 更新依赖

要更新依赖版本，只需在`gradle/libs.versions.toml`文件中修改相应的版本号即可。这样，所有使用该依赖的模块都会自动更新到新版本。 