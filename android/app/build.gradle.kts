import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.edde746.plezy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.edde746.plezy"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 25  // Fire OS 6.x (API 25); overrides libmpv-android's minSdk=26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = Properties()
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))

                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Only use release signing if key.properties exists (not in CI/CD)
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            // If key.properties doesn't exist, it will use debug signing for CI builds
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
    }

    packaging {
        jniLibs {
            // Resolve conflict between libass-android and libmpv native libraries
            pickFirsts.add("lib/*/libc++_shared.so")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("dev.jdtech.mpv:libmpv:0.5.1")

    // Android TV Watch Next integration
    implementation("androidx.tvprovider:tvprovider:1.0.0")

    // Media3 ExoPlayer for Android
    implementation("androidx.media3:media3-exoplayer:1.9.2")
    implementation("androidx.media3:media3-ui:1.9.2")
    implementation("androidx.media3:media3-common:1.9.2")

    // FFmpeg audio decoder for unsupported codecs (ALAC, DTS, TrueHD, etc.)
    implementation("org.jellyfin.media3:media3-ffmpeg-decoder:1.9.0+1")

    // libass-android for ASS/SSA subtitle rendering (fork with font buffering fix)
    implementation(files("libs/ass-media.aar"))
    // ass-kt core library (needed for AssRender.setFontScale)
    implementation("io.github.peerless2012:ass-kt:0.4.0-beta01")
}
