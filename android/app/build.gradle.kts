plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.info_summarizer"
    compileSdk = 34

    val releaseKeystoreEnabled = (System.getenv("KEYSTORE_PASSWORD")?.isNotEmpty()) ?: false

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    signingConfigs {
        if (releaseKeystoreEnabled) {
            create("release") {
                storeFile = file(System.getenv("KEYSTORE_PATH") ?: "upload-keystore.jks")
                storePassword = System.getenv("KEYSTORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
            }
        }
    }

    defaultConfig {
        applicationId = "com.example.info_summarizer"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            if (releaseKeystoreEnabled) {
                signingConfig = signingConfigs["release"]
            }
        }
    }
}

flutter {
    source = "../.."
}