try {
    val processEnv = Class.forName("java.lang.ProcessEnvironment")
    val envField = processEnv.getDeclaredField("theEnvironment")
    envField.isAccessible = true
    (envField.get(null) as? MutableMap<String, String>)?.remove("ANDROID_PREFS_ROOT")
    val caseInsensitiveEnvField = processEnv.getDeclaredField("theCaseInsensitiveEnvironment")
    caseInsensitiveEnvField.isAccessible = true
    (caseInsensitiveEnvField.get(null) as? MutableMap<String, String>)?.remove("ANDROID_PREFS_ROOT")
} catch (_: Throwable) {}

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
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
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
