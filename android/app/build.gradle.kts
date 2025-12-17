plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.health"
    
    // ===== SỬA PHẦN NÀY - QUAN TRỌNG ===== //
    compileSdk = 34  // PHẢI >= 33 cho notification hẹn giờ
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.health"
        minSdk = flutter.minSdkVersion  // Android 5.0
        targetSdk = 34  // PHẢI >= 33 cho notification hẹn giờ
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Thêm multiDex cho notification
        multiDexEnabled = true
    }
    // ====================================== //

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
