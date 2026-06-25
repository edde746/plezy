// Static-linking the native core here avoids shipping a separate libass.so with
// different merge rules from the app.
plugins {
  id("com.android.library")
  id("org.jetbrains.kotlin.android")
}

android {
  namespace = "com.edde746.plezy.libass"
  compileSdk = 36
  // Matches flutter.ndkVersion so only one NDK is provisioned. This module's
  // CMake build (-DANDROID_STL=c++_shared) contributes NDK 28.2's
  // libc++_shared.so to packaging, but that copy is NOT what ships: the app
  // packages the libmpv AAR's newer copy with top merge priority (see
  // app/build.gradle.kts packaging { jniLibs } + sourceSets).
  ndkVersion = "28.2.13676358"

  defaultConfig {
    minSdk = 21
    consumerProguardFiles("consumer-rules.pro")
    externalNativeBuild {
      cmake {
        // HarfBuzz pulls in C++, so the JNI library must use the shared STL that
        // the app already pins through libmpv.
        // A shared cache keeps per-ABI CMake runs from redownloading libass.
        arguments += listOf(
          "-DANDROID_STL=c++_shared",
          "-DLIBASS_CACHE_DIR=${layout.buildDirectory.get().asFile}/libass-prebuilt"
        )
      }
    }
  }

  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
  }

  kotlinOptions {
    jvmTarget = JavaVersion.VERSION_11.toString()
  }

  externalNativeBuild {
    cmake {
      path = file("src/main/cpp/CMakeLists.txt")
      version = "3.22.1"
    }
  }
}

dependencies {
  implementation("androidx.annotation:annotation:1.9.1")
  implementation("androidx.annotation:annotation-experimental:1.5.1")
  implementation("androidx.media3:media3-exoplayer:1.9.2")
  implementation("androidx.media3:media3-ui:1.9.2")

  testImplementation("junit:junit:4.13.2")
}
