import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "id.ac.uniba.silakes_analyzer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "id.ac.uniba.silakes_analyzer"
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

    // Kunci rilis dibaca dari android/key.properties (tidak ada di repo). Tanpa berkas itu, build rilis
    // ditandatangani kunci debug.
    val kunci = Properties()
    val berkasKunci = rootProject.file("key.properties")
    if (berkasKunci.exists()) {
        berkasKunci.inputStream().use { kunci.load(it) }
    }

    signingConfigs {
        if (berkasKunci.exists()) {
            create("rilis") {
                keyAlias = kunci.getProperty("keyAlias")
                keyPassword = kunci.getProperty("keyPassword")
                storeFile = file(kunci.getProperty("storeFile"))
                storePassword = kunci.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (berkasKunci.exists()) signingConfigs.getByName("rilis")
                            else signingConfigs.getByName("debug")
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
