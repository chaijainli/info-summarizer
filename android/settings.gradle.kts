pluginManagement {
    val flutterSdkPath = run {
        val propsFile = file("local.properties")
        require(propsFile.exists()) {
            "android/local.properties not found. " +
                "Flutter's Gradle plugin cannot be resolved without the Flutter SDK path. " +
                "Run 'flutter pub get' once locally to generate this file."
        }
        val properties = java.util.Properties()
        propsFile.inputStream().use { properties.load(it) }
        val sdk = properties.getProperty("flutter.sdk")
        require(!sdk.isNullOrBlank()) {
            "flutter.sdk is missing or empty in android/local.properties"
        }
        sdk
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-gradle-plugin") apply false
    id("com.android.application") version "8.2.1" apply false
    id("org.jetbrains.kotlin.android") version "1.9.23" apply false
}

include(":app")
