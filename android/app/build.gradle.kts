import java.io.FileInputStream
import java.util.Properties

plugins {
  id("com.android.application")
  id("kotlin-android")
  // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
  id("dev.flutter.flutter-gradle-plugin")
}

val mpvVersion = "v1.0.7"
val mpvDir = layout.buildDirectory.dir("libmpv").get().asFile
val mpvAar = "libmpv-release.aar"

val downloadLibmpv by tasks.registering {
  val stamp = File(mpvDir, ".version")
  outputs.upToDateWhen { stamp.exists() && stamp.readText().trim() == mpvVersion }
  doLast {
    mpvDir.mkdirs()
    val url = "https://github.com/edde746/libmpv-android/releases/download/$mpvVersion/$mpvAar"
    exec { commandLine("curl", "-sfL", url, "-o", File(mpvDir, mpvAar).absolutePath) }
    stamp.writeText(mpvVersion)
  }
}

// Extract libc++_shared.so from the libmpv AAR so the app source set can package
// it with top merge priority (see packaging { jniLibs } and sourceSets below).
val extractMpvLibcxx by tasks.registering {
  dependsOn(downloadLibmpv)
  val aar = File(mpvDir, mpvAar)
  val outDir = File(mpvDir, "libcxx")
  inputs.file(aar)
  outputs.dir(outDir)
  doLast {
    outDir.deleteRecursively() // drop stale ABIs from a previous AAR version
    outDir.mkdirs()
    exec {
      commandLine("unzip", "-q", "-o", aar.absolutePath,
        "jni/*/libc++_shared.so", "-d", outDir.absolutePath)
    }
  }
}

val doviVersion = "2.3.1"
val doviDir = layout.buildDirectory.dir("libdovi").get().asFile
val doviAbis = mapOf(
  "arm64-v8a" to "aarch64-linux-android",
  "armeabi-v7a" to "armv7-linux-androideabi",
  "x86" to "i686-linux-android",
  "x86_64" to "x86_64-linux-android"
)

val downloadLibdovi by tasks.registering {
  val stamp = File(doviDir, ".version")
  outputs.upToDateWhen { stamp.exists() && stamp.readText().trim() == doviVersion }
  doLast {
    doviDir.mkdirs()
    val baseUrl = "https://github.com/edde746/libdovi-builds/releases/download/v$doviVersion"
    doviAbis.forEach { (abi, triple) ->
      val archive = File(doviDir, "$triple.tar.gz")
      exec { commandLine("curl", "-sfL", "$baseUrl/libdovi-$triple.tar.gz", "-o", archive.absolutePath) }
      val outDir = File(doviDir, "$abi/lib")
      outDir.mkdirs()
      exec { commandLine("tar", "-xzf", archive.absolutePath, "-C", outDir.absolutePath) }
      archive.delete()
    }
    stamp.writeText(doviVersion)
  }
}

android {
  namespace = "com.amaze.vibestream"
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
    applicationId = "com.amaze.vibestream"
    // You can update the following values to match your application needs.
    // For more information, see: https://flutter.dev/to/review-gradle-config.
    minSdk = 25 // Fire OS 6.x (API 25); overrides libmpv-android's minSdk=26
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName

    externalNativeBuild {
      cmake {
        arguments += listOf(
          "-DDOVI_ENABLE_LIBDOVI=ON",
          "-DDOVI_LIBDOVI_PREBUILT_ROOT=${doviDir.absolutePath}"
        )
      }
    }

    if (System.getenv("AMAZON") != null) {
      versionCode = (flutter.versionCode ?: 0) + 3000
      ndk {
        abiFilters += listOf("armeabi-v7a", "arm64-v8a")
      }
    }
  }

  externalNativeBuild {
    cmake {
      path = file("src/main/cpp/CMakeLists.txt")
    }
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
      // Three copies of libc++_shared.so reach the merge: the libmpv AAR's
      // (NDK r29 — exports std::from_chars<float> that libmpv.so needs), the
      // :libass module's CMake-contributed copy (NDK 28.2 — lacks it), and
      // peerless2012:ass's bundled copy (also old). pickFirst keeps the merge
      // from erroring on the duplicates; WHICH copy wins is pinned by the
      // sourceSets block below: extractMpvLibcxx unpacks the libmpv AAR's copy
      // into an app jniLibs dir, and PROJECT-scope sources beat sub-projects
      // and external AARs. libc++ is backward ABI-compatible, so the older-NDK
      // consumers (libass.so, libasskt.so, ffmpeg decoder, cronet) run fine
      // against the newer copy.
      pickFirsts.add("lib/*/libc++_shared.so")
    }
  }

  sourceSets {
    getByName("main") {
      // libc++_shared.so extracted from the libmpv AAR by extractMpvLibcxx.
      // App source-set jniLibs sit in the PROJECT scope, merged ahead of
      // subprojects (:libass) and external AARs, so with the pickFirst rule
      // above this copy deterministically wins regardless of dependency order.
      jniLibs.srcDir(File(mpvDir, "libcxx/jni"))
    }
  }
}

flutter {
  source = "../.."
}

// Download libdovi before any CMake/native build task
tasks.matching { it.name.contains("CMake") || it.name.contains("externalNative") }.configureEach {
  dependsOn(downloadLibdovi)
}

// Download the libmpv AAR before compilation
tasks.matching { it.name.startsWith("pre") && it.name.endsWith("Build") }.configureEach {
  dependsOn(downloadLibmpv, extractMpvLibcxx)
}
// merge{Debug,Profile,Release}JniLibFolders snapshot jniLibs source dirs as inputs;
// Gradle 8 requires an explicit dependency on the producing task.
tasks.matching { it.name.startsWith("merge") && it.name.endsWith("JniLibFolders") }.configureEach {
  dependsOn(extractMpvLibcxx)
}

dependencies {
  implementation(files(File(mpvDir, mpvAar)))
  implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")

  // Android TV Watch Next integration
  implementation("androidx.tvprovider:tvprovider:1.0.0")

  // Media3 ExoPlayer for Android
  implementation("androidx.media3:media3-exoplayer:1.9.2")
  implementation("androidx.media3:media3-exoplayer-hls:1.9.2")
  implementation("androidx.media3:media3-ui:1.9.2")
  implementation("androidx.media3:media3-common:1.9.2")

  // Cronet for HTTP/2 multiplexing + better connection management
  implementation("androidx.media3:media3-datasource-cronet:1.9.2")
  implementation("org.chromium.net:cronet-embedded:143.7445.0")

  // FFmpeg audio decoder for unsupported codecs (ALAC, DTS, TrueHD, etc.)
  implementation("org.jellyfin.media3:media3-ffmpeg-decoder:1.9.0+1")

  // libass ASS/SSA subtitle rendering: optimized native core (libass.so +
  // prefab headers) from the edde746/libass-android fork's releases; Kotlin/JNI
  // bindings + Media3 glue live in the android/libass module. -PlocalAssCore
  // swaps in a mavenLocal()-published core (0.4.0-local) for native A/B tests.
  val assCoreVersion = if (project.hasProperty("localAssCore")) "0.4.0-local" else "0.4.1-plezy.1"
  implementation("io.github.peerless2012:ass:$assCoreVersion@aar")
  implementation(project(":libass"))

  testImplementation("junit:junit:4.13.2")
}
