import java.io.FileInputStream
import java.util.Properties
import java.util.UUID
import java.util.zip.ZipFile
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
  id("com.android.application")
  id("kotlin-android")
  // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
  id("dev.flutter.flutter-gradle-plugin")
}

apply(from = rootProject.file("gradle/native-artifacts.gradle.kts"))

@Suppress("UNCHECKED_CAST")
val verifySha256 = extra["verifySha256"] as (File, String, String) -> Unit

@Suppress("UNCHECKED_CAST")
val promoteDirectory = extra["promoteDirectory"] as (File, File) -> Unit

// mpv-build's mpv-android library (libmpv, FFmpeg, libc++ and the JNI glue
// with its Kotlin API, package com.edde746.mpv, one AAR), pinned in the
// repo-root mpv-build.lock.json: its key is the version, its sha256 the one
// Gradle's dependency verification checks (gradle/verification-metadata.xml,
// which scripts/set_native_revision.sh writes with the lock). Gradle fetches it
// from the GitHub release through an Ivy repository: no metadata, no
// authentication. The repository is this project's, not settings': every
// project here declares its own (root allprojects, the Flutter plugin), and
// Gradle then ignores the settings' repositories.
val mpvLockFile = rootProject.file("../mpv-build.lock.json")
val mpvAndroid = run {
  @Suppress("UNCHECKED_CAST")
  val lock = groovy.json.JsonSlurper().parse(mpvLockFile) as Map<String, Any?>
  @Suppress("UNCHECKED_CAST")
  ((lock["artifacts"] as? Map<String, Any?>)?.get("android") as? Map<String, Any?>)
    ?: throw GradleException("$mpvLockFile has no android group; run scripts/set_native_revision.sh")
}

@Suppress("UNCHECKED_CAST")
val mpvAar = mpvAndroid["aar"] as? Map<String, String>
  ?: throw GradleException("$mpvLockFile artifacts.android has no aar; run scripts/set_native_revision.sh")
val mpvVerificationFile = rootProject.file("gradle/verification-metadata.xml")
val allMpvAbis = listOf("arm64-v8a", "armeabi-v7a", "x86", "x86_64")
val requestedFelAbis = providers.gradleProperty("plezyngFelAbis").orNull?.split(',')?.map(String::trim)
  ?.also { abis ->
    if (abis.isEmpty() || abis.any { it !in allMpvAbis } || abis.distinct().size != abis.size) {
      throw GradleException("plezyngFelAbis must be a comma-separated subset of ${allMpvAbis.joinToString()}")
    }
  }
val mpvAbis = requestedFelAbis ?: allMpvAbis
if (!mpvVerificationFile.readText().contains("<sha256 value=\"${mpvAar.getValue("checksum")}\"")) {
  throw GradleException(
    "$mpvVerificationFile doesn't check mpv-android against $mpvLockFile's sha256; run scripts/set_native_revision.sh"
  )
}
repositories {
  exclusiveContent {
    forRepository {
      ivy {
        name = "mpv-build"
        url = uri(mpvAndroid.getValue("assetBase") as String)
        patternLayout { artifact("[artifact]-[revision].[ext]") }
        metadataSources { artifact() }
      }
    }
    filter { includeModule("edde746", "mpv-android") }
  }
}
// A locally built FEL AAR is selected only by an explicit Gradle property and
// a matching SHA-256. The Android app and Media3 share FFmpeg from this same
// archive, so swapping only libmpv cannot accidentally create an ABI split.
val felAarPath = providers.gradleProperty("plezyngFelAar").orNull
val felAarSha256 = providers.gradleProperty("plezyngFelAarSha256").orNull
if (requestedFelAbis != null && felAarPath == null) {
  throw GradleException("plezyngFelAbis requires an experimental FEL AAR")
}
if ((felAarPath == null) != (felAarSha256 == null)) {
  throw GradleException("Set both -PplezyngFelAar and -PplezyngFelAarSha256 for an experimental FEL build")
}
val felAarFile = felAarPath?.let { path ->
  val file = File(path).canonicalFile
  if (!file.isFile || file.extension != "aar") {
    throw GradleException("plezyngFelAar must name an existing .aar file: $file")
  }
  if (felAarSha256?.matches(Regex("[0-9a-fA-F]{64}")) != true) {
    throw GradleException("plezyngFelAarSha256 must be 64 hexadecimal digits")
  }
  verifySha256(file, felAarSha256, "experimental FEL AAR")
  val requiredEntries = buildSet {
    add("AndroidManifest.xml")
    add("classes.jar")
    add("META-INF/plezyng-dv-engine.json")
    for (abi in mpvAbis) {
      add("jni/$abi/libplayer.so")
      add("jni/$abi/libmpv.so")
      add("jni/$abi/libavcodec.so")
      add("jni/$abi/libavfilter.so")
      add("jni/$abi/libavformat.so")
      add("jni/$abi/libavutil.so")
      add("jni/$abi/libswscale.so")
      add("jni/$abi/libswresample.so")
      add("jni/$abi/libc++_shared.so")
    }
  }
  ZipFile(file).use { archive ->
    val missing = requiredEntries.filter { archive.getEntry(it) == null }
    if (missing.isNotEmpty()) {
      throw GradleException("Experimental FEL AAR is missing required player/Media3 ABI files: ${missing.joinToString()}")
    }
    val metadata = archive.getInputStream(archive.getEntry("META-INF/plezyng-dv-engine.json")).bufferedReader().use {
      groovy.json.JsonSlurper().parseText(it.readText()) as? Map<*, *>
    } ?: throw GradleException("Experimental FEL AAR has invalid engine metadata")
    if (metadata["schema_version"] != 1 || metadata["engine_id"] != "plezyng-dv-fel-v1" ||
      metadata["ffmpeg_headers"] != "META-INF/plezyng-dv/ffmpeg-headers/") {
      throw GradleException("Experimental FEL AAR metadata does not describe the paired engine and its matching FFmpeg headers")
    }
    val declaredAbis = (metadata["abis"] as? List<*>)?.filterIsInstance<String>()?.sorted()
    if (declaredAbis == null || !declaredAbis.containsAll(mpvAbis)) {
      throw GradleException("Experimental FEL AAR metadata does not cover requested app ABIs: ${mpvAbis.joinToString()}")
    }
    val headerPrefix = metadata["ffmpeg_headers"] as String
    val headerEntries = archive.entries().asSequence().map { it.name }
      .filter { it.startsWith(headerPrefix) && !it.endsWith("/") }.toSet()
    val requiredHeaders = setOf(
      "${headerPrefix}libavcodec/avcodec.h",
      "${headerPrefix}libavcodec/mediacodec.h",
      "${headerPrefix}libavcodec/jni.h",
      "${headerPrefix}libavutil/avconfig.h",
      "${headerPrefix}libavutil/channel_layout.h",
      "${headerPrefix}libswresample/swresample.h",
    )
    if (!headerEntries.containsAll(requiredHeaders)) {
      throw GradleException("Experimental FEL AAR is missing FFmpeg headers required by the shared Media3 bridge: ${(requiredHeaders - headerEntries).joinToString()}")
    }
  }
  file
}
// Preserve the newer generic local-AAR override already used by main. The
// FEL-specific override below adds metadata, shared-header and ABI checks.
val experimentalMpvAarPath = providers.gradleProperty("plezyExperimentalMpvAar").orNull
val experimentalMpvAarSha256 = providers.gradleProperty("plezyExperimentalMpvAarSha256").orNull
val experimentalMpvAar = when {
  experimentalMpvAarPath == null && experimentalMpvAarSha256 == null -> null
  experimentalMpvAarPath == null || experimentalMpvAarSha256 == null -> throw GradleException(
    "plezyExperimentalMpvAar and plezyExperimentalMpvAarSha256 must be supplied together"
  )
  else -> {
    if (!experimentalMpvAarSha256.matches(Regex("[0-9a-fA-F]{64}"))) {
      throw GradleException("plezyExperimentalMpvAarSha256 must be a 64-character SHA-256")
    }
    val file = project.file(experimentalMpvAarPath).canonicalFile
    if (!file.isFile) throw GradleException("Experimental mpv AAR does not exist: ${file.absolutePath}")
    verifySha256(file, experimentalMpvAarSha256.lowercase(), "experimental mpv-android AAR")
    file
  }
}
if (felAarPath != null && experimentalMpvAar != null) {
  throw GradleException("Choose either plezyngFelAar or plezyExperimentalMpvAar, not both")
}

// A local AAR must be wrapped as a Gradle file collection. Passing File
// directly is not valid dependency notation in the Kotlin DSL; the published
// Ivy module remains a coordinate as before.
val selectedLocalMpvAar = felAarFile ?: experimentalMpvAar
val mpvAarDependency: Any = selectedLocalMpvAar?.let { files(it) }
  ?: "edde746:mpv-android:${mpvAar.getValue("key")}@aar"
val mpvAarDependencyLabel = selectedLocalMpvAar?.absolutePath ?: mpvAarDependency.toString()

// The AAR's native libraries this build reads itself: the FFmpeg libraries the
// Media3 adapter links (CMake then packages those same bytes), and the libc++
// runtime libmpv was linked against, packaged at PROJECT scope below so it
// deterministically wins the merge over any older copy.
val mpvAarNatives = configurations.create("mpvAarNatives") {
  isCanBeConsumed = false
}
val mpvNativeDir = layout.buildDirectory.dir("mpv-android").get().asFile
val mpvFfmpegJniDir = File(mpvNativeDir, "ffmpeg/jni")
val mpvLibcxxJniDir = File(mpvNativeDir, "libcxx/jni")
val extractMpvNatives = tasks.register<Sync>("extractMpvNatives") {
  from(provider { zipTree(mpvAarNatives.singleFile) }) {
    include("jni/*/libavcodec.so", "jni/*/libavutil.so", "jni/*/libswresample.so")
    into("ffmpeg")
  }
  from(provider { zipTree(mpvAarNatives.singleFile) }) {
    include("jni/*/libc++_shared.so")
    into("libcxx")
  }
  into(mpvNativeDir)
  includeEmptyDirs = false
  doLast {
    val missing = mpvAbis.map { abi -> File(mpvLibcxxJniDir, "$abi/libc++_shared.so") }.filterNot(File::isFile)
    if (missing.isNotEmpty()) {
      throw GradleException("$mpvAarDependency carries no libc++ runtime for: ${missing.joinToString { it.parentFile.name }}")
    }
  }
}

val media3Version = "1.11.0"
val mpvFfmpegVersion = "8.0.1"
val mpvFfmpegSourceSha256 = "05ee0b03119b45c0bdb4df654b96802e909e0a752f72e4fe3794f487229e5a41"
val mpvFfmpegSourceUrl = "https://ffmpeg.org/releases/ffmpeg-$mpvFfmpegVersion.tar.xz"
val mpvFfmpegDevelopmentDir = layout.buildDirectory.dir("libmpv-ffmpeg-development").get().asFile

// Build the Media3 JNI adapter against the same shared FFmpeg libraries that
// libmpv packages. Headers are pinned to libmpv's FFmpeg version and remain
// build-only; the APK contains one FFmpeg implementation for both players.
// The AAR carries no headers, so they come from FFmpeg's release source: the
// Media3 adapter uses none of the declarations mpv-build's patches change
// (libavcodec/mediacodec.h, libavcodec/jni.h).
val prepareMpvFfmpegDevelopment = tasks.register("prepareMpvFfmpegDevelopment") {
  dependsOn(extractMpvNatives)
  val manifest = File(mpvFfmpegDevelopmentDir, ".manifest")
  val libraries = listOf("avcodec", "avutil", "swresample")
  inputs.dir(mpvFfmpegJniDir)
  if (felAarFile != null) {
    inputs.file(felAarFile)
  } else {
    inputs.property("ffmpegVersion", mpvFfmpegVersion)
    inputs.property("sourceUrl", mpvFfmpegSourceUrl)
    inputs.property("sourceSha256", mpvFfmpegSourceSha256)
  }
  outputs.files(
    mpvAbis.flatMap { abi ->
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
      val includeDir = File(staging, "include")
      val nativeDir = File(staging, "native")
      staging.mkdirs()
      val ffmpegIdentity: String
      if (felAarFile != null) {
        val headerPrefix = "META-INF/plezyng-dv/ffmpeg-headers/"
        val sourceCommit = ZipFile(felAarFile).use { archive ->
          val metadata = archive.getInputStream(archive.getEntry("META-INF/plezyng-dv-engine.json")).bufferedReader().use {
            groovy.json.JsonSlurper().parseText(it.readText()) as Map<*, *>
          }
          val sourceCommit = metadata["ffmpeg_commit"] as? String
            ?: throw GradleException("Experimental FEL AAR metadata has no FFmpeg source commit")
          archive.entries().asSequence()
            .filter { !it.isDirectory && it.name.startsWith(headerPrefix) }
            .forEach { entry ->
              val relative = entry.name.removePrefix(headerPrefix)
              if (relative.isBlank() || relative.split('/').any { it == ".." }) {
                throw GradleException("Experimental FEL AAR contains an unsafe FFmpeg header path")
              }
              val destination = File(includeDir, relative).canonicalFile
              if (!destination.toPath().startsWith(includeDir.canonicalFile.toPath())) {
                throw GradleException("Experimental FEL AAR FFmpeg header escapes its include directory")
              }
              destination.parentFile.mkdirs()
              archive.getInputStream(entry).use { input ->
                destination.outputStream().use { output -> input.copyTo(output) }
              }
            }
          sourceCommit
        }
        val requiredHeaders = listOf(
          "libavcodec/avcodec.h", "libavcodec/mediacodec.h", "libavcodec/jni.h",
          "libavutil/avconfig.h", "libavutil/channel_layout.h", "libswresample/swresample.h"
        )
        val missingHeaders = requiredHeaders.map { File(includeDir, it) }.filterNot(File::isFile)
        if (missingHeaders.isNotEmpty()) {
          throw GradleException("Experimental FEL AAR is missing matching FFmpeg headers: ${missingHeaders.joinToString()}")
        }
        ffmpegIdentity = sourceCommit
      } else {
        val sourceArchive = File(staging, "ffmpeg-$mpvFfmpegVersion.tar.xz")
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
              "--no-same-owner",
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
        sourceArchive.delete()
        extractedSource.deleteRecursively()
        ffmpegIdentity = "$mpvFfmpegVersion:$mpvFfmpegSourceSha256"
      }

      project.copy {
        from(mpvFfmpegJniDir) {
          include(libraries.map { library -> "*/lib$library.so" })
        }
        includeEmptyDirs = false
        into(nativeDir)
      }

      val missing = mpvAbis.flatMap { abi ->
        libraries.map { library -> File(nativeDir, "$abi/lib$library.so") }
      }.filterNot(File::isFile)
      if (missing.isNotEmpty()) {
        throw GradleException(
          "$mpvAarDependency is missing FFmpeg libraries: ${missing.joinToString { it.relativeTo(staging).path }}"
        )
      }
      File(staging, ".manifest").writeText(
        "ffmpeg=$ffmpegIdentity\n"
      )
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
// A local engine AAR may intentionally contain only the ABI being qualified.
// Download and validate just the matching libdovi archive for that build.
val requiredDoviArtifacts = if (felAarFile != null) {
  doviArtifacts.filterKeys { it in mpvAbis }
} else {
  doviArtifacts
}
val doviBaseUrl = "https://github.com/edde746/libdovi-builds/releases/download/v$doviVersion"

val downloadLibdovi = tasks.register("downloadLibdovi") {
  val manifest = File(doviDir, ".manifest")
  inputs.property("version", doviVersion)
  inputs.property("baseUrl", doviBaseUrl)
  requiredDoviArtifacts.forEach { (abi, artifact) ->
    inputs.property("$abi.triple", artifact.first)
    inputs.property("$abi.sha256", artifact.second)
    inputs.property("$abi.sourceUrl", "$doviBaseUrl/libdovi-${artifact.first}.tar.gz")
  }
  outputs.files(requiredDoviArtifacts.keys.map { abi -> File(doviDir, "$abi/lib/libdovi.a") } + manifest)
  doLast {
    doviDir.parentFile.mkdirs()
    val staging = File(doviDir.parentFile, "${doviDir.name}.staging-${UUID.randomUUID()}")
    try {
      staging.mkdirs()
      val downloads = File(staging, ".downloads").apply { mkdirs() }
      requiredDoviArtifacts.forEach { (abi, artifact) ->
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
            // Release archives preserve the packager's uid/gid. This build
            // runs unprivileged on CI and in development containers, where
            // restoring those owners makes GNU tar exit nonzero.
            commandLine("tar", "-xzf", archive.absolutePath, "--no-same-owner", "-C", outDir.absolutePath)
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
        requiredDoviArtifacts.forEach { (abi, artifact) ->
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
  // permission_handler_android uses Android 17 API constants.
  compileSdk = 37
  buildToolsVersion = "36.1.0"
  ndkVersion = "29.0.14206865"

  // Android Automotive OS driver-distraction state (CarUxRestrictionsManager). This is a platform
  // stub, not a shipped dependency: the classes exist only on AAOS images, so every use is guarded
  // by FEATURE_AUTOMOTIVE and the manifest declares `uses-library android.car required=false`.
  useLibrary("android.car")

  buildFeatures {
    buildConfig = true
  }

  compileOptions {
    isCoreLibraryDesugaringEnabled = true
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
  }

  defaultConfig {
    applicationId = "org.snapetech.plezyng"
    if (felAarFile != null) {
      // Keep experimental native builds installable beside the signed app.
      // This avoids asking testers to uninstall their normal client and lose
      // its local state just to try a locally built FEL engine.
      applicationIdSuffix = ".dvfel"
      versionNameSuffix = "-dvfel"
    }
    minSdk = 25 // Fire OS 6.x (API 25); the mpv-android AAR shares the same floor
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
    testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    buildConfigField("boolean", "PLEZYNG_DV_FEL_EXPERIMENTAL", if (felAarFile != null) "true" else "false")

    if (felAarFile != null) {
      ndk {
        abiFilters.clear()
        abiFilters += mpvAbis
      }
    }

    externalNativeBuild {
      cmake {
        arguments += listOf(
          "-DDOVI_ENABLE_LIBDOVI=ON",
          "-DDOVI_LIBDOVI_PREBUILT_ROOT=${doviDir.absolutePath}",
          "-DMPV_FFMPEG_ROOT=${mpvFfmpegDevelopmentDir.absolutePath}"
        )
      }
    }

    if (System.getenv("AMAZON") != null && felAarFile == null) {
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
      // sourceSets rule below makes the runtime the mpv-android AAR carries
      // (the one libmpv was linked against) win for std::from_chars<float>,
      // while older native consumers remain ABI-compatible.
      pickFirsts.add("lib/*/libc++_shared.so")
    }
  }

  sourceSets {
    getByName("main") {
      // PROJECT-scope jniLibs merge ahead of subprojects/AARs, so dependency
      // order cannot accidentally select an older libc++ copy. The directory
      // is extractMpvNatives' output (the AAR's 16 KB-capable libc++), wired
      // below via the JniLibFolders dependency.
      jniLibs.srcDir(mpvLibcxxJniDir)
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
  dependsOn(prepareMpvFfmpegDevelopment)
}
// Gradle snapshots jniLibs source dirs before task execution; this keeps the
// extracted libc++ directory present during input discovery.
tasks.matching { it.name.startsWith("merge") && it.name.endsWith("JniLibFolders") }.configureEach {
  dependsOn(extractMpvNatives)
}

dependencies {
  coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

  // mpv-build's mpv-android library: libmpv, FFmpeg and the JNI glue with
  // its Kotlin API (com.edde746.mpv).
  implementation(mpvAarDependency)
  mpvAarNatives(mpvAarDependency)
  implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")

  // Android TV Watch Next integration
  implementation("androidx.tvprovider:tvprovider:1.1.0")

  // Only used to cancel the legacy periodic shelf refresh job (2.13.0's
  // removed ShelfRefreshWorker) that WorkManager persisted on updated
  // devices. Same version background_downloader pins, so the merged
  // classpath stays coherent.
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
