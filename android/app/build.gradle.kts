import java.io.FileInputStream
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.security.MessageDigest
import java.util.Properties
import java.util.UUID
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

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

val media3Version = "1.10.1"
val mpvFfmpegVersion = "8.0.1"
val mpvFfmpegSourceSha256 = "05ee0b03119b45c0bdb4df654b96802e909e0a752f72e4fe3794f487229e5a41"
val mpvFfmpegSourceUrl = "https://ffmpeg.org/releases/ffmpeg-$mpvFfmpegVersion.tar.xz"
val mpvFfmpegDevelopmentDir = File(mpvDir, "ffmpeg-development")

val downloadLibmpv = tasks.register("downloadLibmpv") {
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
        providers.exec {
          commandLine("curl", "-sfL", mpvUrl, "-o", stagedAar.absolutePath)
        }.result.get().assertNormalExitValue()
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
val extractMpvLibcxx = tasks.register("extractMpvLibcxx") {
  dependsOn(downloadLibmpv)
  val aar = File(mpvDir, mpvAar)
  val outDir = File(mpvDir, "libcxx")
  inputs.file(aar)
  outputs.dir(outDir)
  doLast {
    outDir.deleteRecursively() // drop stale ABIs from a previous AAR version
    outDir.mkdirs()
    providers.exec {
      commandLine(
        "unzip",
        "-q",
        "-o",
        aar.absolutePath,
        "jni/*/libc++_shared.so",
        "-d",
        outDir.absolutePath
      )
    }.result.get().assertNormalExitValue()
  }
}

// Build the Media3 JNI adapter against the same shared FFmpeg libraries that
// libmpv packages. Headers are pinned to libmpv's FFmpeg version and remain
// build-only; the APK contains one FFmpeg implementation for both players.
val prepareMpvFfmpegDevelopment = tasks.register("prepareMpvFfmpegDevelopment") {
  dependsOn(downloadLibmpv)
  val aar = File(mpvDir, mpvAar)
  val manifest = File(mpvFfmpegDevelopmentDir, ".manifest")
  val abis = listOf("arm64-v8a", "armeabi-v7a", "x86", "x86_64")
  val libraries = listOf("avcodec", "avutil", "swresample")
  inputs.file(aar)
  inputs.property("ffmpegVersion", mpvFfmpegVersion)
  inputs.property("sourceUrl", mpvFfmpegSourceUrl)
  inputs.property("sourceSha256", mpvFfmpegSourceSha256)
  outputs.files(
    abis.flatMap { abi ->
      libraries.map { library -> File(mpvFfmpegDevelopmentDir, "native/$abi/lib$library.so") }
    }
  )
  outputs.files(
    File(mpvFfmpegDevelopmentDir, "include/libavcodec/avcodec.h"),
    File(mpvFfmpegDevelopmentDir, "include/libavutil/avconfig.h"),
    File(mpvFfmpegDevelopmentDir, "include/libswresample/swresample.h"),
    manifest
  )
  doLast {
    val staging = File(
      mpvFfmpegDevelopmentDir.parentFile,
      "${mpvFfmpegDevelopmentDir.name}.staging-${UUID.randomUUID()}"
    )
    try {
      val sourceArchive = File(staging, "ffmpeg-$mpvFfmpegVersion.tar.xz")
      val includeDir = File(staging, "include")
      val nativeDir = File(staging, "native")
      staging.mkdirs()
      try {
        providers.exec {
          commandLine("curl", "-sfL", mpvFfmpegSourceUrl, "-o", sourceArchive.absolutePath)
        }.result.get().assertNormalExitValue()
      } catch (error: Exception) {
        throw GradleException("Failed to download FFmpeg $mpvFfmpegVersion headers", error)
      }
      verifySha256(sourceArchive, mpvFfmpegSourceSha256, "FFmpeg $mpvFfmpegVersion source")

      val extractedSource = File(staging, "source").apply { mkdirs() }
      try {
        providers.exec {
          commandLine(
            "tar",
            "-xJf",
            sourceArchive.absolutePath,
            "--strip-components=1",
            "-C",
            extractedSource.absolutePath
          )
        }.result.get().assertNormalExitValue()
      } catch (error: Exception) {
        throw GradleException("Failed to extract FFmpeg $mpvFfmpegVersion headers", error)
      }
      listOf("libavcodec", "libavutil", "libswresample").forEach { library ->
        project.copy {
          from(File(extractedSource, library)) {
            include("*.h")
          }
          into(File(includeDir, library))
        }
      }
      File(includeDir, "libavutil/avconfig.h").writeText(
        """
        |/* Generated for Plezy's little-endian Android ABIs. */
        |#ifndef AVUTIL_AVCONFIG_H
        |#define AVUTIL_AVCONFIG_H
        |#define AV_HAVE_BIGENDIAN 0
        |#define AV_HAVE_FAST_UNALIGNED 0
        |#endif /* AVUTIL_AVCONFIG_H */
        |
        """.trimMargin()
      )

      project.copy {
        from(zipTree(aar)) {
          include(
            "jni/*/libavcodec.so",
            "jni/*/libavutil.so",
            "jni/*/libswresample.so"
          )
          eachFile {
            path = path.removePrefix("jni/")
          }
        }
        includeEmptyDirs = false
        into(nativeDir)
      }

      val missing = abis.flatMap { abi ->
        libraries.map { library -> File(nativeDir, "$abi/lib$library.so") }
      }.filterNot(File::isFile)
      if (missing.isNotEmpty()) {
        throw GradleException(
          "libmpv $mpvVersion is missing FFmpeg libraries: ${missing.joinToString { it.relativeTo(staging).path }}"
        )
      }
      File(staging, ".manifest").writeText(
        "mpv=$mpvVersion\nffmpeg=$mpvFfmpegVersion\nsourceSha256=$mpvFfmpegSourceSha256\n"
      )
      sourceArchive.delete()
      extractedSource.deleteRecursively()
      promoteDirectory(staging, mpvFfmpegDevelopmentDir)
    } finally {
      staging.deleteRecursively()
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

val downloadLibdovi = tasks.register("downloadLibdovi") {
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
          providers.exec {
            commandLine("curl", "-sfL", sourceUrl, "-o", archive.absolutePath)
          }.result.get().assertNormalExitValue()
        } catch (error: Exception) {
          throw GradleException("Failed to download $archiveName v$doviVersion", error)
        }
        verifySha256(archive, expectedSha256, "$archiveName v$doviVersion")

        val outDir = File(staging, "$abi/lib").apply { mkdirs() }
        try {
          providers.exec {
            commandLine("tar", "-xzf", archive.absolutePath, "-C", outDir.absolutePath)
          }.result.get().assertNormalExitValue()
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
  buildToolsVersion = "36.1.0"
  ndkVersion = "29.0.14206865"

  // Android Automotive OS driver-distraction state (CarUxRestrictionsManager). This is a platform
  // stub, not a shipped dependency: the classes exist only on AAOS images, so every use is guarded
  // by FEATURE_AUTOMOTIVE and the manifest declares `uses-library android.car required=false`.
  useLibrary("android.car")

  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
  }

  defaultConfig {
    applicationId = "com.edde746.plezy"
    // You can update the following values to match your application needs.
    // For more information, see: https://flutter.dev/to/review-gradle-config.
    minSdk = 25 // Fire OS 6.x (API 25); overrides libmpv-android's minSdk=26
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
    testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

    externalNativeBuild {
      cmake {
        arguments += listOf(
          "-DDOVI_ENABLE_LIBDOVI=ON",
          "-DDOVI_LIBDOVI_PREBUILT_ROOT=${doviDir.absolutePath}",
          "-DMPV_FFMPEG_ROOT=${mpvFfmpegDevelopmentDir.absolutePath}"
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
      version = "4.1.2"
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

    // Instrumentation target that runs R8 (see testBuildType below).
    //
    // R8 only ever ran on `release`, so every gate in this repository exercised code
    // the shipped APK does not contain: reflective lookups, JNI callbacks and native
    // library loading can all break under shrinking while every debug check passes.
    // #1703 shipped that way — DefaultRenderersFactory's Class.forName for the bundled
    // FFmpeg audio renderer failed in release builds only.
    //
    // Inherits release's minification and keep rules (the Flutter plugin has already
    // installed them by the time this block runs) but stays debuggable and debug-signed,
    // so it is an ordinary test artifact and never a publishable one. Debuggable also
    // makes the Flutter plugin treat it as debug mode, so it uses debug Dart artifacts.
    create("minified") {
      initWith(getByName("release"))
      isDebuggable = true
      // Resource shrinking is orthogonal to the reachability this variant guards and
      // would only slow the instrumentation build down.
      isShrinkResources = false
      testProguardFiles("proguard-test-rules.pro")
      proguardFile("proguard-instrumentation-rules.pro")
      // Release has no signing config unless key.properties exists, which would leave
      // this variant unsigned and uninstallable in CI.
      signingConfig = signingConfigs.getByName("debug")
      // Plugin subprojects only publish debug and release variants.
      matchingFallbacks += listOf("debug", "release")
      ndk {
        debugSymbolLevel = "NONE"
      }
    }
  }

  // Instrumentation normally runs against `debug`; the R8 reachability gate opts into the
  // minified variant with -Pplezy.testBuildType=minified. Only one build type can host
  // androidTest, and the existing playback suites need media3 builder APIs the app itself
  // never calls — which R8 legitimately shrinks — so they stay on debug.
  testBuildType = (findProperty("plezy.testBuildType") as String?) ?: "debug"

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

// BackgroundWorkDiagnostics routes users to background_downloader's private
// notification channel. Fail the build if an upstream ref changes that ID.
val verifyBackgroundDownloaderNotificationChannel = tasks.register("verifyBackgroundDownloaderNotificationChannel") {
  val expectedChannelId = "background_downloader"
  val downloaderProject = rootProject.findProject(":background_downloader")
  val notificationsSource = downloaderProject?.projectDir?.resolve(
    "src/main/kotlin/com/bbflight/background_downloader/Notifications.kt"
  )
  notificationsSource?.let(inputs::file)
  doLast {
    if (notificationsSource == null) {
      logger.lifecycle("Skipping downloader channel verification: Flutter plugin project is not configured")
      return@doLast
    }
    val actualChannelId = Regex(
      """private const val notificationChannelId\s*=\s*"([^"]+)""""
    ).find(notificationsSource.readText())?.groupValues?.get(1)
      ?: throw GradleException("Could not locate background_downloader's notification channel ID")
    if (actualChannelId != expectedChannelId) {
      throw GradleException(
        "background_downloader channel ID changed from $expectedChannelId to $actualChannelId; " +
          "update BackgroundWorkDiagnostics and its tests"
      )
    }
  }
}
tasks.named("preBuild").configure {
  dependsOn(verifyBackgroundDownloaderNotificationChannel)
}

kotlin {
  compilerOptions {
    jvmTarget.set(JvmTarget.JVM_17)
  }
}

flutter {
  source = "../.."
}

tasks.matching { it.name.contains("CMake") || it.name.contains("externalNative") }.configureEach {
  dependsOn(downloadLibdovi, prepareMpvFfmpegDevelopment)
}

tasks.matching { it.name.startsWith("pre") && it.name.endsWith("Build") }.configureEach {
  dependsOn(downloadLibmpv, extractMpvLibcxx, prepareMpvFfmpegDevelopment)
}
// Gradle snapshots jniLibs source dirs before task execution; this keeps the
// extracted libmpv libc++ directory present during input discovery.
tasks.matching { it.name.startsWith("merge") && it.name.endsWith("JniLibFolders") }.configureEach {
  dependsOn(extractMpvLibcxx)
}

dependencies {
  implementation(files(File(mpvDir, mpvAar)))
  implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")

  // Android TV Watch Next integration
  implementation("androidx.tvprovider:tvprovider:1.1.0")

  // Periodic Watch Next background refresh (ShelfRefreshWorker). Same version
  // background_downloader pins, so the merged classpath stays coherent.
  implementation("androidx.work:work-runtime-ktx:2.11.0")

  // Media3 ExoPlayer for Android
  implementation("androidx.media3:media3-decoder:$media3Version")
  implementation("androidx.media3:media3-exoplayer:$media3Version")
  implementation("androidx.media3:media3-exoplayer-hls:$media3Version")
  implementation("androidx.media3:media3-ui:$media3Version")
  implementation("androidx.media3:media3-common:$media3Version")

  // Cronet for HTTP/2 multiplexing + better connection management
  implementation("androidx.media3:media3-datasource-cronet:$media3Version")
  implementation("org.chromium.net:cronet-embedded:143.7445.0")

  // Keeping libass in-project lets its static core share the app's native
  // packaging rules.
  implementation(project(":libass"))

  testImplementation("junit:junit:4.13.2")
  // Real android.util.* implementations for tests exercising media3 classes
  // (MatroskaExtractor uses SparseArray, which is a no-op stub on plain JVM)
  testImplementation("org.robolectric:robolectric:4.16.1")
  testImplementation("androidx.work:work-testing:2.11.0")
  androidTestImplementation("androidx.test:runner:1.7.0")
  androidTestImplementation("androidx.test.ext:junit:1.3.0")
}
