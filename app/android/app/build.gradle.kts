import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Khóa ký bản phát hành (ADR 0014): CI đọc biến môi trường từ secrets; máy dev đọc android/key.properties
// (không commit, xem .gitignore). Thiếu khóa thì bản release ký bằng khóa debug như trước, chỉ để thử ở máy;
// release.yml chặn việc phát hành khi thiếu khóa.
val keyProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
fun releaseKey(name: String, env: String): String? = System.getenv(env) ?: keyProps.getProperty(name)
val releaseStoreFile = releaseKey("storeFile", "WW_KEYSTORE_PATH")
val hasReleaseKey = releaseStoreFile != null && file(releaseStoreFile).exists()

android {
    namespace = "vn.wholewell.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "vn.wholewell.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // API 28: khóa CSDL dùng setUnlockedDeviceRequired (docs/specs/encrypted-db.md).
        minSdk = 28
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Tạm chỉ đóng gói ABI arm64-v8a (Galaxy S24 Ultra) để build nhanh và nhẹ; gỡ khi hỗ trợ đa thiết bị.
        ndk {
            abiFilters += listOf("arm64-v8a")
        }
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseKey("storePassword", "WW_KEYSTORE_PASSWORD")
                keyAlias = releaseKey("keyAlias", "WW_KEY_ALIAS")
                keyPassword = releaseKey("keyPassword", "WW_KEY_PASSWORD")
            }
        }
    }

    // Flavor (ADR 0012): dev có app id riêng nên dữ liệu, khóa Keystore riêng, cài song song với bản thật.
    // Đăng nhập Google Drive ở bản dev cần Android OAuth client riêng trong cùng dự án Google Cloud.
    buildFeatures {
        resValues = true
    }
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "WholeWell Dev")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "WholeWell")
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Gemini Nano on-device qua Android AICore (tự fallback về OCR nếu máy không hỗ trợ).
    implementation("com.google.mlkit:genai-prompt:1.0.0-beta5")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
    // Test JVM cho quy tắc kho khóa (DbKeyRules).
    testImplementation("junit:junit:4.13.2")
}
