plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.kmart_staff_portal"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.kmart_staff_portal"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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

tasks.matching { it.name.startsWith("cleanMerge") && it.name.endsWith("Assets") }.configureEach {
    doFirst {
        val assetsDir = file("${project.layout.buildDirectory.get().asFile}/intermediates/assets")
        if (assetsDir.exists()) {
            for (i in 1..10) {
                if (assetsDir.deleteRecursively()) break
                Thread.sleep(300)
            }
        }
    }
}

tasks.matching { it.name.contains("Merge") && it.name.contains("NativeLibs") }.configureEach {
    doFirst {
        val nativeLibsDir = file("${project.layout.buildDirectory.get().asFile}/intermediates/merged_native_libs")
        if (nativeLibsDir.exists()) {
            for (i in 1..10) {
                if (nativeLibsDir.deleteRecursively()) break
                Thread.sleep(300)
            }
        }
    }
}

tasks.matching { it.name.contains("package") && it.name.contains("Resources") }.configureEach {
    doFirst {
        for (subPath in listOf("intermediates/incremental", "intermediates/packaged_res")) {
            val dir = file("${project.layout.buildDirectory.get().asFile}/$subPath")
            if (dir.exists()) {
                for (i in 1..15) {
                    try {
                        if (dir.deleteRecursively()) break
                    } catch (_: Exception) {
                        Thread.sleep(300)
                    }
                }
            }
        }
    }
}

tasks.matching { it.name.contains("compress") && it.name.contains("Assets") }.configureEach {
    doFirst {
        val compressedDir = file("${project.layout.buildDirectory.get().asFile}/intermediates/compressed_assets")
        if (compressedDir.exists()) {
            for (i in 1..15) {
                try {
                    if (compressedDir.deleteRecursively()) break
                } catch (_: Exception) {
                    Thread.sleep(300)
                }
            }
        }
    }
}

tasks.matching { it.name == "assembleDebug" || it.name == "assembleRelease" }.configureEach {
    doLast {
        val buildDir = project.layout.buildDirectory.get().asFile
        val debugApk = file("$buildDir/app/outputs/apk/debug/app-debug.apk")
        val releaseApk = file("$buildDir/app/outputs/apk/release/app-release.apk")
        
        val rootProj = rootProject.projectDir.parentFile ?: rootProject.projectDir
        
        if (debugApk.exists()) {
            val targetFlutterApk = file("$rootProj/build/app/outputs/flutter-apk/app-debug.apk")
            val targetStandardApk = file("$rootProj/build/app/outputs/apk/debug/app-debug.apk")
            targetFlutterApk.parentFile?.mkdirs()
            targetStandardApk.parentFile?.mkdirs()
            debugApk.copyTo(targetFlutterApk, overwrite = true)
            debugApk.copyTo(targetStandardApk, overwrite = true)
        }
        if (releaseApk.exists()) {
            val targetFlutterApk = file("$rootProj/build/app/outputs/flutter-apk/app-release.apk")
            val targetStandardApk = file("$rootProj/build/app/outputs/apk/release/app-release.apk")
            targetFlutterApk.parentFile?.mkdirs()
            targetStandardApk.parentFile?.mkdirs()
            releaseApk.copyTo(targetFlutterApk, overwrite = true)
            releaseApk.copyTo(targetStandardApk, overwrite = true)
        }
    }
}
