import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.security.MessageDigest
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

// mpv Kotlin API + JNI glue built in-project (imported from the libmpv-android
// fork, commit e60c3ba); the external dependency is reduced to prebuilt native
// trees carried by the mpv-build per-ABI tarballs pinned below.
plugins {
  id("com.android.library")
  id("org.jetbrains.kotlin.android")
}

// Single source for the pinned native artifacts: the repo-root
// mpv-build.lock.json (github.com/edde746/mpv-build release assets + sha256
// checksums). This module downloads and extracts them; app/build.gradle.kts
// reads FFmpeg .so files and the libc++ runtime back out of the extracted
// trees.
val mpvAbis = listOf("arm64-v8a", "armeabi-v7a", "x86", "x86_64")
val mpvLockFile = rootProject.file("../mpv-build.lock.json")
val mpvLockAndroid = run {
  @Suppress("UNCHECKED_CAST")
  val lock = groovy.json.JsonSlurper().parse(mpvLockFile) as Map<String, Any?>
  @Suppress("UNCHECKED_CAST")
  ((lock["artifacts"] as? Map<String, Any?>)?.get("android") as? Map<String, Any?>)
    ?: throw GradleException("$mpvLockFile has no artifacts.android section")
}
val mpvKey = mpvLockAndroid["key"] as? String
  ?: throw GradleException("$mpvLockFile artifacts.android.key is missing")
val mpvAssetBase = mpvLockAndroid["assetBase"] as? String
  ?: throw GradleException("$mpvLockFile artifacts.android.assetBase is missing")

@Suppress("UNCHECKED_CAST")
val mpvAssets = (mpvLockAndroid["assets"] as? Map<String, Map<String, String>>).let { assets ->
  val missing = mpvAbis.filter { assets?.get(it)?.get("asset").isNullOrEmpty() || assets?.get(it)?.get("checksum").isNullOrEmpty() }
  if (assets == null || missing.isNotEmpty()) {
    throw GradleException("$mpvLockFile artifacts.android.assets lacks asset+checksum for: ${missing.joinToString()}")
  }
  assets
}

val mpvDir = layout.buildDirectory.dir("libmpv").get().asFile
val mpvArchivesDir = File(mpvDir, "archives")
val mpvNativeDir = File(mpvDir, "native")
val mpvLibcxxDir = File(mpvDir, "libcxx")

// Downloaded archives are renamed to a key-independent name so a lock bump
// (new key) changes task inputs, not the output file set.
fun stagedArchiveName(abi: String) = "libmpv-android-$abi.tar.gz"

// Dev-only escape hatch: point the build at a directory of locally built
// mpv-build android tarballs (platforms/android output, one
// libmpv-android-<key>-<abi>.tar.gz per ABI) to test changes before a lock
// bump. Checksums are skipped for local archives; the lock stays
// authoritative otherwise.
val localMpvDir: String? = (project.findProperty("plezy.localMpvDir") as String?)
  ?: System.getenv("PLEZY_LOCAL_MPV_DIR")

fun localArchive(abi: String): File {
  val dir = File(localMpvDir!!)
  val exact = File(dir, mpvAssets.getValue(abi).getValue("asset"))
  if (exact.isFile) return exact
  val pattern = Regex("libmpv-android-.+-${Regex.escape(abi)}\\.tar\\.gz")
  val matches = dir.listFiles()?.filter { it.isFile && pattern.matches(it.name) }.orEmpty()
  return matches.singleOrNull() ?: throw GradleException(
    "PLEZY_LOCAL_MPV_DIR=$localMpvDir must contain exactly one libmpv-android-*-$abi.tar.gz, found ${matches.size}"
  )
}

val downloadLibmpv = tasks.register("downloadLibmpv") {
  val manifest = File(mpvArchivesDir, ".manifest")
  inputs.file(mpvLockFile)
  inputs.property("localOverride", localMpvDir ?: "")
  if (localMpvDir != null) mpvAbis.forEach { abi -> inputs.file(localArchive(abi)) }
  outputs.files(mpvAbis.map { File(mpvArchivesDir, stagedArchiveName(it)) } + manifest)
  doLast {
    mpvDir.mkdirs()
    val staging = File(mpvDir, "archives.staging-${UUID.randomUUID()}")
    try {
      staging.mkdirs()
      val manifestText = StringBuilder()
      mpvAbis.forEach { abi ->
        val staged = File(staging, stagedArchiveName(abi))
        if (localMpvDir != null) {
          val source = localArchive(abi)
          source.copyTo(staged, overwrite = true)
          manifestText.append("$abi=local:${source.absolutePath}\n")
        } else {
          val asset = mpvAssets.getValue(abi).getValue("asset")
          val checksum = mpvAssets.getValue(abi).getValue("checksum")
          try {
            providers.exec {
              commandLine("curl", "-sfL", "$mpvAssetBase/$asset", "-o", staged.absolutePath)
            }.result.get().assertNormalExitValue()
          } catch (error: Exception) {
            throw GradleException("Failed to download $asset (mpv-build $mpvKey)", error)
          }
          verifySha256(staged, checksum, "$asset (mpv-build $mpvKey)")
          manifestText.append("$abi=$asset sha256=$checksum\n")
        }
      }
      File(staging, ".manifest").writeText(manifestText.toString())
      promoteDirectory(staging, mpvArchivesDir)
    } finally {
      staging.deleteRecursively()
    }
  }
}

// Each tarball is a native tree: lib/*.so (libmpv, seven FFmpeg libraries,
// libc++_shared) + include/mpv/*.h. The .so files land in the per-ABI jniLibs
// layout under native/jni, the headers under native/include for the CMake
// glue build, and libc++ in a separate tree that the app packages at PROJECT
// scope so the tarball's 16 KB-capable runtime deterministically wins the
// merge (see app/build.gradle.kts packaging { jniLibs } + sourceSets).
val extractLibmpvNative = tasks.register("extractLibmpvNative") {
  dependsOn(downloadLibmpv)
  inputs.files(mpvAbis.map { File(mpvArchivesDir, stagedArchiveName(it)) })
  outputs.dir(mpvNativeDir)
  outputs.dir(mpvLibcxxDir)
  doLast {
    val nativeStaging = File(mpvDir, "native.staging-${UUID.randomUUID()}")
    val libcxxStaging = File(mpvDir, "libcxx.staging-${UUID.randomUUID()}")
    val unpackRoot = File(mpvDir, "unpack-${UUID.randomUUID()}")
    try {
      mpvAbis.forEach { abi ->
        val unpack = File(unpackRoot, abi).apply { mkdirs() }
        providers.exec {
          commandLine(
            "tar",
            "-xzf",
            File(mpvArchivesDir, stagedArchiveName(abi)).absolutePath,
            "-C",
            unpack.absolutePath
          )
        }.result.get().assertNormalExitValue()
        val jniDir = File(nativeStaging, "jni/$abi")
        File(unpack, "lib").listFiles()?.filter { it.isFile && it.name.endsWith(".so") }?.forEach { so ->
          val target = if (so.name == "libc++_shared.so") {
            File(libcxxStaging, "jni/$abi/${so.name}")
          } else {
            File(jniDir, so.name)
          }
          target.parentFile.mkdirs()
          Files.move(so.toPath(), target.toPath())
        }
        // Headers are identical across ABIs; keep the first archive's copy.
        val include = File(unpack, "include")
        val includeTarget = File(nativeStaging, "include")
        if (!includeTarget.exists() && include.isDirectory) {
          include.copyRecursively(includeTarget)
        }
      }
      val missing = buildList {
        mpvAbis.forEach { abi ->
          if (!File(nativeStaging, "jni/$abi/libmpv.so").isFile) add("native/jni/$abi/libmpv.so")
          if (!File(nativeStaging, "jni/$abi/libavcodec.so").isFile) add("native/jni/$abi/libavcodec.so")
          if (!File(libcxxStaging, "jni/$abi/libc++_shared.so").isFile) add("libcxx/jni/$abi/libc++_shared.so")
        }
        if (!File(nativeStaging, "include/mpv/client.h").isFile) add("native/include/mpv/client.h")
      }
      if (missing.isNotEmpty()) {
        throw GradleException(
          "mpv-build $mpvKey android archives are missing expected entries: ${missing.joinToString()}"
        )
      }
      promoteDirectory(nativeStaging, mpvNativeDir)
      promoteDirectory(libcxxStaging, mpvLibcxxDir)
    } finally {
      nativeStaging.deleteRecursively()
      libcxxStaging.deleteRecursively()
      unpackRoot.deleteRecursively()
    }
  }
}

android {
  namespace = "com.edde746.plezy.libmpv"
  compileSdk = 36
  // Matches the app's latest stable NDK so every project-owned native library
  // is built with the same 16 KB page-size-capable libc++ toolchain. That copy
  // is NOT what ships: the app packages the mpv-build tarball's newer copy with
  // top merge priority (see app/build.gradle.kts packaging { jniLibs } + sourceSets).
  ndkVersion = "29.0.14206865"

  defaultConfig {
    // Fire OS 6.x (API 25), same floor as the app. The fork declared 26, but
    // nothing in this API or glue uses anything above 25.
    minSdk = 25
    consumerProguardFiles("consumer-rules.pro")
    externalNativeBuild {
      cmake {
        arguments += listOf(
          "-DANDROID_STL=c++_shared",
          "-DMPV_PREBUILT_ROOT=${mpvNativeDir.absolutePath}"
        )
        cFlags += "-Werror"
        cppFlags += "-std=c++11"
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

  sourceSets {
    getByName("main") {
      // Prebuilt libmpv + FFmpeg .so files extracted from the mpv-build tarballs;
      // the glue libplayer.so comes from the CMake build above.
      jniLibs.srcDir(File(mpvNativeDir, "jni"))
    }
  }
}

kotlin {
  compilerOptions {
    jvmTarget.set(JvmTarget.JVM_17)
  }
}

// The imported libmpv.so/libavcodec.so must exist before CMake links the glue.
tasks.matching { it.name.contains("CMake") || it.name.contains("externalNative") }.configureEach {
  dependsOn(extractLibmpvNative)
}
// Gradle snapshots jniLibs source dirs before task execution; this keeps the
// extracted prebuilt directory present during input discovery.
tasks.matching { it.name.startsWith("merge") && it.name.endsWith("JniLibFolders") }.configureEach {
  dependsOn(extractLibmpvNative)
}
tasks.matching { it.name.startsWith("pre") && it.name.endsWith("Build") }.configureEach {
  dependsOn(extractLibmpvNative)
}

dependencies {
  // Same version the app pins; MpvPlayer's public flows compile against it.
  implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
}
