import groovy.json.JsonSlurper

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Single source of truth for Google-provided demo IDs (also a Flutter asset).
val admobConfig = JsonSlurper().parse(file("../../config/admob_test.json")) as Map<*, *>
check(admobConfig["mode"] == "test") { "Only test AdMob configuration is implemented." }

// Fail closed: never package this test-only integration for production.
val verifyAdmobReleaseConfiguration = tasks.register("verifyAdmobReleaseConfiguration") {
    doLast {
        throw GradleException(
            "AdMob is TEST ONLY. Release builds are blocked until production configuration is implemented."
        )
    }
}
tasks.configureEach {
    if (name == "preReleaseBuild") {
        dependsOn(verifyAdmobReleaseConfiguration)
    }
}

android {
    namespace = "com.example.dollar_trapped"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        manifestPlaceholders["admobAppId"] = admobConfig["androidAppId"] as String
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.dollar_trapped"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
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
