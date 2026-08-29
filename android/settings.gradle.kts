pluginManagement {
    val flutterSdkPath = run {
        // Try local.properties first
        val propsFile = file("local.properties")
        var sdk: String? = null
        if (propsFile.exists()) {
            val properties = java.util.Properties()
            propsFile.inputStream().use { properties.load(it) }
            sdk = properties.getProperty("flutter.sdk")
        }

        // Fallback to FLUTTER_ROOT environment variable (set by GitHub Actions)
        if (sdk == null || sdk.isBlank()) {
            sdk = System.getenv("FLUTTER_ROOT")
        }

        require(!sdk.isNullOrBlank()) {
            """
            Flutter SDK location cannot be determined.
            - local.properties not found or does not contain 'flutter.sdk' property
            - Environment variable FLUTTER_ROOT is not set
            In CI: ensure 'flutter pub get' ran successfully before Gradle build,
              and that FLUTTER_ROOT is exported in the environment.
            Locally: run 'flutter pub get' at least once to generate android/local.properties.
            """.trimIndent()
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
