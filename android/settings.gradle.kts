pluginManagement {
    val flutterSdkPath = try {
        val properties = java.util.Properties()
        val propsFile = file("local.properties")
        if (propsFile.exists()) {
            propsFile.inputStream().use { properties.load(it) }
            properties.getProperty("flutter.sdk")
        } else {
            null
        }
    } catch (e: Exception) {
        null
    }

    val flutterRoot = flutterSdkPath ?: System.getenv("FLUTTER_ROOT")
    if (flutterRoot != null) {
        includeBuild("$flutterRoot/packages/flutter_tools/gradle")
    }

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-gradle-plugin") apply false
    id("com.android.application") version "8.2.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.10" apply false
}

include(":app")