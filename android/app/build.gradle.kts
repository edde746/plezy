import java.io.FileInputStream
import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
  id("com.android.application")
  id("kotlin-android")
  // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
  id("dev.flutter.flutter-gradle-plugin")
}

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
val mpvAarDependency = "edde746:mpv-android:${mpvAar.getValue("key")}@aar"

// The AAR's native library this build reads itself: the libc++ runtime libmpv
// was linked against, packaged at PROJECT scope below so it deterministically
// wins the merge over any older copy.
val mpvAarNatives = configurations.create("mpvAarNatives") {
  isCanBeConsumed = false
}
val mpvNativeDir = layout.buildDirectory.dir("mpv-android").get().asFile
val mpvLibcxxJniDir = File(mpvNativeDir, "libcxx/jni")
val mpvAbis = listOf("arm64-v8a", "armeabi-v7a", "x86", "x86_64")
val extractMpvNatives = tasks.register<Sync>("extractMpvNatives") {
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
    minSdk = 25 // Fire OS 6.x (API 25); the mpv-android AAR shares the same floor
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
    testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

    if (System.getenv("AMAZON") != null) {
      versionCode = (flutter.versionCode ?: 0) + 3000
      ndk {
        abiFilters += listOf("armeabi-v7a", "arm64-v8a")
      }
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
    // #1703 shipped that way: a Class.forName lookup failed in release builds only.
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
  // androidTest, and the playback device suites need the debug-only
  // MpvLifecycleTestActivity, so they stay on debug.
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

// Gradle snapshots jniLibs source dirs before task execution; this keeps the
// extracted libc++ directory present during input discovery.
tasks.matching { it.name.startsWith("merge") && it.name.endsWith("JniLibFolders") }.configureEach {
  dependsOn(extractMpvNatives)
}

dependencies {
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

  // MpvPlaceholderSurface's EGLSurfaceTexture and the audio constants MpvAudioOutputPolicy uses.
  implementation("androidx.media3:media3-common:$media3Version")
  // Only for AudioCapabilities, which MpvAudioOutputPolicy reads to gate mpv's audio-spdif list.
  implementation("androidx.media3:media3-exoplayer:$media3Version")

  testImplementation("junit:junit:4.13.2")
  // Real Android framework implementations (activities, the main looper) for JVM tests
  testImplementation("org.robolectric:robolectric:4.16.1")
  testImplementation("androidx.work:work-testing:2.11.0")
  androidTestImplementation("androidx.test:runner:1.7.0")
  androidTestImplementation("androidx.test.ext:junit:1.3.0")
}
