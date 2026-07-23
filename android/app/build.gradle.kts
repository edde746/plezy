import java.io.FileInputStream
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.security.MessageDigest
import java.util.Properties
import java.util.UUID

fun verifySha256(file: File, expected: String, identity: String) {
  val digest = MessageDigest.getInstance("SHA-256")
  file.inputStream().buffered().use { input ->
    val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
    while (true) {
      val count = input.read(buffer)
      if (count < 0) break
      digest.update(buffer, 0, count)
    }
  }
  val actual = digest.digest().joinToString("") {
    (it.toInt() and 0xff).toString(16).padStart(2, '0')
  }
  if (actual != expected) {
    throw GradleException("SHA-256 mismatch for $identity: expected $expected, got $actual")
  }
}

fun promoteDirectory(staging: File, destination: File) {
  val backup = File(destination.parentFile, "${destination.name}.backup-${UUID.randomUUID()}")
  val hadDestination = destination.exists()
  try {
    if (hadDestination) {
      Files.move(destination.toPath(), backup.toPath(), StandardCopyOption.ATOMIC_MOVE)
    }
    try {
      Files.move(staging.toPath(), destination.toPath(), StandardCopyOption.ATOMIC_MOVE)
    } catch (promotionFailure: Exception) {
      if (hadDestination && backup.exists()) {
        try {
          Files.move(backup.toPath(), destination.toPath(), StandardCopyOption.ATOMIC_MOVE)
        } catch (restoreFailure: Exception) {
          promotionFailure.addSuppressed(restoreFailure)
        }
      }
      throw promotionFailure
    }
    if (hadDestination && backup.exists() && !backup.deleteRecursively()) {
      throw GradleException("Failed to remove obsolete native artifact backup at ${backup.absolutePath}")
    }
  } finally {
    staging.deleteRecursively()
  }
}

plugins {
  id("com.android.application")
  id("kotlin-android")
  // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
  id("dev.flutter.flutter-gradle-plugin")
}

val mpvVersion = "v1.0.7"
val mpvSha256 = "d55d440e587b2a9ffb91874d93069460a987be05fe72af8394849983f0df2d7a"
val mpvDir = layout.buildDirectory.dir("libmpv").get().asFile
val mpvAar = "libmpv-release.aar"
val mpvUrl = "https://github.com/edde746/libmpv-android/releases/download/$mpvVersion/$mpvAar"

val downloadLibmpv by tasks.registering {
  val aar = File(mpvDir, mpvAar)
  val manifest = File(mpvDir, ".manifest")
  inputs.property("version", mpvVersion)
  inputs.property("sourceUrl", mpvUrl)
  inputs.property("sha256", mpvSha256)
  outputs.files(aar, manifest)
  doLast {
    mpvDir.parentFile.mkdirs()
    val staging = File(mpvDir.parentFile, "${mpvDir.name}.staging-${UUID.randomUUID()}")
    try {
      staging.mkdirs()
      val stagedAar = File(staging, mpvAar)
      try {
        exec { commandLine("curl", "-sfL", mpvUrl, "-o", stagedAar.absolutePath) }
      } catch (error: Exception) {
        throw GradleException("Failed to download $mpvAar $mpvVersion", error)
      }
      verifySha256(stagedAar, mpvSha256, "$mpvAar $mpvVersion")
      File(staging, ".manifest").writeText("version=$mpvVersion\nsha256=$mpvSha256\n")
      promoteDirectory(staging, mpvDir)
    } finally {
      staging.deleteRecursively()
    }
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
      commandLine(
        "unzip",
        "-q",
        "-o",
        aar.absolutePath,
        "jni/*/libc++_shared.so",
        "-d",
        outDir.absolutePath
      )
    }
  }
}

val doviVersion = "2.3.1"
val doviDir = layout.buildDirectory.dir("libdovi").get().asFile
val doviArtifacts = mapOf(
  "arm64-v8a" to Pair(
    "aarch64-linux-android",
    "9d2983fc86f2f9e6da54c3c84ba8ea3a528690619f312ff4620198071b84e9ae"
  ),
  "armeabi-v7a" to Pair(
    "armv7-linux-androideabi",
    "ed6fec8bf744e41c661b97f5fc4bf1197ebe9b09a140cbde369728e790ee3a68"
  ),
  "x86" to Pair(
    "i686-linux-android",
    "50f0a5606e617dff8976b9e7930a23272f4804882a35a6f0f2b2f2d3f8ed7135"
  ),
  "x86_64" to Pair(
    "x86_64-linux-android",
    "eba59678f89b792f5c6f802962e237542fe8328f6aa03a0a90ee77353dac3194"
  )
)
val doviBaseUrl = "https://github.com/edde746/libdovi-builds/releases/download/v$doviVersion"

val downloadLibdovi by tasks.registering {
  val manifest = File(doviDir, ".manifest")
  inputs.property("version", doviVersion)
  inputs.property("baseUrl", doviBaseUrl)
  doviArtifacts.forEach { (abi, artifact) ->
    inputs.property("$abi.triple", artifact.first)
    inputs.property("$abi.sha256", artifact.second)
    inputs.property("$abi.sourceUrl", "$doviBaseUrl/libdovi-${artifact.first}.tar.gz")
  }
  outputs.files(doviArtifacts.keys.map { abi -> File(doviDir, "$abi/lib/libdovi.a") } + manifest)
  doLast {
    doviDir.parentFile.mkdirs()
    val staging = File(doviDir.parentFile, "${doviDir.name}.staging-${UUID.randomUUID()}")
    try {
      staging.mkdirs()
      val downloads = File(staging, ".downloads").apply { mkdirs() }
      doviArtifacts.forEach { (abi, artifact) ->
        val (triple, expectedSha256) = artifact
        val archiveName = "libdovi-$triple.tar.gz"
        val archive = File(downloads, archiveName)
        val sourceUrl = "$doviBaseUrl/$archiveName"
        try {
          exec { commandLine("curl", "-sfL", sourceUrl, "-o", archive.absolutePath) }
        } catch (error: Exception) {
          throw GradleException("Failed to download $archiveName v$doviVersion", error)
        }
        verifySha256(archive, expectedSha256, "$archiveName v$doviVersion")

        val outDir = File(staging, "$abi/lib").apply { mkdirs() }
        try {
          exec { commandLine("tar", "-xzf", archive.absolutePath, "-C", outDir.absolutePath) }
        } catch (error: Exception) {
          throw GradleException("Failed to extract $archiveName", error)
        }
        if (!File(outDir, "libdovi.a").isFile) {
          throw GradleException("$archiveName did not contain the expected libdovi.a")
        }
      }
      if (!downloads.deleteRecursively()) {
        throw GradleException("Failed to clean staged libdovi archives")
      }
      val manifestText = buildString {
        append("version=$doviVersion\n")
        doviArtifacts.forEach { (abi, artifact) ->
          append("$abi=${artifact.first},${artifact.second}\n")
        }
      }
      File(staging, ".manifest").writeText(manifestText)
      promoteDirectory(staging, doviDir)
    } finally {
      staging.deleteRecursively()
    }
  }
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
      // pickFirst only suppresses the duplicate libc++ merge error; the
      // sourceSets rule below makes libmpv's newer runtime win for
      // std::from_chars<float>, while older native consumers remain ABI-compatible.
      pickFirsts.add("lib/*/libc++_shared.so")
    }
  }

  sourceSets {
    getByName("main") {
      // PROJECT-scope jniLibs merge ahead of subprojects/AARs, so dependency
      // order cannot accidentally select the older libc++ copy.
      jniLibs.srcDir(File(mpvDir, "libcxx/jni"))
    }
  }

  lint {
    // Enforce the app-owned minSdk boundary without auditing upstream AndroidX.
    checkDependencies = false
    checkOnly += setOf("NewApi")
  }
}

flutter {
  source = "../.."
}

tasks.matching { it.name.contains("CMake") || it.name.contains("externalNative") }.configureEach {
  dependsOn(downloadLibdovi)
}

tasks.matching { it.name.startsWith("pre") && it.name.endsWith("Build") }.configureEach {
  dependsOn(downloadLibmpv, extractMpvLibcxx)
}
// Gradle snapshots jniLibs source dirs before task execution; this keeps the
// extracted libmpv libc++ directory present during input discovery.
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

  // Keeping libass in-project lets its static core share the app's native
  // packaging rules.
  implementation(project(":libass"))

  testImplementation("junit:junit:4.13.2")
  // Real android.util.* implementations for tests exercising media3 classes
  // (MatroskaExtractor uses SparseArray, which is a no-op stub on plain JVM)
  testImplementation("org.robolectric:robolectric:4.15.1")
}
