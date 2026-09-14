import org.jetbrains.kotlin.gradle.dsl.JvmTarget

// Static-linking the native core here avoids shipping a separate libass.so with
// different merge rules from the app.
plugins {
  id("com.android.library")
  id("org.jetbrains.kotlin.android")
}

android {
  namespace = "com.edde746.plezy.libass"
  compileSdk = 36
  // Matches the app's latest stable NDK so every project-owned native library
  // is built with the same 16 KB page-size-capable libc++ toolchain. That copy
  // is NOT what ships: the app packages the mpv-build tarball's newer copy with top
  // merge priority (see app/build.gradle.kts packaging { jniLibs } + sourceSets).
  ndkVersion = "29.0.14206865"

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
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
  }

  externalNativeBuild {
    cmake {
      path = file("src/main/cpp/CMakeLists.txt")
      version = "4.1.2"
    }
  }
}

kotlin {
  compilerOptions {
    jvmTarget.set(JvmTarget.JVM_17)
  }
}

dependencies {
  implementation("androidx.annotation:annotation:1.10.0")
  implementation("androidx.annotation:annotation-experimental:1.6.0")
  implementation("androidx.media3:media3-exoplayer:1.11.0")
  implementation("androidx.media3:media3-ui:1.11.0")

  testImplementation("junit:junit:4.13.2")
}
