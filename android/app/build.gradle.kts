import java.io.FileInputStream
import java.net.URL
import java.util.Properties
import java.util.UUID
import java.util.zip.ZipFile
import org.gradle.api.file.RelativePath
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
  exclusiveContent {
    forRepository { maven { url = uri("https://jitpack.io") } }
    filter { includeGroup("com.github.cgutman") }
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
    if (metadata["schema_version"] != 1 ||
      metadata["engine_id"] != "plezyng-dv-fel-v1" ||
      metadata["ffmpeg_headers"] != "META-INF/plezyng-dv/ffmpeg-headers/"
    ) {
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
      "${headerPrefix}libswresample/swresample.h"
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
val qairtSdkRoot = providers.environmentVariable("QAIRT_SDK_ROOT").orNull
  ?.takeIf(String::isNotBlank)
  ?.let { File(it) }
val androidAnvilContextsRoot = providers.environmentVariable("PLEZY_ANVIL_CONTEXT_ROOT").orNull
  ?.takeIf(String::isNotBlank)
  ?.let { File(it) }
val androidLiteRtModelRoot = providers.environmentVariable("PLEZY_LITERT_MODEL_ROOT").orNull
  ?.takeIf(String::isNotBlank)
  ?.let { File(it) }
  ?: rootProject.file("../assets/motion_models/litert")
val androidLiteRtSamsungRuntimeRoot = providers.environmentVariable("PLEZY_LITERT_SAMSUNG_RUNTIME_ROOT").orNull
  ?.takeIf(String::isNotBlank)
  ?.let { File(it) }
val androidHtpVersions = listOf("V68", "V69", "V73", "V75", "V79", "V81")
val androidAnvilContextTargets = linkedMapOf(
  "sm7325" to "720p",
  "sm8350" to "720p",
  "sm8350p" to "720p",
  "sm7450" to "720p",
  "sm7475" to "720p",
  "sm8450" to "720p",
  "sm8475" to "720p",
  "sm8550" to "1080p",
  "sm8650" to "1080p",
  "sm8750" to "1080p",
  "sm8850" to "1080p"
)
val androidAnvilRuntimeDir = layout.buildDirectory.dir("plezy-anvil-runtime").get().asFile
val stageAndroidAnvilRuntime = tasks.register<Sync>("stageAndroidAnvilRuntime") {
  qairtSdkRoot?.let { sdk ->
    from(sdk.resolve("lib/aarch64-android")) {
      include("libQnnHtp.so", "libQnnSystem.so", "libQnnHtpPrepare.so")
      into("jniLibs/arm64-v8a")
    }
    androidHtpVersions.forEach { version ->
      from(sdk.resolve("lib/aarch64-android/libQnnHtp${version}Stub.so")) {
        into("jniLibs/arm64-v8a")
      }
      from(sdk.resolve("lib/hexagon-${version.lowercase()}/unsigned/libQnnHtp${version}Skel.so")) {
        into("assets/anvil/htp")
      }
    }
  }
  androidAnvilContextsRoot?.let { contextRoot ->
    from(contextRoot) {
      include("**/context.serialized.bin", "manifest.json")
      into("assets/anvil/contexts")
    }
  }
  into(androidAnvilRuntimeDir)
  onlyIf { qairtSdkRoot != null || androidAnvilContextsRoot != null }
  doFirst {
    val sdk = qairtSdkRoot ?: run {
      if (androidAnvilContextsRoot != null) {
        throw GradleException("PLEZY_ANVIL_CONTEXT_ROOT requires QAIRT_SDK_ROOT for the HTP runtime libraries")
      }
      return@doFirst
    }
    val required = listOf(
      sdk.resolve("include/QNN/QnnInterface.h"),
      sdk.resolve("lib/aarch64-android/libQnnHtp.so"),
      sdk.resolve("lib/aarch64-android/libQnnSystem.so"),
      sdk.resolve("lib/aarch64-android/libQnnHtpPrepare.so")
    ) + androidHtpVersions.flatMap { version ->
      listOf(
        sdk.resolve("lib/aarch64-android/libQnnHtp${version}Stub.so"),
        sdk.resolve("lib/hexagon-${version.lowercase()}/unsigned/libQnnHtp${version}Skel.so")
      )
    }
    val missing = required.filterNot(File::isFile)
    if (missing.isNotEmpty()) {
      throw GradleException("QAIRT SDK is incomplete for the Android ANVIL V68/V69/V73/V75/V79/V81 runtimes: ${missing.joinToString()}")
    }
    androidAnvilContextsRoot?.let { root ->
      val requiredContexts = androidAnvilContextTargets.flatMap { (soc, resolution) ->
        listOf("anvil-s-$resolution", "anvil-m-$resolution").map { model ->
          root.resolve("$soc/$model/context.serialized.bin")
        }
      }
      val missingContexts = requiredContexts.filterNot(File::isFile)
      if (missingContexts.isNotEmpty()) {
        throw GradleException("Android ANVIL context set is incomplete: ${missingContexts.joinToString()}")
      }
    }
  }
}

// LiteRT CompiledModel C API and the vendor plugins are pinned to one Maven
// release and checksum-verified before extraction. NPU runtimes remain
// optional at execution time; the APK carries the available provider plugins
// and LiteRT reports which accelerator actually compiled the graph.
val liteRtVersion = "2.3.0"
// Keep this Android runtime on the OpenVINO release pinned by LiteRT 2.3.0's
// third_party/intel_openvino/openvino_version.bzl. The LiteRT provider AAR
// contains the adapter but intentionally omits these OpenVINO runtime .so files.
val openVinoAndroidVersion = "2026.3.1"
val openVinoAndroidBuild = "22476.56d9685302d"
val openVinoAndroidArchive = "openvino-android-$openVinoAndroidVersion.tgz"
val openVinoAndroidRoot = "openvino_toolkit_android_$openVinoAndroidVersion.${openVinoAndroidBuild}_x86_64"
val androidLiteRtArtifactDir = layout.buildDirectory.dir("plezy-litert-downloads").get().asFile
val androidLiteRtRuntimeDir = layout.buildDirectory.dir("plezy-litert-runtime").get().asFile
val androidLiteRtModelAssetsDir = layout.buildDirectory.dir("plezy-litert-model-assets").get().asFile
val androidLiteRtArtifacts = linkedMapOf(
  "litert_cc_sdk.zip" to Pair(
    "https://github.com/google-ai-edge/LiteRT/releases/download/v$liteRtVersion/litert_cc_sdk.zip",
    "44ebb188ae1a510f233639fa499928fdaaba46436a153a2dbfbb9d87d59728d2"
  ),
  "litert-$liteRtVersion.aar" to Pair(
    "https://dl.google.com/dl/android/maven2/com/google/ai/edge/litert/litert/$liteRtVersion/litert-$liteRtVersion.aar",
    "9508c6e9142646f0f2bc1fe68b3925fb470ee7ddd29114540339a04a8ab189dc"
  ),
  "litert-gpu-$liteRtVersion.aar" to Pair(
    "https://dl.google.com/dl/android/maven2/com/google/ai/edge/litert/litert-gpu/$liteRtVersion/litert-gpu-$liteRtVersion.aar",
    "173a4c3813601f7e9542f4e6a49e237775e2f9ce1e0948f35407098bffb1824f"
  ),
  "litert-npu-runtime-qualcomm-$liteRtVersion.aar" to Pair(
    "https://dl.google.com/dl/android/maven2/com/google/ai/edge/litert/litert-npu-runtime-qualcomm/$liteRtVersion/litert-npu-runtime-qualcomm-$liteRtVersion.aar",
    "55aa22e89b7decb9e2f56548188b9e8c42cc8f7a828e2ec4a17715079b313679"
  ),
  "litert-npu-runtime-mediatek-$liteRtVersion.aar" to Pair(
    "https://dl.google.com/dl/android/maven2/com/google/ai/edge/litert/litert-npu-runtime-mediatek/$liteRtVersion/litert-npu-runtime-mediatek-$liteRtVersion.aar",
    "949fcd3a40d597f07473eb8d6b4d89ab6343b5a8fd2d21c118e2855e613c4587"
  ),
  "litert-npu-runtime-google-tensor-$liteRtVersion.aar" to Pair(
    "https://dl.google.com/dl/android/maven2/com/google/ai/edge/litert/litert-npu-runtime-google-tensor/$liteRtVersion/litert-npu-runtime-google-tensor-$liteRtVersion.aar",
    "5f38ab3de4b99ef75edf13c595cf0c090b10a82d9697f5b55703409757e786f7"
  ),
  "litert-npu-runtime-intel-openvino-$liteRtVersion.aar" to Pair(
    "https://dl.google.com/dl/android/maven2/com/google/ai/edge/litert/litert-npu-runtime-intel-openvino/$liteRtVersion/litert-npu-runtime-intel-openvino-$liteRtVersion.aar",
    "ea5eb69272b3579e6480b527cf1f8d1f1703f789df130fff34ea93997f674f93"
  ),
  openVinoAndroidArchive to Pair(
    "https://storage.openvinotoolkit.org/repositories/openvino/packages/$openVinoAndroidVersion/linux/openvino_toolkit_android_$openVinoAndroidVersion.${openVinoAndroidBuild}_x86_64.tgz",
    "757eb8140039c9060a9e2668dc3885ab0daf24fabe7adf71a8e9e81da148049c"
  )
)
val downloadAndroidLiteRtArtifacts = tasks.register("downloadAndroidLiteRtArtifacts") {
  outputs.files(androidLiteRtArtifacts.keys.map { File(androidLiteRtArtifactDir, it) })
  doLast {
    androidLiteRtArtifactDir.mkdirs()
    androidLiteRtArtifacts.forEach { (name, artifact) ->
      val (sourceUrl, expectedSha256) = artifact
      val destination = File(androidLiteRtArtifactDir, name)
      if (destination.isFile) {
        try {
          verifySha256(destination, expectedSha256, "LiteRT $name")
          return@forEach
        } catch (_: GradleException) {
          destination.delete()
        }
      }
      val partial = File(destination.parentFile, "${destination.name}.partial")
      try {
        URL(sourceUrl).openStream().use { input ->
          partial.outputStream().use { output -> input.copyTo(output) }
        }
        verifySha256(partial, expectedSha256, "LiteRT $name")
        if (!partial.renameTo(destination)) {
          throw GradleException("Could not promote downloaded LiteRT artifact $name")
        }
      } catch (error: Exception) {
        partial.delete()
        throw GradleException("Could not stage pinned LiteRT artifact $name", error)
      }
    }
  }
}
val stageAndroidLiteRtArtifacts = tasks.register<Sync>("stageAndroidLiteRtArtifacts") {
  dependsOn(downloadAndroidLiteRtArtifacts)
  from(provider { zipTree(File(androidLiteRtArtifactDir, "litert_cc_sdk.zip")) }) {
    include("litert_cc_sdk/litert/**")
    eachFile {
      relativePath = RelativePath(true, *relativePath.segments.drop(1).toTypedArray())
    }
    into("sdk/litert_cc_sdk")
  }
  androidLiteRtArtifacts.keys.filter { it.endsWith(".aar") }.forEach { aarName ->
    from(provider { zipTree(File(androidLiteRtArtifactDir, aarName)) }) {
      include("jni/**/*.so")
      exclude("jni/**/libc++_shared.so")
      eachFile {
        relativePath = RelativePath(true, *relativePath.segments.drop(1).toTypedArray())
      }
      into("jniLibs")
    }
  }
  from(
    provider {
      tarTree(resources.gzip(File(androidLiteRtArtifactDir, openVinoAndroidArchive)))
    }
  ) {
    include(
      "$openVinoAndroidRoot/runtime/lib/intel64/libopenvino.so",
      "$openVinoAndroidRoot/runtime/lib/intel64/libopenvino_intel_npu_plugin.so",
      "$openVinoAndroidRoot/runtime/lib/intel64/libopenvino_ir_frontend.so",
      "$openVinoAndroidRoot/runtime/lib/intel64/libopenvino_tensorflow_lite_frontend.so",
      "$openVinoAndroidRoot/runtime/3rdparty/tbb/lib/libtbb.so"
    )
    eachFile { relativePath = RelativePath(true, "x86_64", name) }
    into("jniLibs")
  }
  androidLiteRtSamsungRuntimeRoot?.let { runtimeRoot ->
    inputs.file(runtimeRoot.resolve("BUILD_INFO.txt"))
    inputs.file(runtimeRoot.resolve("SHA256SUMS"))
    from(runtimeRoot) {
      include(
        "arm64-v8a/libLiteRtCompilerPlugin_Samsung.so",
        "arm64-v8a/libLiteRtDispatch_Samsung.so"
      )
      into("jniLibs")
    }
    from(runtimeRoot.resolve("litecore")) {
      include("lib/arm64-v8a/*.so")
      into("assets/litert/samsung/litecore")
    }
    from(runtimeRoot) {
      include("BUILD_INFO.txt", "SHA256SUMS")
      into("assets/litert/samsung")
    }
  }
  includeEmptyDirs = false
  into(androidLiteRtRuntimeDir)
  doFirst {
    androidLiteRtSamsungRuntimeRoot?.let { runtimeRoot ->
      val required = listOf(
        runtimeRoot.resolve("arm64-v8a/libLiteRtCompilerPlugin_Samsung.so"),
        runtimeRoot.resolve("arm64-v8a/libLiteRtDispatch_Samsung.so"),
        runtimeRoot.resolve("litecore/lib/arm64-v8a/libgraph_wrapper.so"),
        runtimeRoot.resolve("litecore/lib/arm64-v8a/libgraphgen_api.so")
      )
      val missing = required.filterNot(File::isFile)
      val sdkLibraries = runtimeRoot.resolve("litecore/lib/arm64-v8a")
        .listFiles()
        ?.filter { it.isFile && it.name.endsWith(".so") }
        .orEmpty()
      if (missing.isNotEmpty() || sdkLibraries.size < 2) {
        throw GradleException(
          "PLEZY_LITERT_SAMSUNG_RUNTIME_ROOT must contain both LiteRT plugins and the LiteCore " +
            "Android runtime under litecore/lib/arm64-v8a; missing: ${missing.joinToString()}"
        )
      }
      val buildInfo = runtimeRoot.resolve("BUILD_INFO.txt")
      if (!buildInfo.isFile || !buildInfo.readText().contains("LiteRT source tag: v2.3.0")) {
        throw GradleException("Samsung runtime output must be built from LiteRT v2.3.0")
      }
      val checksums = runtimeRoot.resolve("SHA256SUMS")
      if (!checksums.isFile) {
        throw GradleException("Samsung runtime output is missing its SHA256SUMS file")
      }
      val expectedHashes = checksums.readLines().associate { line ->
        val match = Regex("^([0-9a-fA-F]{64})\\s+\\*?(.+)$").matchEntire(line)
          ?: throw GradleException("Samsung runtime SHA256SUMS has an invalid line: $line")
        match.groupValues[2].removePrefix("./") to match.groupValues[1]
      }
      (required + sdkLibraries).forEach { library ->
        val relativePath = runtimeRoot.toPath().relativize(library.toPath()).toString()
        val expectedHash = expectedHashes[relativePath]
          ?: throw GradleException("Samsung runtime SHA256SUMS has no entry for $relativePath")
        verifySha256(library, expectedHash, "Samsung runtime $relativePath")
      }
    }
  }
}
val stageAndroidLiteRtModels = tasks.register<Sync>("stageAndroidLiteRtModels") {
  androidLiteRtModelRoot?.let { root ->
    from(root) {
      include("manifest.json", "*.tflite")
      into("litert/models")
    }
  }
  onlyIf { androidLiteRtModelRoot != null }
  doFirst {
    val root = androidLiteRtModelRoot ?: return@doFirst
    val manifestFile = root.resolve("manifest.json")
    if (!manifestFile.isFile) throw GradleException("PLEZY_LITERT_MODEL_ROOT is missing manifest.json")
    @Suppress("UNCHECKED_CAST")
    val manifest = groovy.json.JsonSlurper().parse(manifestFile) as Map<String, Any?>

    @Suppress("UNCHECKED_CAST")
    val models = manifest["models"] as? Map<String, Map<String, Any?>>
      ?: throw GradleException("LiteRT model manifest has no models map")
    if (models.isEmpty()) throw GradleException("LiteRT model manifest contains no model packs")
    models.forEach { (modelId, modelEntry) ->
      @Suppress("UNCHECKED_CAST")
      val variants = modelEntry["variants"] as? Map<String, Map<String, Map<String, Any?>>>
        ?: throw GradleException("LiteRT model $modelId has no variants")
      variants.forEach { (resolution, providers) ->
        providers.forEach { (provider, record) ->
          val filename = record["file"] as? String
            ?: throw GradleException("LiteRT $modelId/$resolution/$provider has no filename")
          if (File(filename).name != filename || !filename.endsWith(".tflite")) {
            throw GradleException("LiteRT model filename is not a safe .tflite basename: $filename")
          }
          val modelFile = root.resolve(filename)
          val expectedBytes = (record["bytes"] as? Number)?.toLong()
            ?: throw GradleException("LiteRT model $filename has no byte count")
          if (!modelFile.isFile || modelFile.length() != expectedBytes) {
            throw GradleException("LiteRT model $filename is missing or has the wrong size")
          }
          val expectedSha256 = record["sha256"] as? String
            ?: throw GradleException("LiteRT model $filename has no SHA-256")
          verifySha256(modelFile, expectedSha256, "LiteRT model $filename")
        }
      }
    }
  }
  into(androidLiteRtModelAssetsDir)
}
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
          "libavcodec/avcodec.h",
          "libavcodec/mediacodec.h",
          "libavcodec/jni.h",
          "libavutil/avconfig.h",
          "libavutil/channel_layout.h",
          "libswresample/swresample.h"
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
          "-DMPV_FFMPEG_ROOT=${mpvFfmpegDevelopmentDir.absolutePath}",
          "-DLITERT_CC_SDK_ROOT=${File(androidLiteRtRuntimeDir, "sdk/litert_cc_sdk").absolutePath}",
          "-DLITERT_ANDROID_RUNTIME_ROOT=${File(androidLiteRtRuntimeDir, "jniLibs").absolutePath}"
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
    resources {
      // Bouncy Castle publishes the same license text in bcprov, bcpkix, and
      // bcutil. Keep one copy in the APK instead of dropping the notice.
      pickFirsts.add("META-INF/LICENSE.md")
    }
  }

  sourceSets {
    getByName("main") {
      // PROJECT-scope jniLibs merge ahead of subprojects/AARs, so dependency
      // order cannot accidentally select an older libc++ copy. The directory
      // is extractMpvNatives' output (the AAR's 16 KB-capable libc++), wired
      // below via the JniLibFolders dependency.
      jniLibs.srcDir(mpvLibcxxJniDir)
      jniLibs.srcDir(File(androidLiteRtRuntimeDir, "jniLibs"))
      assets.srcDir(androidLiteRtModelAssetsDir)
      assets.srcDir(File(androidLiteRtRuntimeDir, "assets"))
      // QAIRT files remain in the private SDK and are copied into this staged
      // tree only when QAIRT_SDK_ROOT is supplied by the build environment.
      if (qairtSdkRoot != null) {
        jniLibs.srcDir(File(androidAnvilRuntimeDir, "jniLibs"))
      }
      if (qairtSdkRoot != null || androidAnvilContextsRoot != null) {
        assets.srcDir(File(androidAnvilRuntimeDir, "assets"))
      }
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
  dependsOn(stageAndroidLiteRtArtifacts)
}

tasks.matching { it.name.startsWith("pre") && it.name.endsWith("Build") }.configureEach {
  dependsOn(prepareMpvFfmpegDevelopment)
}
// Gradle snapshots jniLibs source dirs before task execution; this keeps the
// extracted libc++ directory present during input discovery.
tasks.matching { it.name.startsWith("merge") && it.name.endsWith("JniLibFolders") }.configureEach {
  dependsOn(extractMpvNatives)
  dependsOn(stageAndroidAnvilRuntime)
  dependsOn(stageAndroidLiteRtArtifacts)
}
tasks.matching { it.name.startsWith("merge") && it.name.endsWith("Assets") }.configureEach {
  dependsOn(stageAndroidAnvilRuntime)
  dependsOn(stageAndroidLiteRtArtifacts)
  dependsOn(stageAndroidLiteRtModels)
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
  // ExoPlayer's GPU frame-effects pipeline (used for opt-in Lanczos upscaling).
  implementation("androidx.media3:media3-effect:$media3Version")
  implementation("androidx.media3:media3-ui:$media3Version")
  implementation("androidx.media3:media3-common:$media3Version")

  // Cronet for HTTP/2 multiplexing + better connection management
  implementation("androidx.media3:media3-datasource-cronet:$media3Version")
  implementation("org.chromium.net:cronet-embedded:500.1.0")

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
