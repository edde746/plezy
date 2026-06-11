// libass ASS subtitle rendering: Kotlin/JNI bindings + Media3 integration
// (extractor, parsers, AssHandler, GL atlas overlay). The native libass core
// (libass.so + prefab headers) comes from the Maven artifact
// io.github.peerless2012:ass; this module compiles its JNI against it.
plugins {
  id("com.android.library")
  id("org.jetbrains.kotlin.android")
}

android {
  namespace = "com.edde746.plezy.libass"
  compileSdk = 36
  ndkVersion = "28.2.13676358" // matches flutter.ndkVersion so only one NDK is provisioned

  defaultConfig {
    minSdk = 21
    consumerProguardFiles("consumer-rules.pro")
    if (project.hasProperty("localAssCore")) {
      // The locally published A/B core only ships device ABIs (x86 would need
      // nasm on the host); match it so prefab resolution doesn't fail.
      ndk {
        abiFilters += listOf("armeabi-v7a", "arm64-v8a")
      }
    }
    externalNativeBuild {
      cmake {
        // libass.so in the prefab AAR is built against c++_shared (abi.json: stl=c++_shared);
        // prefab validates consumer STL compatibility.
        arguments += listOf("-DANDROID_STL=c++_shared")
      }
    }
  }

  buildFeatures {
    prefab = true
  }

  packaging {
    jniLibs {
      // libass.so is a prefab IMPORTED target (linked, not owned) — the app packages
      // it from the io.github.peerless2012:ass AAR; don't duplicate it here.
      excludes.add("**/libass.so")
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
  // compileOnly: prefab headers + link-time libass.so come from the AAR; runtime
  // packaging of libass.so is the app's implementation dependency.
  // -PlocalAssCore swaps in a mavenLocal()-published core for A/B tests (must
  // match the app module's version so one libass.so is linked and packaged).
  val assCoreVersion = if (project.hasProperty("localAssCore")) "0.4.0-local" else "0.4.1-plezy.1"
  compileOnly("io.github.peerless2012:ass:$assCoreVersion@aar")

  implementation("androidx.annotation:annotation:1.9.1")
  implementation("androidx.annotation:annotation-experimental:1.5.1")
  implementation("androidx.media3:media3-exoplayer:1.9.2")
  implementation("androidx.media3:media3-ui:1.9.2")

  testImplementation("junit:junit:4.13.2")
}
