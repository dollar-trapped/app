import groovy.json.JsonSlurper

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The same environment files are read by Dart. Never use demo IDs in release.
val admobTest = JsonSlurper().parse(file("../../config/admob_test.json")) as Map<*, *>
val admobProduction = JsonSlurper().parse(file("../../config/admob_production.json")) as Map<*, *>
check(admobTest["mode"] == "test")
val verifyAdmobReleaseConfiguration = tasks.register("verifyAdmobReleaseConfiguration") {
    doLast {
        check(admobProduction["mode"] == "production")
        val appId = admobProduction["androidAppId"] as String
        val bannerId = admobProduction["androidAdaptiveBannerId"] as String
        check(Regex("ca-app-pub-[0-9]{16}~[0-9]{10}").matches(appId))
        check(Regex("ca-app-pub-[0-9]{16}/[0-9]{10}").matches(bannerId))
        val rewardedId = admobProduction["androidRewardedId"] as String
        check(Regex("ca-app-pub-[0-9]{16}/[0-9]{10}").matches(rewardedId))
        val ids = listOf(appId, bannerId, rewardedId)
        check(ids.none { it.startsWith("ca-app-pub-3940256099942544") }) {
            "Google demo IDs cannot be used in a release build."
        }
    }
}
tasks.configureEach {
    if (name == "preReleaseBuild") dependsOn(verifyAdmobReleaseConfiguration)
}

android {
    namespace = "com.dollarmullim.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        manifestPlaceholders["admobAppId"] = admobTest["androidAppId"] as String
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.dollarmullim.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            manifestPlaceholders["admobAppId"] = admobProduction["androidAppId"] as String
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
