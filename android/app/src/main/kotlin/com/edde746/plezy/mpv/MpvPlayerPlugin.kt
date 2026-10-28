package com.edde746.plezy.mpv

import android.app.Activity
import android.app.ActivityManager
import android.content.ComponentCallbacks2
import android.content.Context
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.PowerManager
import android.util.Log
import com.edde746.plezy.exoplayer.supportedMpvSpdifCodecs
import com.edde746.plezy.shared.PlayerChannelBinding
import com.edde746.plezy.shared.PlayerDebugLog
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.security.MessageDigest
import java.util.concurrent.CancellationException
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.atomic.AtomicBoolean
import java.util.zip.ZipFile

private const val LITERT_RUNTIME_VERSION = "2.3.0"
private val LITERT_OPENVINO_RUNTIME_LIBRARIES = listOf(
  "libopenvino.so",
  "libopenvino_intel_npu_plugin.so",
  "libopenvino_ir_frontend.so",
  "libopenvino_tensorflow_lite_frontend.so",
  "libtbb.so"
)
private const val LITERT_SAMSUNG_LITECORE_ASSET_DIR = "litert/samsung/litecore/lib/arm64-v8a"
private const val LITERT_SAMSUNG_MANIFEST_ASSET = "litert/samsung/SHA256SUMS"
private val LITERT_SAMSUNG_LITECORE_REQUIRED_LIBRARIES = setOf(
  "libgraph_wrapper.so",
  "libgraphgen_api.so"
)

/**
 * [failureDetails] travels as the error's `details`; the message stays fixed so
 * nothing a failure carried (possibly the value written) reaches Dart. See
 * [mpvPropertyFailureDetails].
 */
internal fun completeMpvPropertyResult(
  result: MethodChannel.Result,
  outcome: Result<Unit>,
  successValue: Any? = null,
  failureDetails: Map<String, Any>? = null
) {
  val failure = outcome.exceptionOrNull()
  when {
    failure == null -> result.success(successValue)
    failure is CancellationException -> completeMpvPropertyNotInitialized(result)
    else -> result.error("SET_PROPERTY_FAILED", "MPV property write was rejected", failureDetails)
  }
}

internal fun completeMpvPropertyNotInitialized(result: MethodChannel.Result) {
  result.error("NOT_INITIALIZED", "Player not initialized", null)
}

/**
 * Channel plumbing for [MpvPlayerCore]. The default instance is the video
 * player; the [audioOnly] instance (see [MpvAudioPlayerPlugin]) drives the
 * dedicated music core on its own channel pair with two lifecycle
 * differences:
 * - the core is built on the application context, not the Activity, so
 *   background music playback survives activity teardown — it is only
 *   disposed on explicit Dart `dispose` or engine detach, never in
 *   [onDetachedFromActivity];
 * - all video-only surface work is skipped inside the core.
 */
open class MpvPlayerPlugin(
  private val channelBase: String = "com.plezy/mpv_player",
  private val audioOnly: Boolean = false
) : FlutterPlugin,
  MethodChannel.MethodCallHandler,
  EventChannel.StreamHandler,
  ActivityAware,
  com.edde746.plezy.shared.PlayerDelegate {

  private val tag = if (audioOnly) "MpvAudioPlayerPlugin" else "MpvPlayerPlugin"
  private val motionRuntimeExecutor = Executors.newSingleThreadExecutor { task ->
    Thread(task, "$tag-motion-runtime").apply { isDaemon = true }
  }

  private data class AndroidHtpTarget(
    val socModel: String,
    val version: String,
    val socId: Int,
    val resolution: String
  ) {
    val architecture: String get() = version.lowercase()
    val stubLibrary: String get() = "libQnnHtp${version}Stub.so"
    val skelLibrary: String get() = "libQnnHtp${version}Skel.so"
  }

  // Qualcomm's supported-device table supplies the exact HTP architecture and
  // SoC ID used for context preparation. ANVIL has measured SM8650, SM8550,
  // and SM7475; the same fixed-shape context path also covers the other
  // documented mobile targets below. Contexts remain keyed by exact SoC.
  private val androidHtpTargets = mapOf(
    "SM8850" to AndroidHtpTarget("SM8850", "V81", 87, "1080p"),
    "SM8750" to AndroidHtpTarget("SM8750", "V79", 69, "1080p"),
    "SM8650" to AndroidHtpTarget("SM8650", "V75", 57, "1080p"),
    "SM8550" to AndroidHtpTarget("SM8550", "V73", 43, "1080p"),
    "SM8475" to AndroidHtpTarget("SM8475", "V69", 42, "720p"),
    "SM8450" to AndroidHtpTarget("SM8450", "V69", 36, "720p"),
    "SM7475" to AndroidHtpTarget("SM7475", "V69", 41, "720p"),
    "SM7450" to AndroidHtpTarget("SM7450", "V69", 41, "720p"),
    "SM8350P" to AndroidHtpTarget("SM8350P", "V68", 30, "720p"),
    "SM8350" to AndroidHtpTarget("SM8350", "V68", 30, "720p"),
    "SM7325" to AndroidHtpTarget("SM7325", "V68", 35, "720p")
  )

  private val channels = PlayerChannelBinding(channelBase, this, this, tag)
  private var playerCore: MpvPlayerCore? = null
  private var textureRegistry: io.flutter.view.TextureRegistry? = null
  private var visualizer: MilkRustVisualizer? = null
  private var visualizerSessionId = 0L
  private var audioFocusEnabled = true
  private var activity: Activity? = null
  private var activityBinding: ActivityPluginBinding? = null
  private var applicationContext: Context? = null
  private val nameToId = mutableMapOf<String, Int>()
  private var sessionGeneration = 0

  // The Dart instanceId that created the current core. A `dispose` carrying a
  // different token lost the ownership race to a successor and must not tear
  // down that successor's core; it is acknowledged without touching anything.
  private var coreInstanceId: Long? = null

  // How long a Dart `dispose` waits for native teardown before being
  // acknowledged. Native lifecycle operations remain serialized on background
  // workers after the watchdog fires, so a successor cannot overlap a stuck
  // decoder, exhaust codec instances, or block Android's main thread.
  private val disposeWatchdogMs = 6_000L

  // How long an `initialize` waits for the core's callback before its
  // pending callers are answered. Initialization runs three sequential
  // operation-queue calls (placeholder EGL setup, the native create, the
  // internal property observation), each bounded at 6s, so an attempt that
  // can still succeed has 18s of headroom; anything shorter would report
  // failure for a slow init that was about to complete. Beyond that the
  // callback is the core's only signal, and a lost one (a worker killed by
  // an Error never completes its awaited operation) has nothing else to
  // settle the Dart future.
  private val initWatchdogMs = 20_000L

  // Test seams, mirroring ExoPlayerPlugin.createMpvCore/initializeMpvCore:
  // MpvPlayer's companion loads libmpv, so substituting both is the only way
  // a JVM test can drive this plugin's initialization path.
  internal var createCore: (Context, Boolean, Float, String, Boolean) -> MpvPlayerCore =
    { context, hardwareDecoding, subtitleRenderScale, logLevel, experimentalDolbyVision ->
      MpvPlayerCore(context, audioOnly, hardwareDecoding, subtitleRenderScale, logLevel, experimentalDolbyVision)
    }
  internal var initializeCore: (MpvPlayerCore, (Boolean) -> Unit) -> Unit = { core, onInitialized ->
    core.initialize(onInitialized)
  }

  /** Same semantics as Activity.runOnUiThread, without needing an Activity. */
  private fun runOnMain(block: () -> Unit) = channels.runOnMain(block)

  /**
   * LiteRT/QNN capability discovery and model/runtime staging read APKs,
   * hash model packs, and copy native libraries. Keep that IO away from the
   * platform thread; serialize it so concurrent Neural requests cannot race
   * while promoting the same app-private files. Flutter channel replies are
   * marshaled back to the platform thread.
   */
  private fun executeMotionRuntimePreparation(
    result: MethodChannel.Result,
    operation: (MethodChannel.Result) -> Unit
  ) {
    val mainThreadResult = object : MethodChannel.Result {
      private val completed = AtomicBoolean(false)

      private fun complete(reply: () -> Unit) {
        if (completed.compareAndSet(false, true)) runOnMain(reply)
      }

      override fun success(value: Any?) = complete { result.success(value) }

      override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) = complete { result.error(errorCode, errorMessage, errorDetails) }

      override fun notImplemented() = complete { result.notImplemented() }
    }

    try {
      motionRuntimeExecutor.execute {
        try {
          operation(mainThreadResult)
        } catch (error: Exception) {
          Log.w(tag, "Android motion runtime preparation failed", error)
          mainThreadResult.error(
            "MOTION_RUNTIME_PREPARE_FAILED",
            "Android motion runtime preparation failed",
            null
          )
        }
      }
    } catch (_: RejectedExecutionException) {
      result.error("MOTION_RUNTIME_UNAVAILABLE", "Android motion runtime is shutting down", null)
    }
  }

  // Pending `MethodChannel.Result`s for an init that is currently in flight.
  // Concurrent `invoke('initialize')` calls share the same outcome instead
  // of each tearing down the in-flight core and starting their own — which
  // was the root cause of #930.
  private val pendingInitResults = mutableListOf<MethodChannel.Result>()

  @Volatile private var isInitializing = false
  private var initAttemptCounter = 0
  private var activeInitAttempt: Int? = null

  /**
   * Android memory pressure, forwarded to whichever core this instance owns.
   *
   * Registered on the *application* context rather than the Activity, and
   * from the base class so both instances get one: the audio-only core
   * deliberately outlives the activity (background music), which is exactly
   * the case where handing native buffers back matters most. Both plugin
   * instances are separate registrations on the same engine
   * ([MpvAudioPlayerPlugin] is a distinct class for that reason), so each
   * callback only ever touches its own core.
   */
  private val memoryCallbacks = object : ComponentCallbacks2 {
    override fun onTrimMemory(level: Int) {
      playerCore?.onTrimMemory(level)
    }

    override fun onConfigurationChanged(newConfig: Configuration) {}

    @Deprecated("Never called since API 34; kept because ComponentCallbacks requires it.")
    override fun onLowMemory() {
      // Deliberately not TRIM_MEMORY_COMPLETE: this says the *device* is low,
      // not that this process is the problem, and the 1-2 GB TV boxes that
      // still deliver it do so routinely mid-4K-playback (#2314). They also
      // deliver TRIM_MEMORY_RUNNING_CRITICAL when this process is what has to
      // give, so only the back cache goes here.
      playerCore?.onTrimMemory(ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW)
    }
  }

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    textureRegistry = binding.textureRegistry
    applicationContext = binding.applicationContext
    binding.applicationContext.registerComponentCallbacks(memoryCallbacks)
    channels.attach(binding)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    // Engine detach is terminal for both video and audio plugin instances.
    // Dispose before detaching channels so no native work can publish into a
    // dead messenger.
    binding.applicationContext.unregisterComponentCallbacks(memoryCallbacks)
    disposeCoreForTeardown()
    motionRuntimeExecutor.shutdown()
    activity = null
    activityBinding = null
    applicationContext = null
    textureRegistry = null
    channels.detach()
  }

  private fun takeCoreForTeardown(): MpvPlayerCore? {
    disposeVisualizer()
    ++sessionGeneration
    val core = playerCore
    playerCore = null
    coreInstanceId = null
    cancelPendingInits()
    return core
  }

  private fun disposeCoreForTeardown() {
    // Activity/engine detach never reaches Dart's clearVideoFrameRate, so
    // the display mode is restored here or not at all.
    takeCoreForTeardown()?.dispose(preserveDisplayMode = false)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    activityBinding = binding
    PlayerDebugLog.d(tag) { "Attached to activity" }
  }

  override fun onDetachedFromActivity() {
    // The audio-only core deliberately outlives the activity (background
    // music); it is torn down on engine detach / Dart dispose instead.
    if (!audioOnly) {
      disposeCoreForTeardown()
    }
    activity = null
    activityBinding = null
    PlayerDebugLog.d(tag) { "Detached from activity" }
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    activityBinding = binding
    PlayerDebugLog.d(tag) { "Reattached to activity for config changes" }
  }

  override fun onDetachedFromActivityForConfigChanges() {
    // The video core owns views and window services from this Activity. Plezy
    // does not retain the engine across configuration recreation, so there is
    // no Activity-transfer contract under which that core may survive.
    if (!audioOnly) {
      disposeCoreForTeardown()
    }
    activity = null
    activityBinding = null
    PlayerDebugLog.d(tag) { "Detached from activity for config changes" }
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    channels.listen(events)
  }

  override fun onCancel(arguments: Any?) {
    channels.cancel()
  }

  private fun disposeVisualizer() {
    ++visualizerSessionId
    val old = visualizer
    visualizer = null
    old?.close()
  }

  private fun handleVisualizer(call: MethodCall, result: MethodChannel.Result) {
    fun unavailable(): String {
      if (!audioOnly || playerCore?.visualizationSessionId() == null) return "Initialize the music player before opening a preset."
      if ((call.argument<String>("engine") ?: "projectm") != "milkrust") return "Select native MilkRust on Android; this host does not bundle projectM."
      return MilkRustNativeBridge.loadError ?: MilkRustNativeBridge.dependencyError()
    }
    try {
      if (call.method == "visualizerCapabilities") {
        val reason = unavailable()
        result.success(mapOf("available" to reason.isEmpty(), "reason" to reason, "engine" to "milkrust-native-abi1", "audioTap" to reason.isEmpty()))
        return
      }
      if (call.method == "visualizerCreate") {
        val reason = unavailable()
        check(reason.isEmpty()) { reason }
        val registry = checkNotNull(textureRegistry) { "Flutter texture registry is unavailable." }
        val player = checkNotNull(playerCore?.visualizationSessionId()) { "Music session ended." }
        disposeVisualizer()
        val created = MilkRustVisualizer(registry, player)
        visualizer = created
        result.success(mapOf("sessionId" to visualizerSessionId, "textureId" to created.textureId))
        return
      }
      val current = visualizer
      if (current == null || call.argument<Number>("sessionId")?.toLong() != visualizerSessionId) {
        result.error("VISUALIZER_STALE", "This visualization session has ended.", null)
        return
      }
      when (call.method) {
        "visualizerDispose" -> disposeVisualizer()
        "visualizerLoad" -> current.load(checkNotNull(call.argument<String>("path")), checkNotNull(call.argument<String>("root")))
        "visualizerResize" -> {
          val width = checkNotNull(call.argument<Number>("width")).toLong()
          val height = checkNotNull(call.argument<Number>("height")).toLong()
          require(width in 1..16384 && height in 1..16384) { "Invalid visualization dimensions." }
          current.resize(width.toInt(), height.toInt())
        }
        "visualizerSetPaused" -> current.pause(checkNotNull(call.argument<Boolean>("paused")))
        "visualizerStatus" -> {
          result.success(current.status())
          return
        }
        else -> {
          result.notImplemented()
          return
        }
      }
      result.success(null)
    } catch (error: Exception) {
      result.error("VISUALIZER_NATIVE", error.message ?: "Native visualization failed.", null)
    }
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    if (call.method.startsWith("visualizer")) {
      handleVisualizer(call, result)
      return
    }
    when (call.method) {
      "initialize" -> handleInitialize(call, result)
      "dispose" -> handleDispose(call, result)
      "setProperty" -> handleSetProperty(call, result)
      "getProperty" -> handleGetProperty(call, result)
      "getStats" -> handleGetStats(result)
      "observeProperty" -> handleObserveProperty(call, result)
      "command" -> handleCommand(call, result)
      "setVisible" -> handleSetVisible(call, result)
      "setVideoRect" -> handleSetVideoRect(call, result)
      "updateFrame" -> handleUpdateFrame(result)
      "setVideoFrameRate" -> handleSetVideoFrameRate(call, result)
      "clearVideoFrameRate" -> handleClearVideoFrameRate(result)
      "setAudioFocusEnabled" -> handleSetAudioFocusEnabled(call, result)
      "requestAudioFocus" -> handleRequestAudioFocus(result)
      "getAudioSpdifCodecs" -> handleGetAudioSpdifCodecs(result)
      "abandonAudioFocus" -> handleAbandonAudioFocus(result)
      "openContentFd" -> handleOpenContentFd(call, result)
      "closeContentFd" -> handleCloseContentFd(call, result)
      "getHeapSize" -> {
        // Device heap class for Dart-side memory tiering (stream ring cache).
        // Lives on the always-registered mpv channel so it survives backends.
        val context: Context? = activity ?: applicationContext
        val am = context?.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
        result.success(am?.largeMemoryClass ?: 0)
      }
      "getAndroidMotionRuntimeCapabilities" -> executeMotionRuntimePreparation(result) {
        handleGetAndroidMotionRuntimeCapabilities(it)
      }
      "getAndroidThermalStatus" -> handleGetAndroidThermalStatus(result)
      "prepareAndroidAnvilRuntime" -> executeMotionRuntimePreparation(result) {
        handlePrepareAndroidAnvilRuntime(call, it)
      }
      "prepareAndroidLiteRtMotionRuntime" -> executeMotionRuntimePreparation(result) {
        handlePrepareAndroidLiteRtMotionRuntime(call, it)
      }
      "setAndroidMotionProcessingRenderer" -> handleSetAndroidMotionProcessingRenderer(call, result)
      "isInitialized" -> result.success(playerCore?.isInitialized ?: false)
      "setLogLevel" -> handleSetLogLevel(call, result)
      else -> result.notImplemented()
    }
  }

  /**
   * Derives the `audio-spdif` value for the current audio route. mpv force-passthroughs
   * every codec named there with no decode fallback, so with no context to inspect the
   * route the conservative answer is the empty list — decode everything (#1703, #1991).
   */
  private fun handleGetAudioSpdifCodecs(result: MethodChannel.Result) {
    val context: Context? = activity ?: applicationContext
    result.success(context?.let(::supportedMpvSpdifCodecs) ?: "")
  }

  private fun handleGetAndroidMotionRuntimeCapabilities(result: MethodChannel.Result) {
    val context = applicationContext
    if (context == null) {
      result.success(mapOf("available" to false, "reason" to "application-context-unavailable"))
      return
    }
    result.success(getAndroidMotionRuntimeCapabilities(context))
  }

  private fun handleGetAndroidThermalStatus(result: MethodChannel.Result) {
    val context = applicationContext
    if (context == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
      result.success(null)
      return
    }
    val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
    val status = powerManager?.currentThermalStatus
    result.success(
      when (status) {
        PowerManager.THERMAL_STATUS_NONE -> "none"
        PowerManager.THERMAL_STATUS_LIGHT -> "light"
        PowerManager.THERMAL_STATUS_MODERATE -> "moderate"
        PowerManager.THERMAL_STATUS_SEVERE -> "severe"
        PowerManager.THERMAL_STATUS_CRITICAL -> "critical"
        PowerManager.THERMAL_STATUS_EMERGENCY -> "emergency"
        PowerManager.THERMAL_STATUS_SHUTDOWN -> "shutdown"
        else -> null
      }
    )
  }

  private fun handleSetAndroidMotionProcessingRenderer(call: MethodCall, result: MethodChannel.Result) {
    val renderer = call.argument<String>("renderer")
    val core = playerCore
    if (core?.isInitialized != true) {
      completeMpvPropertyNotInitialized(result)
      return
    }

    val gen = sessionGeneration
    core.setMotionProcessingRenderer(renderer) { outcome ->
      if (gen != sessionGeneration || playerCore !== core) {
        result.success(false)
      } else {
        outcome.fold(
          onSuccess = { installed -> result.success(installed) },
          onFailure = { error -> result.error("MOTION_RENDERER_FAILED", error.message, null) }
        )
      }
    }
  }

  private fun handlePrepareAndroidAnvilRuntime(call: MethodCall, result: MethodChannel.Result) {
    val context = applicationContext
    if (context == null) {
      result.error("MOTION_RUNTIME_UNAVAILABLE", "Android application context is unavailable", null)
      return
    }
    val contextPath = call.argument<String>("contextPath")
    val modelId = call.argument<String>("modelId")
    if (modelId == null || modelId !in setOf("anvil-s-720p", "anvil-m-720p", "anvil-s-1080p", "anvil-m-1080p")) {
      result.error("INVALID_ARGS", "Unknown ANVIL model context", null)
      return
    }

    try {
      val capabilities = getAndroidMotionRuntimeCapabilities(context)
      if (capabilities["qnnHtpAvailable"] != true) {
        result.error("MOTION_RUNTIME_UNAVAILABLE", "A compatible Qualcomm HTP runtime is unavailable", capabilities)
        return
      }
      val target = androidHtpTarget(context)
        ?: throw IllegalStateException("No supported Qualcomm HTP target was identified")
      val requiredResolution = target.resolution
      if (!modelId.endsWith(requiredResolution)) {
        result.error(
          "MOTION_MODEL_UNAVAILABLE",
          "${target.version} ANVIL contexts are built for $requiredResolution input",
          capabilities
        )
        return
      }

      val availableModels = capabilities["anvilContextIds"] as? List<*>
      val remoteV75Performance = target.architecture == "v75" && modelId == "anvil-s-1080p"
      if (!remoteV75Performance && availableModels?.contains(modelId) != true) {
        result.error("MOTION_MODEL_UNAVAILABLE", "The matching ANVIL context is not packaged", capabilities)
        return
      }

      val appFiles = context.filesDir.canonicalFile
      val directory: File
      val modelContext: File
      if (!contextPath.isNullOrBlank()) {
        val provided = File(contextPath).canonicalFile
        if (
          provided.name != "context.serialized.bin" ||
          !provided.path.startsWith(appFiles.path + File.separator) ||
          !provided.isFile
        ) {
          result.error("INVALID_ARGS", "ANVIL context must be installed inside app storage", null)
          return
        }
        directory = provided.parentFile
          ?: throw IllegalArgumentException("ANVIL context directory is missing")
        modelContext = provided
      } else {
        directory = File(appFiles, "anvil/${target.architecture}/$modelId")
        if (!directory.isDirectory && !directory.mkdirs()) {
          throw IllegalStateException("Could not create ANVIL runtime directory")
        }
        modelContext = File(directory, "context.serialized.bin")
        val assetPath = "anvil/contexts/${target.socModel.lowercase()}/$modelId/context.serialized.bin"
        if (!verifyAnvilContextAsset(context, target, modelId, assetPath)) {
          result.error("MOTION_MODEL_INTEGRITY_FAILED", "The ANVIL context manifest or checksum is invalid", null)
          return
        }
        copyAnvilAsset(context, assetPath, modelContext)
      }

      copyAnvilAsset(context, "anvil/htp/${target.skelLibrary}", File(directory, target.skelLibrary))
      result.success(directory.absolutePath)
    } catch (error: Exception) {
      Log.w(tag, "Failed to prepare the Android neural runtime", error)
      result.error("MOTION_RUNTIME_PREPARE_FAILED", "Android neural runtime could not be prepared", null)
    }
  }

  private fun handlePrepareAndroidLiteRtMotionRuntime(call: MethodCall, result: MethodChannel.Result) {
    val context = applicationContext
    if (context == null) {
      result.error("MOTION_RUNTIME_UNAVAILABLE", "Android application context is unavailable", null)
      return
    }
    val modelId = call.argument<String>("modelId")
    if (modelId == null || modelId !in setOf("anvil-s-720p", "anvil-m-720p", "anvil-s-1080p", "anvil-m-1080p")) {
      result.error("INVALID_ARGS", "Unknown LiteRT ANVIL model", null)
      return
    }

    try {
      val capabilities = getAndroidMotionRuntimeCapabilities(context)
      val gpuAvailable = capabilities["litertGpuAvailable"] == true
      val npuProviders = capabilities["litertNpuProviders"] as? List<*> ?: emptyList<Any>()
      if (!gpuAvailable && npuProviders.isEmpty()) {
        result.error("MOTION_RUNTIME_UNAVAILABLE", "No LiteRT hardware provider is packaged", capabilities)
        return
      }

      val manifestText = context.assets.open("litert/models/manifest.json")
        .bufferedReader()
        .use { it.readText() }
      val manifest = org.json.JSONObject(manifestText)
      val modelKey = modelId.substringBeforeLast('-')
      val resolution = modelId.substringAfterLast('-')
      val providers = manifest.getJSONObject("models")
        .getJSONObject(modelKey)
        .getJSONObject("variants")
        .getJSONObject(resolution)

      val directory = File(context.filesDir, "motion-models/litert/$modelId")
      if (!directory.isDirectory && !directory.mkdirs()) {
        throw IllegalStateException("Could not create the LiteRT model directory")
      }

      val currentSocModel = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        normalizeSocModel(Build.SOC_MODEL).removePrefix("S5")
      } else {
        ""
      }
      val samsungNpuRecord = if (npuProviders.contains("samsung")) {
        providers.optJSONObject("samsung")?.takeIf { record ->
          val target = normalizeSocModel(record.optString("soc_model")).removePrefix("S5")
          target in setOf("E9955", "E9965") && target == currentSocModel
        }
      } else {
        null
      }
      val googleTensorNpuRecord = if (npuProviders.contains("google-tensor")) {
        val keys = providers.keys()
        var matchingRecord: org.json.JSONObject? = null
        while (keys.hasNext() && matchingRecord == null) {
          val record = providers.optJSONObject(keys.next()) ?: continue
          if (
            record.optString("backend") == "google-tensor" &&
            record.optString("execution") == "aot" &&
            normalizeSocModel(record.optString("soc_model")) == normalizeSocModel(Build.SOC_MODEL)
          ) {
            matchingRecord = record
          }
        }
        matchingRecord
      } else {
        null
      }
      val hasGenericJitProvider = npuProviders.any { it != "google-tensor" && it != "samsung" }
      val npuRecord = samsungNpuRecord ?: googleTensorNpuRecord ?: if (hasGenericJitProvider) {
        providers.optJSONObject("npu")
      } else {
        null
      }
      val npuExecution = npuRecord?.optString("execution", "jit")
      val npuModel = if (
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
        npuRecord != null &&
        (npuRecord.optString("backend") != "google-tensor" || npuExecution == "aot")
      ) {
        installLiteRtModelAsset(context, npuRecord, directory)
      } else {
        null
      }
      val gpuModel = if (gpuAvailable) {
        providers.optJSONObject("gpu")?.let { installLiteRtModelAsset(context, it, directory) }
      } else {
        null
      }
      if (npuModel == null && gpuModel == null) {
        result.error("MOTION_MODEL_UNAVAILABLE", "No model variant matches the installed LiteRT providers", capabilities)
        return
      }

      val cacheDirectory = File(context.filesDir, "motion-models/litert-cache")
      if (!cacheDirectory.isDirectory && !cacheDirectory.mkdirs()) {
        throw IllegalStateException("Could not create the LiteRT compilation cache")
      }
      val processAbi = if (android.os.Process.is64Bit()) {
        Build.SUPPORTED_ABIS.firstOrNull { it == "arm64-v8a" || it == "x86_64" }
      } else {
        Build.SUPPORTED_ABIS.firstOrNull { it == "armeabi-v7a" || it == "x86" }
      } ?: throw IllegalStateException("LiteRT has no runtime libraries for this process ABI")
      val libraryDirectory = stageLiteRtRuntimeLibraries(
        context,
        processAbi,
        includeSamsungLiteCore = npuProviders.contains("samsung")
      )
      val npuModelBackend = npuRecord?.optString("backend")?.takeIf { it.isNotBlank() }
        ?: npuProviders.firstOrNull()?.toString()?.takeIf { npuModel != null }
      result.success(
        mapOf(
          "modelId" to modelId,
          "npuModelPath" to npuModel?.absolutePath,
          "gpuModelPath" to gpuModel?.absolutePath,
          "npuModelExecution" to npuExecution,
          "npuModelBackend" to npuModelBackend,
          "npuModelTarget" to npuRecord?.optString("soc_model")?.takeIf { it.isNotBlank() },
          // LiteRT discovers compiler and dispatch plugins by scanning this
          // filesystem directory. APK-stored JNI libraries are not guaranteed
          // to be extracted into nativeLibraryDir on modern Android builds.
          "libraryDir" to libraryDirectory.absolutePath,
          "cacheDir" to cacheDirectory.absolutePath,
          "npuProviders" to npuProviders.filter { provider ->
            provider != "google-tensor" || googleTensorNpuRecord != null && npuExecution == "aot"
          }
        )
      )
    } catch (error: Exception) {
      Log.w(tag, "Failed to prepare the Android LiteRT motion runtime", error)
      result.error("MOTION_RUNTIME_PREPARE_FAILED", "LiteRT motion runtime could not be prepared", null)
    }
  }

  private fun getAndroidMotionRuntimeCapabilities(context: Context): Map<String, Any?> {
    val socModel = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) Build.SOC_MODEL else ""
    val socManufacturer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) Build.SOC_MANUFACTURER else ""
    val target = androidHtpTarget(context)
    val nativeDir = File(context.applicationInfo.nativeLibraryDir)
    val requiredLibraries = listOf(
      "libQnnHtp.so",
      "libQnnSystem.so",
      "libQnnHtpPrepare.so"
    ) + listOfNotNull(target?.stubLibrary)
    val packagedLibraries = requiredLibraries.filterTo(mutableSetOf()) { File(nativeDir, it).isFile }
    val abi = if (android.os.Process.is64Bit()) {
      Build.SUPPORTED_ABIS.firstOrNull { it == "arm64-v8a" }
    } else {
      null
    }
    if (abi != null) {
      val apkPaths = listOf(context.applicationInfo.sourceDir) + context.applicationInfo.splitSourceDirs.orEmpty()
      for (apkPath in apkPaths) {
        try {
          ZipFile(apkPath).use { apk ->
            for (library in requiredLibraries) {
              if (apk.getEntry("lib/$abi/$library") != null) packagedLibraries += library
            }
          }
        } catch (_: Exception) {
          // A split can disappear during an update. Other package locations
          // are still checked, and the missing-library report stays precise.
        }
      }
    }
    val missingLibraries = requiredLibraries.filterNot(packagedLibraries::contains)
    val skelAssetPresent = target != null && assetExists(context, "anvil/htp/${target.skelLibrary}")
    val supportedSoc = target != null && android.os.Process.is64Bit()
    val available = supportedSoc && missingLibraries.isEmpty() && skelAssetPresent
    val contextResolution = target?.resolution ?: "1080p"
    val modelIds = listOf("anvil-s-$contextResolution", "anvil-m-$contextResolution")
      .filter { modelId ->
        target != null &&
          assetExists(
            context,
            "anvil/contexts/${target.socModel.lowercase()}/$modelId/context.serialized.bin"
          )
      }
    val liteRtBaseLibraries = listOf("libLiteRt.so", "libplezy_litert_motion.so")
    val liteRtGpuLibraries = listOf("libLiteRtClGlAccelerator.so")
    val liteRtProviders = linkedMapOf(
      "qualcomm" to listOf("libLiteRtCompilerPlugin_Qualcomm.so", "libLiteRtDispatch_Qualcomm.so"),
      "mediatek" to listOf("libLiteRtCompilerPlugin_MediaTek.so", "libLiteRtDispatch_MediaTek.so"),
      "google-tensor" to listOf("libLiteRtCompilerPlugin_google_tensor.so", "libLiteRtDispatch_GoogleTensor.so"),
      "intel-openvino" to listOf("libLiteRtCompilerPlugin_IntelOpenvino.so", "libLiteRtDispatch_IntelOpenvino.so"),
      "samsung" to listOf("libLiteRtCompilerPlugin_Samsung.so", "libLiteRtDispatch_Samsung.so")
    )
    val processAbi = if (android.os.Process.is64Bit()) {
      Build.SUPPORTED_ABIS.firstOrNull { it == "arm64-v8a" || it == "x86_64" }
    } else {
      Build.SUPPORTED_ABIS.firstOrNull { it == "armeabi-v7a" || it == "x86" }
    }
    fun hasNativeLibrary(name: String): Boolean {
      if (File(nativeDir, name).isFile) return true
      if (processAbi == null) return false
      val apkPaths = listOf(context.applicationInfo.sourceDir) + context.applicationInfo.splitSourceDirs.orEmpty()
      return apkPaths.any { apkPath ->
        try {
          ZipFile(apkPath).use { apk -> apk.getEntry("lib/$processAbi/$name") != null }
        } catch (_: Exception) {
          false
        }
      }
    }
    val liteRtOpenVinoRuntimeAvailable = processAbi == "x86_64" &&
      LITERT_OPENVINO_RUNTIME_LIBRARIES.all(::hasNativeLibrary)
    val liteRtBaseAvailable = liteRtBaseLibraries.all(::hasNativeLibrary)
    val liteRtGpuAvailable = liteRtBaseAvailable && liteRtGpuLibraries.all(::hasNativeLibrary)
    val samsungLiteCoreLibraries = context.assets.list(LITERT_SAMSUNG_LITECORE_ASSET_DIR)
      .orEmpty()
      .filter { it.endsWith(".so") }
      .toSet()
    val samsungLiteCoreAvailable = assetExists(context, LITERT_SAMSUNG_MANIFEST_ASSET) &&
      samsungLiteCoreLibraries.containsAll(LITERT_SAMSUNG_LITECORE_REQUIRED_LIBRARIES)
    val litertNpuProviders = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      liteRtProviders.mapNotNull { (provider, libraries) ->
        val abiSupported = when (provider) {
          "intel-openvino" -> liteRtOpenVinoRuntimeAvailable
          else -> processAbi == "arm64-v8a"
        }
        val normalizedSocModel = normalizeSocModel(socModel)
        val normalizedSocManufacturer = socManufacturer.trim().uppercase()
        val deviceSupported = when (provider) {
          "qualcomm" -> normalizedSocManufacturer.contains("QUALCOMM") ||
            normalizedSocManufacturer == "QTI" ||
            normalizedSocModel.matches(Regex("^(SM|QCM|QCS)\\d+.*")) ||
            normalizedSocModel.contains("SNAPDRAGON")
          "mediatek" -> normalizedSocManufacturer.contains("MEDIATEK") ||
            normalizedSocModel.matches(Regex("^MT\\d+.*"))
          "google-tensor" -> normalizedSocModel in setOf("TENSORG5", "TENSORG6")
          "intel-openvino" ->
            processAbi == "x86_64" &&
              (normalizedSocManufacturer.contains("INTEL") || normalizedSocModel.contains("INTEL"))
          "samsung" ->
            samsungLiteCoreAvailable &&
              Build.VERSION.SDK_INT >= 36 &&
              normalizedSocModel.removePrefix("S5") in setOf("E9955", "E9965")
          else -> false
        }
        if (liteRtBaseAvailable && abiSupported && deviceSupported && libraries.all(::hasNativeLibrary)) {
          provider
        } else {
          null
        }
      }
    } else {
      emptyList()
    }
    val liteRtModelManifestPresent = assetExists(context, "litert/models/manifest.json")
    return mapOf(
      "platform" to "android-mpv",
      "manufacturer" to Build.MANUFACTURER,
      "socManufacturer" to socManufacturer,
      "device" to Build.DEVICE,
      "socModel" to socModel,
      "provider" to if (available) "qnn-htp-${target!!.architecture}" else "unavailable",
      "qnnHtpAvailable" to available,
      "qnnHtpArchitecture" to target?.architecture,
      "qnnHtpVersion" to target?.version,
      "qnnHtpSocId" to target?.socId,
      "qnnHtpResolution" to target?.resolution,
      "qnnHtpV75Available" to (available && target?.architecture == "v75"),
      "anvilContextIds" to modelIds,
      "litertAvailable" to liteRtBaseAvailable,
      "litertGpuAvailable" to liteRtGpuAvailable,
      "litertNpuAvailable" to litertNpuProviders.isNotEmpty(),
      "litertNpuProviders" to litertNpuProviders,
      "litertModelManifestPresent" to liteRtModelManifestPresent,
      "missingLibraries" to missingLibraries,
      "skelAssetPresent" to skelAssetPresent,
      "reason" to when {
        !supportedSoc -> "unsupported-soc"
        missingLibraries.isNotEmpty() -> "qnn-runtime-not-packaged"
        !skelAssetPresent -> "qnn-skel-not-packaged"
        else -> null
      }
    )
  }

  private fun normalizeSocModel(value: String): String = value.trim().uppercase().filter { it.isLetterOrDigit() }

  private fun installLiteRtModelAsset(context: Context, record: org.json.JSONObject, directory: File): File {
    val filename = record.optString("file")
    val expectedBytes = record.optLong("bytes", -1)
    val expectedSha256 = record.optString("sha256")
    if (
      filename.isBlank() ||
      File(filename).name != filename ||
      !filename.endsWith(".tflite") ||
      expectedBytes <= 0 ||
      expectedSha256.length != 64
    ) {
      throw IllegalArgumentException("LiteRT model manifest entry is invalid")
    }

    val assetPath = "litert/models/$filename"
    val destination = File(directory, filename)
    if (destination.isFile &&
      destination.length() == expectedBytes &&
      sha256(destination).equals(expectedSha256, ignoreCase = true)
    ) {
      return destination
    }

    val temporary = File(directory, "$filename.partial")
    try {
      context.assets.open(assetPath).use { input ->
        FileOutputStream(temporary).use { output ->
          val digest = MessageDigest.getInstance("SHA-256")
          val buffer = ByteArray(64 * 1024)
          var totalBytes = 0L
          while (true) {
            val count = input.read(buffer)
            if (count < 0) break
            totalBytes += count
            if (totalBytes > expectedBytes) throw IllegalStateException("LiteRT model exceeds its manifest size")
            digest.update(buffer, 0, count)
            output.write(buffer, 0, count)
          }
          output.fd.sync()
          val actualSha256 = digest.digest().joinToString("") { "%02x".format(it.toInt() and 0xff) }
          if (totalBytes != expectedBytes || !actualSha256.equals(expectedSha256, ignoreCase = true)) {
            throw IllegalStateException("LiteRT model size or SHA-256 does not match its manifest")
          }
        }
      }
      if (destination.exists() && !destination.delete()) {
        throw IllegalStateException("Could not replace LiteRT model ${destination.name}")
      }
      if (!temporary.renameTo(destination)) {
        throw IllegalStateException("Could not install LiteRT model $filename")
      }
      return destination
    } finally {
      if (temporary.exists()) temporary.delete()
    }
  }

  private fun stageLiteRtRuntimeLibraries(
    context: Context,
    abi: String,
    includeSamsungLiteCore: Boolean
  ): File {
    val directory = File(context.filesDir, "motion-runtime/litert-$LITERT_RUNTIME_VERSION/$abi")
    if (!directory.isDirectory && !directory.mkdirs()) {
      throw IllegalStateException("Could not create the LiteRT runtime plugin directory")
    }
    fun isRuntimeLibrary(name: String): Boolean = name.endsWith(".so") &&
      (
        name.startsWith("libLiteRt") ||
          name == "libplezy_litert_motion.so" ||
          name in LITERT_OPENVINO_RUNTIME_LIBRARIES
        )

    val nativeDirectory = File(context.applicationInfo.nativeLibraryDir)
    val nativeLibraries = nativeDirectory.listFiles()
      .orEmpty()
      .filter { it.isFile && isRuntimeLibrary(it.name) }
      .associateBy { it.name }
    val apkLibraries = linkedMapOf<String, Pair<File, String>>()
    val apkPaths = (
      listOf(context.applicationInfo.sourceDir) +
        context.applicationInfo.splitSourceDirs.orEmpty()
      ).map { File(it) }
    for (apkPath in apkPaths) {
      try {
        ZipFile(apkPath).use { apk ->
          val entries = apk.entries()
          while (entries.hasMoreElements()) {
            val entry = entries.nextElement()
            val prefix = "lib/$abi/"
            if (
              entry.isDirectory ||
              !entry.name.startsWith(prefix) ||
              !isRuntimeLibrary(entry.name.removePrefix(prefix))
            ) {
              continue
            }
            val libraryName = entry.name.removePrefix(prefix)
            if (!apkLibraries.containsKey(libraryName)) {
              apkLibraries[libraryName] = apkPath to entry.name
            }
          }
        }
      } catch (_: Exception) {
        // A split can disappear during an update; available APKs are still
        // checked, then the required runtime library check below reports it.
      }
    }

    val libraryNames = (nativeLibraries.keys + apkLibraries.keys).toSortedSet()
    val requiredLibraries = setOf("libLiteRt.so", "libplezy_litert_motion.so")
    val missingLibraries = requiredLibraries - libraryNames
    if (missingLibraries.isNotEmpty()) {
      throw IllegalStateException("LiteRT runtime libraries are missing for $abi: ${missingLibraries.joinToString()}")
    }
    if (!directory.setReadable(true, true) || !directory.setExecutable(true, true)) {
      throw IllegalStateException("Could not make the LiteRT plugin directory readable")
    }
    for (name in libraryNames) {
      val destination = File(directory, name)
      val nativeSource = nativeLibraries[name]
      val apkSource = apkLibraries[name]
      val expectedBytes = nativeSource?.length() ?: apkSource?.let { (apkPath, entryName) ->
        ZipFile(apkPath).use { it.getEntry(entryName)?.size ?: -1L }
      } ?: -1L
      if (expectedBytes < 0) throw IllegalStateException("Could not read the packaged LiteRT library size for $name")
      if (destination.isFile && destination.length() == expectedBytes) {
        if (!destination.setReadable(true, true) ||
          !destination.setExecutable(true, true) ||
          !destination.setWritable(false, true)
        ) {
          throw IllegalStateException("Could not set executable permissions on LiteRT library $name")
        }
        continue
      }

      val temporary = File(directory, "$name.partial")
      try {
        FileOutputStream(temporary).use { output ->
          if (nativeSource != null) {
            nativeSource.inputStream().use { it.copyTo(output) }
          } else {
            val (apkPath, entryName) = apkSource
              ?: throw IllegalStateException("The packaged LiteRT library is missing: $name")
            ZipFile(apkPath).use { apk ->
              val entry = apk.getEntry(entryName)
                ?: throw IllegalStateException("The packaged LiteRT library disappeared: $name")
              apk.getInputStream(entry).use { it.copyTo(output) }
            }
          }
          output.fd.sync()
        }
        if (temporary.length() != expectedBytes) {
          throw IllegalStateException("The staged LiteRT library has the wrong size: $name")
        }
        if (!temporary.setReadable(true, true) ||
          !temporary.setExecutable(true, true) ||
          !temporary.setWritable(false, true)
        ) {
          throw IllegalStateException("Could not set executable permissions on LiteRT library $name")
        }
        if (destination.exists() && !destination.delete()) {
          throw IllegalStateException("Could not replace staged LiteRT library $name")
        }
        if (!temporary.renameTo(destination)) {
          throw IllegalStateException("Could not install staged LiteRT library $name")
        }
      } finally {
        if (temporary.exists()) temporary.delete()
      }
    }
    if (includeSamsungLiteCore) {
      val manifestText = context.assets.open(LITERT_SAMSUNG_MANIFEST_ASSET)
        .bufferedReader()
        .use { it.readText() }
      val expectedHashes = manifestText.lineSequence().filter(String::isNotBlank).associate { line ->
        val match = Regex("^([0-9a-fA-F]{64})\\s+\\*?(.+)$").matchEntire(line)
          ?: throw IllegalStateException("Samsung LiteCore checksum manifest is invalid")
        match.groupValues[2].removePrefix("./") to match.groupValues[1]
      }
      val assetNames = context.assets.list(LITERT_SAMSUNG_LITECORE_ASSET_DIR)
        .orEmpty()
        .filter { it.endsWith(".so") }
        .sorted()
      if (!assetNames.containsAll(LITERT_SAMSUNG_LITECORE_REQUIRED_LIBRARIES)) {
        throw IllegalStateException("Samsung LiteCore runtime assets are incomplete")
      }
      val liteCoreRoot = File(directory, "litecore")
      val liteCoreLibraryDirectory = File(liteCoreRoot, "lib/arm64-v8a")
      val manifestMarker = File(directory, "samsung-litecore.sha256")
      val runtimeIsCurrent = manifestMarker.isFile &&
        manifestMarker.readText() == manifestText &&
        assetNames.all { name ->
          val library = File(liteCoreLibraryDirectory, name)
          library.isFile && library.length() > 0
        }
      if (!runtimeIsCurrent) {
        val stagingRoot = File(directory, "litecore.staging-${System.nanoTime()}")
        val stagingLibraryDirectory = File(stagingRoot, "lib/arm64-v8a")
        try {
          if (!stagingLibraryDirectory.mkdirs()) {
            throw IllegalStateException("Could not create the Samsung LiteCore staging directory")
          }
          for (name in assetNames) {
            val relativePath = "litecore/lib/arm64-v8a/$name"
            val expectedHash = expectedHashes[relativePath]
              ?: throw IllegalStateException("Samsung LiteCore manifest is missing $relativePath")
            val assetPath = "$LITERT_SAMSUNG_LITECORE_ASSET_DIR/$name"
            val destination = File(stagingLibraryDirectory, name)
            context.assets.open(assetPath).use { input ->
              FileOutputStream(destination).use { output ->
                input.copyTo(output)
                output.fd.sync()
              }
            }
            if (!sha256(destination).equals(expectedHash, ignoreCase = true)) {
              throw IllegalStateException("Samsung LiteCore library $name failed SHA-256 verification")
            }
            if (!destination.setReadable(true, true) ||
              !destination.setExecutable(true, true) ||
              !destination.setWritable(false, true)
            ) {
              throw IllegalStateException("Could not set permissions on Samsung LiteCore library $name")
            }
          }
          for (parent in listOf(stagingRoot, File(stagingRoot, "lib"), stagingLibraryDirectory)) {
            if (!parent.setReadable(true, true) || !parent.setExecutable(true, true)) {
              throw IllegalStateException("Could not set permissions on the Samsung LiteCore runtime directory")
            }
          }
          if (liteCoreRoot.exists() && !liteCoreRoot.deleteRecursively()) {
            throw IllegalStateException("Could not replace the previous Samsung LiteCore runtime")
          }
          if (!stagingRoot.renameTo(liteCoreRoot)) {
            throw IllegalStateException("Could not install the Samsung LiteCore runtime")
          }
          val markerTemporary = File(directory, "samsung-litecore.sha256.partial")
          markerTemporary.writeText(manifestText)
          if (manifestMarker.exists() && !manifestMarker.delete()) {
            throw IllegalStateException("Could not replace the Samsung LiteCore checksum marker")
          }
          if (!markerTemporary.renameTo(manifestMarker)) {
            throw IllegalStateException("Could not install the Samsung LiteCore checksum marker")
          }
        } finally {
          if (stagingRoot.exists()) stagingRoot.deleteRecursively()
        }
      }
    }
    return directory
  }

  private fun sha256(file: File): String {
    val digest = MessageDigest.getInstance("SHA-256")
    file.inputStream().use { input ->
      val buffer = ByteArray(64 * 1024)
      while (true) {
        val count = input.read(buffer)
        if (count < 0) break
        digest.update(buffer, 0, count)
      }
    }
    return digest.digest().joinToString("") { "%02x".format(it.toInt() and 0xff) }
  }

  private fun androidHtpTarget(context: Context): AndroidHtpTarget? {
    if (!android.os.Process.is64Bit() || Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return null
    return androidHtpTargets[Build.SOC_MODEL.trim().uppercase()]
  }

  private fun assetExists(context: Context, path: String): Boolean = try {
    context.assets.open(path).use { true }
  } catch (_: Exception) {
    false
  }

  private fun verifyAnvilContextAsset(
    context: Context,
    target: AndroidHtpTarget,
    modelId: String,
    assetPath: String
  ): Boolean = try {
    val manifestText = context.assets.open("anvil/contexts/manifest.json")
      .bufferedReader()
      .use { it.readText() }
    val entries = org.json.JSONObject(manifestText).getJSONArray("contexts")
    val expectedPath = "${target.socModel.lowercase()}/$modelId/context.serialized.bin"
    val model = modelId.substringBeforeLast('-')
    val resolution = modelId.substringAfterLast('-')
    var expectedSha256: String? = null
    for (index in 0 until entries.length()) {
      val entry = entries.getJSONObject(index)
      if (
        entry.optString("target") == target.socModel.lowercase() &&
        entry.optString("model") == model &&
        entry.optString("resolution") == resolution &&
        entry.optString("context_path") == expectedPath
      ) {
        expectedSha256 = entry.optString("context_sha256")
        break
      }
    }
    if (expectedSha256.isNullOrBlank() || expectedSha256.length != 64) {
      false
    } else {
      val digest = MessageDigest.getInstance("SHA-256")
      context.assets.open(assetPath).use { input ->
        val buffer = ByteArray(64 * 1024)
        while (true) {
          val count = input.read(buffer)
          if (count < 0) break
          digest.update(buffer, 0, count)
        }
      }
      val actualSha256 = digest.digest().joinToString("") { "%02x".format(it.toInt() and 0xff) }
      actualSha256.equals(expectedSha256, ignoreCase = true)
    }
  } catch (_: Exception) {
    false
  }

  private fun copyAnvilAsset(context: Context, assetPath: String, destination: File) {
    val temporary = File(destination.parentFile, "${destination.name}.partial")
    destination.parentFile?.mkdirs()
    try {
      context.assets.open(assetPath).use { input ->
        FileOutputStream(temporary).use { output ->
          input.copyTo(output)
          output.fd.sync()
        }
      }
      if (destination.exists() && !destination.delete()) {
        throw IllegalStateException("Could not replace ANVIL asset ${destination.name}")
      }
      if (!temporary.renameTo(destination)) {
        throw IllegalStateException("Could not install ANVIL asset $assetPath")
      }
    } finally {
      if (temporary.exists()) temporary.delete()
    }
  }

  private fun handleInitialize(call: MethodCall, result: MethodChannel.Result) {
    // Whether the session will hardware-decode; decides the initial vo chain
    // (MpvPlayerCore.initialVideoOutput). Absent on the audio-only core and
    // from older callers; hardware decode is the setting's default.
    val hardwareDecoding = call.argument<Boolean>("hardwareDecoding") ?: true
    // Subtitle "Render Resolution" for the vo=mediacodec OSD plane (Full / ¾ / ½ /
    // ⅓ / ¼ of the surface); the same fraction the ExoPlayer overlay applies.
    // Absent from older callers and the audio-only core; full is the default.
    val subtitleRenderScale = call.argument<Double>("subtitleRenderScale")?.toFloat() ?: 1f
    val logLevel = call.argument<String>("logLevel") ?: "warn"
    val experimentalDolbyVision = call.argument<Boolean>("experimentalDolbyVision") ?: false
    // Video cores need the Activity (surface/view hierarchy); the audio-only
    // core is built on the application context so it can outlive it.
    val coreContext: Context? = if (audioOnly) applicationContext else activity
    if (coreContext == null) {
      if (audioOnly) {
        result.error("NO_CONTEXT", "Application context not available", null)
      } else {
        result.error("NO_ACTIVITY", "Activity not available", null)
      }
      return
    }

    if (playerCore?.isInitialized == true) {
      PlayerDebugLog.d(tag) { "Already initialized" }
      result.success(true)
      return
    }

    // Coalesce concurrent inits: the second caller waits for the first
    // call's outcome instead of disposing the in-flight core. The Dart
    // side memoizes too, but this is defense in depth for any direct
    // `invoke('initialize')` that bypasses _ensureInitialized.
    val attempt = synchronized(pendingInitResults) {
      pendingInitResults += result
      if (isInitializing) {
        null
      } else {
        isInitializing = true
        (++initAttemptCounter).also { activeInitAttempt = it }
      }
    }
    if (attempt == null) {
      PlayerDebugLog.d(tag) { "Init already in flight, queuing caller" }
      return
    }

    runOnMain {
      if (!isCurrentInitAttempt(attempt) ||
        (!audioOnly && activity !== coreContext) ||
        (audioOnly && applicationContext !== coreContext)
      ) {
        completePendingInits(attempt, success = false)
        return@runOnMain
      }

      val gen: Int
      val core: MpvPlayerCore
      try {
        // Caller invariant: dispose() was already called explicitly,
        // OR `playerCore?.isInitialized == true` and we early-exited
        // above. We never tear down a core that's mid-initialization.
        if (playerCore != null && playerCore?.isInitialized != true) {
          Log.w(tag, "Discarding stale uninitialized core before re-init")
          disposeVisualizer()
          playerCore?.dispose()
          playerCore = null
        }

        gen = ++sessionGeneration
        core = createCore(coreContext, hardwareDecoding, subtitleRenderScale, logLevel, experimentalDolbyVision).apply {
          delegate = this@MpvPlayerPlugin
          setAudioFocusEnabled(audioFocusEnabled)
        }
        playerCore = core
        coreInstanceId = call.argument<Number>("instanceId")?.toLong()
      } catch (e: Exception) {
        Log.e(tag, "Failed to initialize: ${e.message}", e)
        completePendingInits(attempt, success = false, errorMessage = e.message)
        return@runOnMain
      }

      // A core that never answers must not leave the Dart future that is
      // waiting on this attempt unresolved. completePendingInits is
      // attempt-scoped, so a late callback takes its stale branch and
      // disposes the core it created.
      val watchdog = Runnable {
        Log.w(tag, "Init watchdog fired after ${initWatchdogMs}ms; discarding the attempt")
        completePendingInits(attempt, success = false)
      }
      channels.mainHandler.postDelayed(watchdog, initWatchdogMs)

      initializeCore(core) { success ->
        channels.mainHandler.removeCallbacks(watchdog)
        val stale = gen != sessionGeneration ||
          playerCore !== core ||
          !isCurrentInitAttempt(attempt)
        if (stale || !success) {
          if (playerCore === core) {
            playerCore = null
            coreInstanceId = null
          }
          core.dispose()
          if (stale) {
            PlayerDebugLog.d(tag) { "Stale init callback (gen=$gen, current=$sessionGeneration)" }
          } else {
            PlayerDebugLog.d(tag) { "Initialized: false" }
          }
        } else {
          // Start hidden - now safe because setVisible operates on the container,
          // not the SurfaceView directly (matching ExoPlayer's approach).
          // No-op on the audio-only core, which has no render layer.
          core.setVisible(false)
          PlayerDebugLog.d(tag) { "Initialized: true" }
        }
        completePendingInits(attempt, success = !stale && success)
      }
    }
  }

  private fun isCurrentInitAttempt(attempt: Int): Boolean = synchronized(pendingInitResults) {
    isInitializing && activeInitAttempt == attempt
  }

  private fun cancelPendingInits() {
    val pending = synchronized(pendingInitResults) {
      ++initAttemptCounter
      activeInitAttempt = null
      isInitializing = false
      val copy = pendingInitResults.toList()
      pendingInitResults.clear()
      copy
    }
    pending.forEach { it.success(false) }
  }

  internal fun completePendingInits(
    attempt: Int,
    success: Boolean,
    errorMessage: String? = null
  ) {
    val pending = synchronized(pendingInitResults) {
      if (activeInitAttempt != attempt) return
      activeInitAttempt = null
      isInitializing = false
      val copy = pendingInitResults.toList()
      pendingInitResults.clear()
      copy
    }
    for (r in pending) {
      if (errorMessage != null) {
        r.error("INIT_FAILED", errorMessage, null)
      } else {
        r.success(success)
      }
    }
  }

  private fun handleDispose(call: MethodCall, result: MethodChannel.Result) {
    val token = call.argument<Number>("instanceId")?.toLong()
    // True across a player→player replacement: the successor inherits the
    // window's display mode instead of renegotiating HDMI twice.
    val preserveDisplayMode = call.argument<Boolean>("preserveDisplayMode") ?: false
    runOnMain {
      val owner = coreInstanceId
      if (playerCore != null && token != null && owner != null && token != owner) {
        // This dispose lost the ownership race: a successor already created
        // the current core. Acknowledge without touching it.
        PlayerDebugLog.d(tag) { "Ignoring stale dispose (token=$token, core owner=$owner)" }
        result.success(null)
        return@runOnMain
      }
      val core = takeCoreForTeardown()
      if (core == null) {
        result.success(null)
        return@runOnMain
      }
      // A hung native teardown must not wedge the Dart-side release chain.
      // Native create/destroy remains serialized on background workers behind
      // that teardown, so a successor cannot accumulate another MediaCodec
      // instance while the old one still owns its resources.
      val completed = AtomicBoolean(false)
      fun completeOnce(reason: String) {
        if (completed.compareAndSet(false, true)) {
          PlayerDebugLog.d(tag) { reason }
          result.success(null)
        }
      }
      channels.mainHandler.postDelayed({
        completeOnce("Dispose watchdog fired after ${disposeWatchdogMs}ms; teardown continues in background")
      }, disposeWatchdogMs)
      core.dispose(preserveDisplayMode) { completeOnce("Disposed") }
    }
  }

  private fun handleSetProperty(call: MethodCall, result: MethodChannel.Result) {
    val name = call.argument<String>("name")
    val value = call.argument<String>("value")

    if (name == null || value == null) {
      result.error("INVALID_ARGS", "Missing 'name' or 'value'", null)
      return
    }

    val core = playerCore
    if (core?.isInitialized != true) {
      completeMpvPropertyNotInitialized(result)
      return
    }

    core.setProperty(name, value) { outcome ->
      val details = propertyFailureDetails(core, name, outcome)
      if (details != null) Log.w(tag, "MPV rejected property '$name' $details; keeping the previous value")
      completeMpvPropertyResult(result, outcome, failureDetails = details)
    }
  }

  /** Null for a success or a cancellation, which answers NOT_INITIALIZED instead. */
  private fun propertyFailureDetails(core: MpvPlayerCore, name: String, outcome: Result<Unit>): Map<String, Any>? = outcome.exceptionOrNull()
    ?.takeUnless { it is CancellationException }
    ?.let { mpvPropertyFailureDetails(name, it, core.sessionFailure) }

  private fun handleGetProperty(call: MethodCall, result: MethodChannel.Result) {
    val name = call.argument<String>("name")

    if (name == null) {
      result.error("INVALID_ARGS", "Missing 'name'", null)
      return
    }

    val core = playerCore
    if (core == null) {
      result.success(null)
      return
    }

    val gen = sessionGeneration
    core.getPropertyAsync(name) { value ->
      if (gen != sessionGeneration || playerCore !== core) {
        result.success(null)
      } else {
        result.success(value)
      }
    }
  }

  private fun handleGetStats(result: MethodChannel.Result) {
    val core = playerCore
    if (core == null) {
      result.success(mapOf("playerType" to "mpv"))
      return
    }

    val gen = sessionGeneration
    core.getStatsAsync { stats ->
      if (gen != sessionGeneration || playerCore !== core) {
        result.success(mapOf("playerType" to "mpv"))
      } else {
        result.success(stats)
      }
    }
  }

  private fun handleObserveProperty(call: MethodCall, result: MethodChannel.Result) {
    val name = call.argument<String>("name")
    val format = call.argument<String>("format")
    val id = call.argument<Int>("id")

    if (name == null || format == null || id == null) {
      result.error("INVALID_ARGS", "Missing 'name', 'format', or 'id'", null)
      return
    }

    val core = playerCore
    if (core?.isInitialized != true) {
      completeMpvPropertyNotInitialized(result)
      return
    }
    // Install the id before registering: mpv may emit the initial value at once.
    nameToId[name] = id
    core.observeProperty(name, format) { outcome ->
      completeMpvPropertyResult(result, outcome, failureDetails = propertyFailureDetails(core, name, outcome))
    }
  }

  private fun handleCommand(call: MethodCall, result: MethodChannel.Result) {
    val args = call.argument<List<String>>("args")

    if (args == null) {
      result.error("INVALID_ARGS", "Missing 'args'", null)
      return
    }

    val core = playerCore
    if (core == null) {
      result.error("NOT_INITIALIZED", "Player not initialized", null)
      return
    }
    // `loadfile` answers with the playlist entry it created so Dart can tie
    // the load to that source's start-file/playback-restart/end-file events;
    // every other command answers null.
    core.commandForSource(args.toTypedArray()) { outcome ->
      outcome.fold(
        onSuccess = { playlistEntryId ->
          result.success(playlistEntryId?.let { mapOf("playlistEntryId" to it) })
        },
        onFailure = { error ->
          result.error("COMMAND_FAILED", error.message ?: "mpv command failed", args)
        }
      )
    }
  }

  private fun handleSetLogLevel(call: MethodCall, result: MethodChannel.Result) {
    val level = call.argument<Any>("level") as? String
    if (level == null) {
      result.error("INVALID_ARGS", "Missing or invalid 'level'", null)
      return
    }
    PlayerDebugLog.applyLogLevel(level)
    val core = playerCore
    if (core?.isInitialized != true) {
      completeMpvPropertyNotInitialized(result)
      return
    }
    core.setLogLevel(level) { outcome ->
      when (val failure = outcome.exceptionOrNull()) {
        null -> result.success(null)
        is CancellationException -> completeMpvPropertyNotInitialized(result)
        else -> {
          Log.w(tag, "MPV rejected log level change", failure)
          result.error("SET_LOG_LEVEL_FAILED", "MPV log level change was rejected", null)
        }
      }
    }
  }

  private fun handleSetVideoRect(call: MethodCall, result: MethodChannel.Result) {
    val left = call.argument<Number>("left")?.toInt()
    val top = call.argument<Number>("top")?.toInt()
    val right = call.argument<Number>("right")?.toInt()
    val bottom = call.argument<Number>("bottom")?.toInt()
    val devicePixelRatio = call.argument<Number>("devicePixelRatio")?.toDouble()
    if (left == null ||
      top == null ||
      right == null ||
      bottom == null ||
      devicePixelRatio == null ||
      !devicePixelRatio.isFinite() ||
      devicePixelRatio <= 0.0
    ) {
      result.error("INVALID_ARGS", "Missing or invalid video rectangle", null)
      return
    }
    playerCore?.setVideoRect(left, top, right, bottom, devicePixelRatio)
    result.success(null)
  }

  private fun handleSetVisible(call: MethodCall, result: MethodChannel.Result) {
    val visible = call.argument<Boolean>("visible")

    if (visible == null) {
      result.error("INVALID_ARGS", "Missing 'visible'", null)
      return
    }

    playerCore?.setVisible(visible)
    result.success(null)
  }

  private fun handleUpdateFrame(result: MethodChannel.Result) {
    playerCore?.updateFrame()
    result.success(null)
  }

  private fun handleSetVideoFrameRate(call: MethodCall, result: MethodChannel.Result) {
    val fps = call.argument<Double>("fps")?.toFloat() ?: 0f
    val duration = call.argument<Number>("duration")?.toLong() ?: 0L
    val extraDelayMs = call.argument<Number>("extraDelayMs")?.toLong() ?: 0L
    val videoWidth = call.argument<Number>("videoWidth")?.toInt() ?: 0
    val videoHeight = call.argument<Number>("videoHeight")?.toInt() ?: 0
    val matchResolution = call.argument<Boolean>("matchResolution") ?: false

    PlayerDebugLog.d(tag) {
      "setVideoFrameRate: fps=$fps, duration=$duration, extraDelayMs=$extraDelayMs, " +
        "video=${videoWidth}x$videoHeight, matchResolution=$matchResolution"
    }
    val core = playerCore
    if (core == null) {
      result.success(false)
      return
    }
    core.setVideoFrameRate(fps, duration, extraDelayMs, videoWidth, videoHeight, matchResolution) { switched ->
      result.success(switched)
    }
  }

  private fun handleClearVideoFrameRate(result: MethodChannel.Result) {
    PlayerDebugLog.d(tag) { "clearVideoFrameRate" }
    playerCore?.clearVideoFrameRate()
    result.success(null)
  }

  private fun handleRequestAudioFocus(result: MethodChannel.Result) {
    PlayerDebugLog.d(tag) { "requestAudioFocus" }
    val granted = playerCore?.requestAudioFocus() ?: false
    result.success(granted)
  }

  private fun handleSetAudioFocusEnabled(call: MethodCall, result: MethodChannel.Result) {
    val enabled = call.argument<Boolean>("enabled")
    if (enabled == null) {
      result.error("INVALID_ARGS", "Missing 'enabled'", null)
      return
    }
    audioFocusEnabled = enabled
    playerCore?.setAudioFocusEnabled(enabled)
    result.success(null)
  }

  private fun handleAbandonAudioFocus(result: MethodChannel.Result) {
    PlayerDebugLog.d(tag) { "abandonAudioFocus" }
    playerCore?.abandonAudioFocus()
    result.success(null)
  }

  private fun handleOpenContentFd(call: MethodCall, result: MethodChannel.Result) {
    val uriString = call.argument<String>("uri")
    if (uriString == null) {
      result.error("INVALID_ARGS", "Missing 'uri'", null)
      return
    }

    // The audio instance may run without an Activity (background music), so
    // resolve SAF content URIs through the application context there.
    val contentResolver = (if (audioOnly) applicationContext else activity)?.contentResolver
    if (contentResolver == null) {
      result.error(if (audioOnly) "NO_CONTEXT" else "NO_ACTIVITY", "Context not available", null)
      return
    }

    // Open file descriptor off UI thread to prevent ANR on slow storage
    Thread {
      try {
        val uri = Uri.parse(uriString)
        val pfd = contentResolver.openFileDescriptor(uri, "r")
        if (pfd == null) {
          runOnMain {
            result.error("OPEN_FAILED", "Failed to open file descriptor for $uriString", null)
          }
          return@Thread
        }

        val fd = pfd.detachFd()
        PlayerDebugLog.d(tag) { "Opened content FD $fd for $uriString" }
        runOnMain { result.success(fd) }
      } catch (e: Exception) {
        Log.e(tag, "Failed to open content FD: ${e.message}", e)
        runOnMain { result.error("OPEN_FAILED", e.message, null) }
      }
    }.start()
  }

  // Reclaims a detached fd from handleOpenContentFd that mpv will never
  // consume (a gapless-armed entry dropped before mpv opened it). The Dart
  // side guarantees single-close and only calls this when the entry provably
  // never played.
  private fun handleCloseContentFd(call: MethodCall, result: MethodChannel.Result) {
    val fd = call.argument<Int>("fd")
    if (fd == null || fd < 0) {
      result.error("INVALID_ARGS", "Missing 'fd'", null)
      return
    }
    try {
      ParcelFileDescriptor.adoptFd(fd).close()
      PlayerDebugLog.d(tag) { "Closed content FD $fd" }
      result.success(null)
    } catch (e: Exception) {
      Log.e(tag, "Failed to close content FD $fd: ${e.message}", e)
      result.error("CLOSE_FAILED", e.message, null)
    }
  }

  // PlayerDelegate

  override fun onPropertyChange(name: String, value: Any?) {
    onPropertyChange(name, value, null)
  }

  override fun onPropertyChange(name: String, value: Any?, sourceId: Long?) {
    val propId = nameToId[name] ?: return
    channels.emitProperty(propId, value, sourceId)
  }

  override fun onEvent(name: String, data: Map<String, Any>?) {
    channels.emitEvent(name, data)
  }
}

/**
 * The audio-only music instance on `com.plezy/mpv_audio_player[/events]`.
 * A distinct class (not just a configured [MpvPlayerPlugin]) because
 * FlutterEngine's plugin registry keys plugins by class and would silently
 * drop a second [MpvPlayerPlugin] registration.
 */
class MpvAudioPlayerPlugin : MpvPlayerPlugin(channelBase = "com.plezy/mpv_audio_player", audioOnly = true)

/** Independent MPV channel and core for the second retained workspace video. */
class MpvWorkspacePlayerPlugin : MpvPlayerPlugin(channelBase = "com.plezy/mpv_player/workspace")
