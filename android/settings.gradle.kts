pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localPropertiesFile = file("local.properties")
        if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { properties.load(it) }
            val sdk = properties.getProperty("flutter.sdk")
            if (!sdk.isNullOrEmpty()) return@run sdk
        }
        
        val envFlutterRoot = System.getenv("FLUTTER_ROOT")
        require(!envFlutterRoot.isNullOrEmpty()) {
            "Flutter SDK location not found. " +
                "Please define flutter.sdk in local.properties or set FLUTTER_ROOT environment variable."
        }
        envFlutterRoot
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.2.1" apply false
    id("org.jetbrains.kotlin.android") version "1.9.23" apply false
}

include(":app")
