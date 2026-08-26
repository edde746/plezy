package com.edde746.plezy.exoplayer

import android.app.Activity
import android.util.Log
import com.edde746.plezy.libass.media.AssHandler
import com.edde746.plezy.mpv.MpvPlayerCore
import com.edde746.plezy.mpv.completeMpvPropertyNotInitialized
import com.edde746.plezy.mpv.completeMpvPropertyResult
import com.edde746.plezy.shared.MpvContentUriResolver
import com.edde746.plezy.shared.PlayerChannelBinding
import com.edde746.plezy.shared.PlayerDelegate
import com.edde746.plezy.shared.ResolvedMpvUri
import com.edde746.plezy.shared.SurfacePlayerCore
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CancellationException
import java.util.concurrent.atomic.AtomicBoolean

class ExoPlayerPlugin :
  FlutterPlugin,
  MethodChannel.MethodCallHandler,
  EventChannel.StreamHandler,
  ActivityAware,
  ExoPlayerDelegate {

  companion object {
    private const val TAG = "ExoPlayerPlugin"
    private const val MPV_FALLBACK_INIT_TIMEOUT_MS = 10_000L
    private const val MPV_OPEN_TIMEOUT_MS = 10_000L
    private const val METHOD_CHANNEL = "com.plezy/exo_player"
  }

  private val channels = PlayerChannelBinding(METHOD_CHANNEL, this, this, TAG)
  private val mainHandler get() = channels.mainHandler
  private fun runOnMain(block: () -> Unit) = channels.runOnMain(block)
  private var playerCore: ExoPlayerCore? = null

  // The Dart instanceId that created the current core. A `dispose` carrying a
  // different token lost the ownership race to a successor and must not tear
  // down that successor's session; it is acknowledged without touching it.
  private var coreInstanceId: Long? = null
  private var mpvCore: MpvPlayerCore? = null // MPV fallback player
  private var usingMpvFallback: Boolean = false
  private var fallbackInProgress: Boolean = false
  private var backendSwitchPending: Boolean = false
  private var activity: Activity? = null
  private var activityBinding: ActivityPluginBinding? = null

  /** Whichever core currently owns the surface; both expose [SurfacePlayerCore] identically. */
  private val activeSurfaceCore: SurfacePlayerCore?
    get() = if (usingMpvFallback) mpvCore else playerCore

  // Every Dart observeProperty registration, kept so an ExoPlayer→MPV
  // fallback can re-observe exactly what Dart asked for instead of
  // maintaining a parallel hard-coded list.
  private data class ObservedProperty(val id: Int, val format: String)
  private class MediaOpenRequest(
    val mediaGeneration: Int,
    val uri: String,
    val headers: Map<String, String>?,
    val startPositionMs: Long,
    val hasStartPosition: Boolean,
    /**
     * Whether to start playing once open. Mutable because a play or pause arriving while this
     * request is queued behind a backend handover has no player to reach — the outgoing core is
     * being disposed and the replacement does not exist yet — so the latest intent is recorded here
     * instead. Without that, a pause the caller was told succeeded is silently undone by the open.
     */
    var autoPlay: Boolean,
    val isLive: Boolean,
    val externalSubtitles: List<Map<String, Any?>>?,
    val contentFrameRate: Float,
    private val result: MethodChannel.Result?
  ) {
    private val completed = AtomicBoolean(false)

    fun success() {
      if (completed.compareAndSet(false, true)) result?.success(null)
    }

    fun error(code: String, message: String) {
      if (completed.compareAndSet(false, true)) result?.error(code, message, null)
    }
  }

  private sealed class PendingMpvSignal {
    data class Property(val id: Int, val value: Any?) : PendingMpvSignal()
    data class Event(val name: String, val data: Map<String, Any>?) : PendingMpvSignal()
  }

  private data class MpvSignalGate(
    val core: MpvPlayerCore,
    val mediaGeneration: Int,
    val signals: MutableList<PendingMpvSignal> = mutableListOf()
  )

  private inner class MpvDelegate(private val core: MpvPlayerCore) : PlayerDelegate {
    override fun onPropertyChange(name: String, value: Any?) {
      runOnMain { forwardMpvProperty(core, name, value) }
    }

    override fun onEvent(name: String, data: Map<String, Any>?) {
      val snapshot = data?.toMap()
      runOnMain { forwardMpvEvent(core, name, snapshot) }
    }
  }

  private val observedProperties = LinkedHashMap<String, ObservedProperty>()

  private var sessionGeneration = 0
  private var mediaGeneration = 0
  private var fallbackMediaGeneration: Int? = null
  private var terminalEventGeneration: Int? = null
  private var pendingOpen: MediaOpenRequest? = null
  private var inFlightOpen: MediaOpenRequest? = null
  private var mpvForwardGeneration: Int? = null
  private var mpvSignalGate: MpvSignalGate? = null
  private var mpvCoreNeedsReplacement = false
  internal var createMpvCore: (Activity) -> MpvPlayerCore =
    { MpvPlayerCore(it, hardwareDecoding = fallbackHardwareDecoding()) }
  internal var initializeMpvCore: (MpvPlayerCore, (Boolean) -> Unit) -> Unit = { core, onInitialized ->
    core.initialize(onInitialized)
  }
  internal var resolveMpvUri: (String, Activity, (ResolvedMpvUri) -> Unit) -> Unit = { uri, act, onResolved ->
    MpvContentUriResolver.resolve(uri, act.contentResolver, mainHandler, onResolved)
  }
  private var debugLoggingEnabled: Boolean = false

  // mpv properties set while ExoPlayer is active (including before
  // initialize — Dart queues its startup properties first), replayed into a
  // fallback MPV core. Keyed by property name (last write wins) and cleared
  // only at real session boundaries so settings can be replayed if a
  // superseded load requires a fresh MPV core.
  private val pendingMpvProperties = LinkedHashMap<String, String>()

  // Audio passthrough is a request, not a queued mpv property: mpv force-passthroughs
  // every codec in audio-spdif with no decode fallback, so the fallback core's value is
  // derived from the audio route at the moment mpv actually starts (#1703).
  private var audioPassthroughRequested = false

  // `dv-conversion-mode` is not an mpv property and never reaches
  // pendingMpvProperties: Dart routes it through setDvConversionMode (see
  // PlayerAndroid.setProperty), so the fallback core has to be seeded from the
  // last configured value or it loses the fork's P7/P5 handling entirely.
  private var dvConversionMode = "auto"
  private var currentExternalSubtitles: List<Map<String, Any?>>? = null

  // FlutterPlugin

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channels.attach(binding)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    teardownSession(clearActivity = true)
    channels.detach()
  }

  private fun teardownSession(clearActivity: Boolean) {
    ++sessionGeneration
    ++mediaGeneration
    val exoCore = playerCore
    val fallbackCore = mpvCore
    playerCore = null
    coreInstanceId = null
    mpvCore = null
    usingMpvFallback = false
    fallbackInProgress = false
    backendSwitchPending = false
    mpvForwardGeneration = null
    mpvSignalGate = null
    mpvCoreNeedsReplacement = false
    fallbackMediaGeneration = null
    terminalEventGeneration = null
    pendingOpen?.error("NOT_INITIALIZED", "Player session ended before media could open")
    pendingOpen = null
    inFlightOpen?.error("NOT_INITIALIZED", "Player session ended before media could open")
    inFlightOpen = null
    currentExternalSubtitles = null
    pendingMpvProperties.clear()
    audioPassthroughRequested = false
    dvConversionMode = "auto"
    if (clearActivity) {
      activity = null
      activityBinding = null
    }
    exoCore?.dispose()
    fallbackCore?.dispose()
  }

  // ActivityAware

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    activityBinding = binding
    Log.d(TAG, "Attached to activity")
  }

  override fun onDetachedFromActivity() {
    teardownSession(clearActivity = true)
    Log.d(TAG, "Detached from activity")
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    activityBinding = binding
    Log.d(TAG, "Reattached to activity for config changes")
  }

  override fun onDetachedFromActivityForConfigChanges() {
    // MainActivity owns a self-created engine which is destroyed with the old
    // Activity. There is no cached-engine transfer contract, so retaining an
    // Activity-bound core here would orphan its views and native resources.
    teardownSession(clearActivity = true)
    Log.d(TAG, "Detached from activity for config changes")
  }

  // EventChannel.StreamHandler

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    channels.listen(events)
  }

  override fun onCancel(arguments: Any?) {
    channels.cancel()
  }

  // MethodChannel.MethodCallHandler

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "initialize" -> handleInitialize(call, result)
      "dispose" -> handleDispose(call, result)
      "open" -> handleOpen(call, result)
      "play" -> handlePlay(result)
      "pause" -> handlePause(result)
      "stop" -> handleStop(result)
      "seek" -> handleSeek(call, result)
      "setVolume" -> handleSetVolume(call, result)
      "setRate" -> handleSetRate(call, result)
      "selectAudioTrack" -> handleSelectAudioTrack(call, result)
      "selectSubtitleTrack" -> handleSelectSubtitleTrack(call, result)
      "addSubtitleTrack" -> handleAddSubtitleTrack(call, result)
      "setVisible" -> handleSetVisible(call, result)
      "updateFrame" -> handleUpdateFrame(result)
      "setVideoFrameRate" -> handleSetVideoFrameRate(call, result)
      "clearVideoFrameRate" -> handleClearVideoFrameRate(result)
      "requestAudioFocus" -> handleRequestAudioFocus(result)
      "abandonAudioFocus" -> handleAbandonAudioFocus(result)
      "isInitialized" -> result.success(
        if (usingMpvFallback) {
          mpvCore?.isInitialized ?: false
        } else {
          playerCore?.isInitialized ?: false
        }
      )
      "getStats" -> handleGetStats(result)
      "getPlayerType" -> result.success(if (usingMpvFallback) "mpv" else "exoplayer")
      "setSubtitleStyle" -> handleSetSubtitleStyle(call, result)
      "setBoxFitMode" -> handleSetBoxFitMode(call, result)
      "setVideoZoom" -> handleSetVideoZoom(call, result)
      "setDvConversionMode" -> handleSetDvConversionMode(call, result)
      "setAudioNormalization" -> handleSetAudioNormalization(call, result)
      "setAudioPassthrough" -> handleSetAudioPassthrough(call, result)
      "setAudioDownmix" -> handleSetAudioDownmix(call, result)
      "observeProperty" -> handleObserveProperty(call, result)
      "setMpvProperty" -> handleSetMpvProperty(call, result)
      "setLogLevel" -> {
        val level = call.argument<String>("level") ?: "warn"
        debugLoggingEnabled = (level == "v" || level == "debug" || level == "trace")
        playerCore?.debugLoggingEnabled = debugLoggingEnabled
        result.success(null)
      }
      "triggerFallback" -> {
        playerCore?.triggerFallback()
        result.success(null)
      }
      else -> result.notImplemented()
    }
  }

  private fun handleInitialize(call: MethodCall, result: MethodChannel.Result) {
    val currentActivity = activity
    if (currentActivity == null) {
      result.error("NO_ACTIVITY", "Activity not available", null)
      return
    }

    val requestGeneration = sessionGeneration
    if (playerCore?.isInitialized == true || mpvCore?.isInitialized == true || fallbackInProgress) {
      Log.d(TAG, "Already initialized or switching backend")
      result.success(true)
      return
    }

    val tunnelingEnabled = call.argument<Boolean>("tunnelingEnabled") ?: false
    dvConversionMode = call.argument<String>("dvConversionMode") ?: "auto"
    val audioPassthroughEnabled = call.argument<Boolean>("audioPassthroughEnabled") ?: false
    val assVideoLatencyFrames = call.argument<Int>("assVideoLatencyFrames") ?: 0
    val subtitleRenderScale = call.argument<Double>("subtitleRenderScale")?.toFloat() ?: 1.0f
    // ExoPlayer-only: mpv's read-ahead is owned by the mpv.conf editor, so there is no
    // fallback replay for this one. Resolved in the core; unrecognised means Auto (#1816).
    val bufferTier = call.argument<String>("bufferTier") ?: "auto"
    // Seed the request here rather than waiting for Dart's separate setAudioPassthrough
    // call, so a fallback raised before that arrives still derives audio-spdif correctly.
    audioPassthroughRequested = audioPassthroughEnabled
    // Global libass overlay render scale — set before the player/handler is built below so the
    // first frame-size apply already uses it.
    AssHandler.setRenderScale(subtitleRenderScale)

    currentActivity.runOnUiThread {
      if (requestGeneration != sessionGeneration || activity !== currentActivity) {
        result.success(false)
        return@runOnUiThread
      }
      ++sessionGeneration
      // Do NOT clear pendingMpvProperties here: Dart queues its startup
      // properties (sub-ass, subtitle fonts, ...) before initialize, and the
      // fallback replay in setupMpvFallback needs them. Dispose/detach clear.

      if (mpvCore != null || fallbackInProgress) {
        mpvCore?.dispose()
        mpvCore = null
        usingMpvFallback = false
        fallbackInProgress = false
      }

      // An initialize without an intervening dispose would otherwise orphan the previous core
      // along with its ExoPlayer, audio sink, codecs and surface views — nothing else holds a
      // reference, so they would never be released.
      playerCore?.let { stale ->
        playerCore = null
        stale.dispose()
      }

      try {
        val core = ExoPlayerCore(currentActivity).apply {
          delegate = this@ExoPlayerPlugin
          this.debugLoggingEnabled = this@ExoPlayerPlugin.debugLoggingEnabled
        }
        playerCore = core
        coreInstanceId = call.argument<Number>("instanceId")?.toLong()
        val success = core.initialize(
          tunnelingEnabled = tunnelingEnabled,
          audioPassthroughEnabled = audioPassthroughEnabled,
          bufferTier = bufferTier
        )
        if (!success) {
          if (playerCore === core) playerCore = null
          result.success(false)
          return@runOnUiThread
        }
        if (core.setDebugDvConversionMode(dvConversionMode) != true) {
          Log.w(TAG, "Invalid DV conversion mode during initialize: $dvConversionMode")
        }
        // Seed from this device's persisted calibration, falling back to the Dart perf-tier proxy.
        core.seedAssVideoLatencyFrames(assVideoLatencyFrames)
        core.setVisible(false)

        Log.d(TAG, "Initialized: true")
        result.success(true)
      } catch (e: Exception) {
        Log.e(TAG, "Failed to initialize: ${e.message}", e)
        playerCore?.dispose()
        playerCore = null
        result.error("INIT_FAILED", e.message, null)
      }
    }
  }

  private fun handleDispose(call: MethodCall, result: MethodChannel.Result) {
    val token = call.argument<Number>("instanceId")?.toLong()
    runOnMain {
      val owner = coreInstanceId
      if ((playerCore != null || mpvCore != null) && token != null && owner != null && token != owner) {
        Log.d(TAG, "Ignoring stale dispose (token=$token, core owner=$owner)")
        result.success(null)
        return@runOnMain
      }
      teardownSession(clearActivity = false)
      Log.d(TAG, "Disposed")
      result.success(null)
    }
  }

  @Suppress("UNCHECKED_CAST")
  private fun handleOpen(call: MethodCall, result: MethodChannel.Result) {
    val uri = call.argument<String>("uri")
    val headers = call.argument<Map<String, String>>("headers")
    val startPositionMs = call.argument<Number>("startPositionMs")?.toLong() ?: 0L
    val hasStartPosition = call.argument<Boolean>("hasStartPosition") ?: (startPositionMs > 0L)
    val autoPlay = call.argument<Boolean>("autoPlay") ?: true
    val isLive = call.argument<Boolean>("isLive") ?: false
    val externalSubtitles = call.argument<List<Map<String, Any?>>>("externalSubtitles")
    // Server-reported frame rate for this item; -1 when the metadata did not carry one.
    val contentFrameRate = call.argument<Number>("contentFrameRate")?.toFloat() ?: -1f

    if (uri == null) {
      result.error("INVALID_ARGS", "Missing 'uri'", null)
      return
    }
    val currentActivity = activity
    if (currentActivity == null) {
      result.error("NO_ACTIVITY", "Activity not available", null)
      return
    }

    val request = MediaOpenRequest(
      mediaGeneration = ++mediaGeneration,
      uri = uri,
      headers = headers,
      startPositionMs = startPositionMs,
      hasStartPosition = hasStartPosition,
      autoPlay = autoPlay,
      isLive = isLive,
      externalSubtitles = externalSubtitles?.map { it.toMap() },
      contentFrameRate = contentFrameRate,
      result = result
    )
    terminalEventGeneration = null
    currentExternalSubtitles = request.externalSubtitles

    if (fallbackInProgress) {
      pendingOpen?.let(::completeSupersededOpen)
      pendingOpen = request
      Log.i(TAG, "Queued media generation ${request.mediaGeneration} until MPV fallback is ready")
      return
    }

    if (usingMpvFallback) {
      val core = mpvCore
      if (core?.isInitialized != true) {
        request.error("NOT_INITIALIZED", "Compatible player is not initialized")
        return
      }
      val activeOpen = inFlightOpen
      if (activeOpen != null) {
        completeSupersededOpen(activeOpen)
        mpvCoreNeedsReplacement = true
        pendingOpen?.let(::completeSupersededOpen)
        pendingOpen = request
        Log.i(TAG, "Queued media generation ${request.mediaGeneration} behind the active MPV open")
        return
      }
      pendingOpen?.let(::completeSupersededOpen)
      if (mpvCoreNeedsReplacement) {
        pendingOpen = request
        dispatchPendingMpvOpen(core, currentActivity, sessionGeneration)
      } else {
        pendingOpen = null
        dispatchMpvOpen(request, core, currentActivity, sessionGeneration)
      }
      return
    }

    currentActivity.runOnUiThread {
      if (request.mediaGeneration != mediaGeneration) {
        completeSupersededOpen(request)
        return@runOnUiThread
      }
      if (activity !== currentActivity) {
        request.error("NO_ACTIVITY", "Activity is no longer available")
        return@runOnUiThread
      }
      val core = playerCore
      if (core?.isInitialized != true) {
        request.error("NOT_INITIALIZED", "ExoPlayer is not initialized")
        return@runOnUiThread
      }
      core.open(
        uri = uri,
        headers = headers,
        startPositionMs = startPositionMs,
        autoPlay = autoPlay,
        mediaGeneration = request.mediaGeneration,
        isLive = isLive,
        externalSubtitleList = request.externalSubtitles,
        contentFrameRate = request.contentFrameRate
      )
      request.success()
    }
  }

  private fun loadMpvMedia(
    core: MpvPlayerCore,
    uri: String,
    headers: Map<String, String>?,
    startPositionMs: Long,
    hasStartPosition: Boolean,
    autoPlay: Boolean,
    externalSubtitles: List<Map<String, Any?>>?,
    onComplete: (Boolean) -> Unit
  ) {
    val startSeconds = startPositionMs / 1000.0
    val options = mutableListOf<String>()
    options.add(if (hasStartPosition && startPositionMs > 0L) "start=$startSeconds" else "start=none")
    options.add(if (autoPlay) "pause=no" else "pause=yes")
    options.add("sid=no")
    options.add("secondary-sid=no")
    appendExternalSubtitleOptions(options, externalSubtitles)
    appendHttpHeaderOptions(options, headers)
    val optionsStr = options.joinToString(",")
    core.command(arrayOf("loadfile", uri, "replace", "-1", optionsStr), onComplete)
  }

  private fun completeSupersededOpen(request: MediaOpenRequest) {
    request.error("OPEN_SUPERSEDED", "A newer media open replaced this request")
  }

  private fun forwardMpvProperty(core: MpvPlayerCore, name: String, value: Any?) {
    if (mpvCore !== core || !usingMpvFallback) return
    val propId = observedProperties[name]?.id ?: return
    val gate = mpvSignalGate
    if (gate != null) {
      if (gate.core === core && gate.mediaGeneration == mediaGeneration) {
        gate.signals.add(PendingMpvSignal.Property(propId, value))
      }
      return
    }
    if (mpvForwardGeneration == mediaGeneration) channels.emitProperty(propId, value)
  }

  private fun forwardMpvEvent(core: MpvPlayerCore, name: String, data: Map<String, Any>?) {
    if (mpvCore !== core || !usingMpvFallback) return
    val gate = mpvSignalGate
    if (gate != null) {
      if (gate.core === core && gate.mediaGeneration == mediaGeneration) {
        gate.signals.add(PendingMpvSignal.Event(name, data))
      }
      return
    }
    if (mpvForwardGeneration == mediaGeneration) channels.emitEvent(name, data)
  }

  private fun flushMpvSignals(core: MpvPlayerCore, request: MediaOpenRequest) {
    val gate = mpvSignalGate ?: return
    if (gate.core !== core || gate.mediaGeneration != request.mediaGeneration) return
    mpvSignalGate = null
    for (signal in gate.signals) {
      when (signal) {
        is PendingMpvSignal.Property -> channels.emitProperty(signal.id, signal.value)
        is PendingMpvSignal.Event -> channels.emitEvent(signal.name, signal.data)
      }
    }
  }

  private fun discardMpvSignals(core: MpvPlayerCore, request: MediaOpenRequest) {
    val gate = mpvSignalGate ?: return
    if (gate.core === core && gate.mediaGeneration == request.mediaGeneration) {
      mpvSignalGate = null
    }
  }

  private fun dispatchPendingMpvOpen(core: MpvPlayerCore, act: Activity, generation: Int) {
    runOnMain {
      if (inFlightOpen != null) return@runOnMain
      val next = pendingOpen ?: return@runOnMain
      pendingOpen = null
      if (generation != sessionGeneration || activity !== act || !usingMpvFallback || mpvCore !== core) {
        next.error("NOT_INITIALIZED", "Compatible player is no longer available")
        return@runOnMain
      }
      if (mpvCoreNeedsReplacement) {
        replaceMpvCoreForOpen(next, core, act, generation)
      } else {
        dispatchMpvOpen(next, core, act, generation)
      }
    }
  }

  private fun replaceMpvCoreForOpen(
    request: MediaOpenRequest,
    oldCore: MpvPlayerCore,
    act: Activity,
    generation: Int
  ) {
    fallbackInProgress = true
    pendingOpen = request
    mpvForwardGeneration = null
    mpvSignalGate = null
    if (mpvCore === oldCore) mpvCore = null
    oldCore.dispose()

    val replacementCore = try {
      createMpvCore(act)
    } catch (error: Exception) {
      failMpvReplacementInitialization(
        request.mediaGeneration,
        null,
        "Failed to recreate compatible player",
        error
      )
      return
    }
    replacementCore.delegate = MpvDelegate(replacementCore)
    mpvCore = replacementCore

    val settled = AtomicBoolean(false)
    val timeout = Runnable {
      if (!settled.compareAndSet(false, true)) return@Runnable
      failMpvReplacementInitialization(
        request.mediaGeneration,
        replacementCore,
        "Timed out recreating compatible player"
      )
    }
    mainHandler.postDelayed(timeout, MPV_FALLBACK_INIT_TIMEOUT_MS)

    try {
      initializeMpvCore(replacementCore) { success ->
        runOnMain {
          if (!settled.compareAndSet(false, true)) return@runOnMain
          mainHandler.removeCallbacks(timeout)
          if (
            generation != sessionGeneration ||
            activity !== act ||
            !usingMpvFallback ||
            mpvCore !== replacementCore
          ) {
            replacementCore.dispose()
            return@runOnMain
          }
          if (!success) {
            failMpvReplacementInitialization(
              request.mediaGeneration,
              replacementCore,
              "Failed to recreate compatible player"
            )
            return@runOnMain
          }

          fallbackInProgress = false
          mpvCoreNeedsReplacement = false
          val next = pendingOpen
          pendingOpen = null
          if (next == null) return@runOnMain
          replacementCore.setPauseIntentForLoad(paused = !next.autoPlay)
          prepareMpvFallback(replacementCore)
          dispatchMpvOpen(next, replacementCore, act, generation)
        }
      }
    } catch (error: Exception) {
      if (settled.compareAndSet(false, true)) {
        mainHandler.removeCallbacks(timeout)
        failMpvReplacementInitialization(
          request.mediaGeneration,
          replacementCore,
          "Failed to recreate compatible player",
          error
        )
      }
    }
  }

  private fun failMpvReplacementInitialization(
    mediaGeneration: Int,
    core: MpvPlayerCore?,
    logMessage: String,
    error: Throwable? = null
  ) {
    if (error == null) {
      Log.e(TAG, logMessage)
    } else {
      Log.e(TAG, logMessage, error)
    }
    if (core != null && mpvCore !== core) return

    fallbackInProgress = false
    usingMpvFallback = false
    backendSwitchPending = false
    mpvCoreNeedsReplacement = false
    mpvForwardGeneration = null
    mpvSignalGate = null
    mpvCore = null
    core?.dispose()
    val failed = pendingOpen
    pendingOpen = null
    failed?.error("FALLBACK_FAILED", "Compatible player failed to initialize")
    emitFallbackErrorOnce(failed?.mediaGeneration ?: mediaGeneration, "Compatible player failed to initialize")
  }

  private fun dispatchMpvOpen(
    request: MediaOpenRequest,
    core: MpvPlayerCore,
    act: Activity,
    generation: Int
  ) {
    inFlightOpen = request
    val settled = AtomicBoolean(false)
    val timeout = Runnable {
      if (!settled.compareAndSet(false, true)) return@Runnable
      val wasActive = inFlightOpen === request
      if (wasActive) inFlightOpen = null
      discardMpvSignals(core, request)
      if (mpvForwardGeneration == request.mediaGeneration) mpvForwardGeneration = null
      request.error("OPEN_TIMEOUT", "Timed out opening media with compatible player")

      val fallbackIsCurrent =
        wasActive &&
          request.mediaGeneration == mediaGeneration &&
          generation == sessionGeneration &&
          activity === act &&
          usingMpvFallback &&
          mpvCore === core
      if (fallbackIsCurrent) {
        failActiveFallback(request.mediaGeneration, "Timed out opening media with MPV fallback")
      } else if (generation == sessionGeneration && activity === act && usingMpvFallback && mpvCore === core) {
        dispatchPendingMpvOpen(core, act, generation)
      }
    }
    mainHandler.postDelayed(timeout, MPV_OPEN_TIMEOUT_MS)

    resolveMpvUri(request.uri, act) { source ->
      if (settled.get()) {
        source.closeIfUnused()
        return@resolveMpvUri
      }
      if (generation != sessionGeneration || activity !== act || !usingMpvFallback || mpvCore !== core) {
        if (!settled.compareAndSet(false, true)) {
          source.closeIfUnused()
          return@resolveMpvUri
        }
        mainHandler.removeCallbacks(timeout)
        source.closeIfUnused()
        if (inFlightOpen === request) inFlightOpen = null
        request.error("NOT_INITIALIZED", "Compatible player is no longer available")
        return@resolveMpvUri
      }
      if (request.mediaGeneration != mediaGeneration) {
        if (!settled.compareAndSet(false, true)) {
          source.closeIfUnused()
          return@resolveMpvUri
        }
        mainHandler.removeCallbacks(timeout)
        source.closeIfUnused()
        if (inFlightOpen === request) inFlightOpen = null
        completeSupersededOpen(request)
        dispatchPendingMpvOpen(core, act, generation)
        return@resolveMpvUri
      }

      core.setPauseIntentForLoad(paused = !request.autoPlay)
      mpvForwardGeneration = request.mediaGeneration
      mpvSignalGate = MpvSignalGate(core, request.mediaGeneration)
      loadMpvMedia(
        core = core,
        uri = source.value,
        headers = request.headers,
        startPositionMs = request.startPositionMs,
        hasStartPosition = request.hasStartPosition,
        autoPlay = request.autoPlay,
        externalSubtitles = request.externalSubtitles
      ) { success ->
        if (!settled.compareAndSet(false, true)) {
          if (!success) source.closeIfUnused()
          return@loadMpvMedia
        }
        mainHandler.removeCallbacks(timeout)
        if (inFlightOpen === request) inFlightOpen = null

        if (request.mediaGeneration != mediaGeneration) {
          if (!success) source.closeIfUnused()
          discardMpvSignals(core, request)
          if (mpvForwardGeneration == request.mediaGeneration) mpvForwardGeneration = null
          completeSupersededOpen(request)
          dispatchPendingMpvOpen(core, act, generation)
          return@loadMpvMedia
        }
        if (generation != sessionGeneration || activity !== act || !usingMpvFallback || mpvCore !== core) {
          if (!success) source.closeIfUnused()
          discardMpvSignals(core, request)
          if (mpvForwardGeneration == request.mediaGeneration) mpvForwardGeneration = null
          request.error("NOT_INITIALIZED", "Compatible player is no longer available")
          return@loadMpvMedia
        }
        if (!success) {
          source.closeIfUnused()
          discardMpvSignals(core, request)
          if (mpvForwardGeneration == request.mediaGeneration) mpvForwardGeneration = null
          request.error("OPEN_FAILED", "Compatible player failed to open media")
          failActiveFallback(request.mediaGeneration, "Failed to open media with MPV fallback")
          return@loadMpvMedia
        }

        if (backendSwitchPending) {
          backendSwitchPending = false
          notifyBackendSwitched()
          Log.i(TAG, "Successfully switched to MPV fallback")
        }
        flushMpvSignals(core, request)
        request.success()
      }
    }
  }

  private fun handleFallbackMpvProperty(
    name: String,
    value: String,
    result: MethodChannel.Result,
    successValue: Any? = null
  ) {
    val currentActivity = activity
    val core = mpvCore
    if (currentActivity == null || core?.isInitialized != true) {
      completeMpvPropertyNotInitialized(result)
      return
    }
    val generation = sessionGeneration
    currentActivity.runOnUiThread {
      if (
        !usingMpvFallback ||
        generation != sessionGeneration ||
        activity !== currentActivity ||
        mpvCore !== core ||
        !core.isInitialized
      ) {
        completeMpvPropertyNotInitialized(result)
        return@runOnUiThread
      }
      pendingMpvProperties[name] = value
      core.setProperty(name, value) { outcome ->
        val fallbackIsCurrent =
          usingMpvFallback &&
            generation == sessionGeneration &&
            activity === currentActivity &&
            mpvCore === core
        val currentOutcome =
          if (fallbackIsCurrent || outcome.isFailure) {
            outcome
          } else {
            Result.failure(CancellationException("MPV fallback unavailable"))
          }
        completeMpvPropertyResult(result, currentOutcome, successValue)
      }
    }
  }

  private fun handlePlay(result: MethodChannel.Result) {
    // A backend handover leaves nothing to command: record the intent on the queued open instead,
    // so the replacement starts the way the caller last asked.
    pendingOpen?.autoPlay = true
    if (usingMpvFallback) {
      handleFallbackMpvProperty("pause", "no", result)
      return
    }
    activity?.runOnUiThread {
      playerCore?.play()
      result.success(null)
    } ?: result.success(null)
  }

  private fun handlePause(result: MethodChannel.Result) {
    // See handlePlay. This direction matters more: the caller is told the pause succeeded, and a
    // queued open that still carried autoPlay would start playing anyway — on a car, that is
    // playback after the vehicle said no.
    pendingOpen?.autoPlay = false
    if (usingMpvFallback) {
      handleFallbackMpvProperty("pause", "yes", result)
      return
    }
    activity?.runOnUiThread {
      playerCore?.pause()
      result.success(null)
    } ?: result.success(null)
  }

  private fun handleStop(result: MethodChannel.Result) {
    activity?.runOnUiThread {
      if (usingMpvFallback) {
        mpvCore?.command(arrayOf("stop"))
        mpvCore?.setVisible(false)
      } else {
        playerCore?.stop()
      }
      result.success(null)
    } ?: result.success(null)
  }

  private fun handleSeek(call: MethodCall, result: MethodChannel.Result) {
    val positionMs = call.argument<Number>("positionMs")?.toLong()

    if (positionMs == null) {
      result.error("INVALID_ARGS", "Missing 'positionMs'", null)
      return
    }

    activity?.runOnUiThread {
      if (usingMpvFallback) {
        val positionSeconds = positionMs / 1000.0
        mpvCore?.command(arrayOf("seek", positionSeconds.toString(), "absolute"))
      } else {
        playerCore?.seekTo(positionMs)
      }
      result.success(null)
    } ?: result.success(null)
  }

  private fun handleSetVolume(call: MethodCall, result: MethodChannel.Result) {
    val volume = call.argument<Number>("volume")?.toFloat()

    if (volume == null) {
      result.error("INVALID_ARGS", "Missing 'volume'", null)
      return
    }

    if (usingMpvFallback) {
      handleFallbackMpvProperty("volume", volume.toString(), result)
      return
    }
    activity?.runOnUiThread {
      playerCore?.setVolume(volume / 100f) // Convert 0-100 to 0-1
      result.success(null)
    } ?: result.success(null)
  }

  private fun handleSetRate(call: MethodCall, result: MethodChannel.Result) {
    val rate = call.argument<Number>("rate")?.toFloat()

    if (rate == null) {
      result.error("INVALID_ARGS", "Missing 'rate'", null)
      return
    }

    if (usingMpvFallback) {
      handleFallbackMpvProperty("speed", rate.toString(), result)
      return
    }
    activity?.runOnUiThread {
      playerCore?.setPlaybackSpeed(rate)
      result.success(null)
    } ?: result.success(null)
  }

  private fun handleSelectAudioTrack(call: MethodCall, result: MethodChannel.Result) {
    val trackId = call.argument<String>("trackId")

    if (trackId == null) {
      result.error("INVALID_ARGS", "Missing 'trackId'", null)
      return
    }

    if (usingMpvFallback) {
      // After fallback, track IDs come from mpv's track-list (already 1-indexed)
      handleFallbackMpvProperty("aid", trackId, result)
      return
    }
    activity?.runOnUiThread {
      playerCore?.selectAudioTrack(trackId)
      result.success(null)
    } ?: result.success(null)
  }

  private fun handleSelectSubtitleTrack(call: MethodCall, result: MethodChannel.Result) {
    val trackId = call.argument<String>("trackId")

    // trackId can be null or "no" to disable subtitles
    if (usingMpvFallback) {
      handleFallbackMpvProperty("sid", trackId ?: "no", result)
      return
    }
    activity?.runOnUiThread {
      playerCore?.selectSubtitleTrack(trackId)
      result.success(null)
    } ?: result.success(null)
  }

  private fun handleAddSubtitleTrack(call: MethodCall, result: MethodChannel.Result) {
    val uri = call.argument<String>("uri")
    val title = call.argument<String>("title")
    val language = call.argument<String>("language")
    val mimeType = call.argument<String>("mimeType")
    val select = call.argument<Boolean>("select") ?: false

    if (uri == null) {
      result.error("INVALID_ARGS", "Missing 'uri'", null)
      return
    }

    activity?.runOnUiThread {
      if (usingMpvFallback) {
        val selectFlag = if (select) "select" else "auto"
        val core = mpvCore
        if (core == null) {
          result.success(null)
        } else {
          core.command(arrayOf("sub-add", uri, selectFlag, title ?: "External")) {
            result.success(null)
          }
        }
      } else {
        playerCore?.addSubtitleTrack(uri, title, language, mimeType, select)
        result.success(null)
      }
    } ?: result.success(null)
  }

  private fun handleSetVisible(call: MethodCall, result: MethodChannel.Result) {
    val visible = call.argument<Boolean>("visible")

    if (visible == null) {
      result.error("INVALID_ARGS", "Missing 'visible'", null)
      return
    }

    activeSurfaceCore?.setVisible(visible)
    result.success(null)
  }

  private fun handleUpdateFrame(result: MethodChannel.Result) {
    activeSurfaceCore?.updateFrame()
    result.success(null)
  }

  private fun handleSetVideoFrameRate(call: MethodCall, result: MethodChannel.Result) {
    val fps = call.argument<Double>("fps")?.toFloat() ?: 0f
    val duration = call.argument<Number>("duration")?.toLong() ?: 0L
    val extraDelayMs = call.argument<Number>("extraDelayMs")?.toLong() ?: 0L
    val videoWidth = call.argument<Number>("videoWidth")?.toInt() ?: 0
    val videoHeight = call.argument<Number>("videoHeight")?.toInt() ?: 0
    val matchResolution = call.argument<Boolean>("matchResolution") ?: false

    Log.d(
      TAG,
      "setVideoFrameRate: fps=$fps, duration=$duration, extraDelayMs=$extraDelayMs, " +
        "video=${videoWidth}x$videoHeight, matchResolution=$matchResolution"
    )
    val core = activeSurfaceCore
    if (core == null) {
      result.success(false)
      return
    }
    core.setVideoFrameRate(fps, duration, extraDelayMs, videoWidth, videoHeight, matchResolution) { switched ->
      result.success(switched)
    }
  }

  private fun handleClearVideoFrameRate(result: MethodChannel.Result) {
    Log.d(TAG, "clearVideoFrameRate")
    activeSurfaceCore?.clearVideoFrameRate()
    result.success(null)
  }

  private fun handleRequestAudioFocus(result: MethodChannel.Result) {
    Log.d(TAG, "requestAudioFocus")
    val granted = activeSurfaceCore?.requestAudioFocus() ?: false
    result.success(granted)
  }

  private fun handleAbandonAudioFocus(result: MethodChannel.Result) {
    Log.d(TAG, "abandonAudioFocus")
    activeSurfaceCore?.abandonAudioFocus()
    result.success(null)
  }

  private fun handleObserveProperty(call: MethodCall, result: MethodChannel.Result) {
    val name = call.argument<String>("name")
    val id = call.argument<Int>("id")
    val format = call.argument<String>("format") ?: "string"

    if (name == null || id == null) {
      result.error("INVALID_ARGS", "Missing 'name' or 'id'", null)
      return
    }

    observedProperties[name] = ObservedProperty(id, format)
    result.success(null)
  }

  private fun handleSetSubtitleStyle(call: MethodCall, result: MethodChannel.Result) {
    val fontSize = call.argument<Number>("fontSize")?.toFloat() ?: 55f
    val textColor = call.argument<String>("textColor") ?: "#FFFFFF"
    val borderSize = call.argument<Number>("borderSize")?.toFloat() ?: 3f
    val borderColor = call.argument<String>("borderColor") ?: "#000000"
    val bgColor = call.argument<String>("bgColor") ?: "#000000"
    val bgOpacity = call.argument<Number>("bgOpacity")?.toInt() ?: 0
    val subtitlePosition = call.argument<Number>("subtitlePosition")?.toInt() ?: 100
    val bold = call.argument<Boolean>("bold") ?: false
    val italic = call.argument<Boolean>("italic") ?: false
    val anchorToScreen = call.argument<Boolean>("anchorToScreen") ?: false

    if (usingMpvFallback) {
      // MPV fallback handles styling via setProperty, no-op here
      result.success(null)
      return
    }

    playerCore?.setSubtitleStyle(fontSize, textColor, borderSize, borderColor, bgColor, bgOpacity, subtitlePosition, bold, italic, anchorToScreen)
    result.success(null)
  }

  private fun handleSetBoxFitMode(call: MethodCall, result: MethodChannel.Result) {
    val mode = call.argument<Number>("mode")?.toInt()
    if (mode == null) {
      result.error("INVALID_ARGS", "Missing 'mode'", null)
      return
    }
    // The MPV-property side (panscan / sub-ass-force-margins / video-aspect-override)
    // is driven from Dart via setProperty and routed through setMpvProperty, which
    // already handles both the fallback and pendingMpvProperties cases.
    if (usingMpvFallback) {
      result.success(null)
      return
    }
    activity?.runOnUiThread {
      playerCore?.setBoxFitMode(mode)
      result.success(null)
    } ?: result.success(null)
  }

  private fun handleSetVideoZoom(call: MethodCall, result: MethodChannel.Result) {
    val scale = call.argument<Number>("scale")?.toDouble()
    if (scale == null) {
      result.error("INVALID_ARGS", "Missing 'scale'", null)
      return
    }
    if (usingMpvFallback) {
      result.success(null)
      return
    }
    activity?.runOnUiThread {
      playerCore?.setVideoZoom(scale)
      result.success(null)
    } ?: result.success(null)
  }

  private fun handleSetDvConversionMode(call: MethodCall, result: MethodChannel.Result) {
    val mode = call.argument<String>("mode")
    if (mode == null) {
      result.error("INVALID_ARGS", "Missing 'mode'", null)
      return
    }
    if (usingMpvFallback) {
      // The fallback core owns the property now; dropping the write would
      // strand it on the mode ExoPlayer started with.
      val core = mpvCore
      if (core == null) {
        result.success(false)
        return
      }
      dvConversionMode = mode
      core.setProperty("dv-conversion-mode", mode) { outcome ->
        completeMpvPropertyResult(result, outcome, successValue = true)
      }
      return
    }
    activity?.runOnUiThread {
      val handled = playerCore?.setDebugDvConversionMode(mode) == true
      if (handled) {
        // Keep the fallback seed on the value ExoPlayer is actually running.
        dvConversionMode = mode
        result.success(true)
      } else {
        result.error("INVALID_ARGS", "Invalid DV conversion mode: $mode", null)
      }
    } ?: result.error("NO_ACTIVITY", "Activity not available", null)
  }

  private fun handleSetAudioNormalization(call: MethodCall, result: MethodChannel.Result) {
    val enabled = call.argument<Boolean>("enabled")
    if (enabled == null) {
      result.error("INVALID_ARGS", "Missing 'enabled'", null)
      return
    }
    if (usingMpvFallback) {
      // mpv applies loudnorm via the 'af' property the Dart layer also sends.
      result.success(true)
      return
    }
    activity?.runOnUiThread {
      playerCore?.setAudioNormalization(enabled)
      result.success(true)
    } ?: result.error("NO_ACTIVITY", "Activity not available", null)
  }

  private fun handleSetAudioDownmix(call: MethodCall, result: MethodChannel.Result) {
    val enabled = call.argument<Boolean>("enabled")
    if (enabled == null) {
      result.error("INVALID_ARGS", "Missing 'enabled'", null)
      return
    }
    val centerBoostDb = call.argument<Int>("centerBoostDb") ?: 0
    val normalize = call.argument<Boolean>("normalize") ?: true
    if (usingMpvFallback) {
      // mpv applies downmix via the audio-channels/audio-swresample-o
      // properties the Dart layer also sends through setMpvProperty.
      result.success(true)
      return
    }
    activity?.runOnUiThread {
      playerCore?.setAudioDownmix(enabled, centerBoostDb, normalize)
      result.success(true)
    } ?: result.error("NO_ACTIVITY", "Activity not available", null)
  }

  private fun handleSetAudioPassthrough(call: MethodCall, result: MethodChannel.Result) {
    val enabled = call.argument<Boolean>("enabled")
    if (enabled == null) {
      result.error("INVALID_ARGS", "Missing 'enabled'", null)
      return
    }
    audioPassthroughRequested = enabled
    val currentActivity = activity
    if (usingMpvFallback) {
      val audioSpdif = if (enabled && currentActivity != null) supportedMpvSpdifCodecs(currentActivity) else ""
      handleFallbackMpvProperty("audio-spdif", audioSpdif, result, true)
      return
    }
    currentActivity?.runOnUiThread {
      playerCore?.setAudioPassthrough(enabled)
      result.success(true)
    } ?: result.error("NO_ACTIVITY", "Activity not available", null)
  }

  private fun handleSetMpvProperty(call: MethodCall, result: MethodChannel.Result) {
    val name = call.argument<String>("name")
    val value = call.argument<String>("value")

    if (name == null || value == null) {
      result.error("INVALID_ARGS", "Missing 'name' or 'value'", null)
      return
    }

    if (usingMpvFallback) {
      handleFallbackMpvProperty(name, value, result)
      return
    }

    // Apply sync offsets to ExoPlayer when active
    when (name) {
      "audio-delay" -> playerCore?.setAudioDelay(value.toDoubleOrNull() ?: 0.0)
      "sub-delay" -> playerCore?.setSubtitleDelay(value.toDoubleOrNull() ?: 0.0)
      // mpv semantics mirrored on the libass overlay: anchor non-positioned ASS
      // events to the visible screen (Dart sets 'yes' for cover mode / zoom > 1)
      "sub-ass-force-margins" -> playerCore?.setAssForceMargins(value == "yes")
      "force-seekable" -> playerCore?.setForceSeekable(value == "yes")
    }

    // Before fallback this is queue acceptance, not a completed MPV write.
    pendingMpvProperties[name] = value
    result.success(null)
  }

  private fun handleGetStats(result: MethodChannel.Result) {
    if (usingMpvFallback) {
      Thread {
        val stats = try {
          getMpvStats()
        } catch (error: Throwable) {
          Log.w(TAG, "Failed to collect mpv fallback stats", error)
          mapOf("playerType" to "mpv")
        }
        // Platform-channel replies must return to Android's platform thread.
        // Do not depend on an Activity: it may detach while this work runs.
        mainHandler.post { result.success(stats) }
      }.start()
    } else {
      activity?.runOnUiThread {
        val coreStats = playerCore?.getStats() ?: emptyMap()
        result.success(coreStats + mapOf("playerType" to "exoplayer"))
      } ?: result.success(mapOf("playerType" to "unknown"))
    }
  }

  /**
   * Get playback stats from MPV when in fallback mode.
   * Queries relevant MPV properties and returns them in a map format
   * compatible with the performance overlay.
   */
  private fun getMpvStats(): Map<String, Any?> = mpvCore?.getStats() ?: mapOf("playerType" to "mpv")

  // PiP Mode handling

  fun onPipModeChanged(isInPipMode: Boolean) {
    activity?.runOnUiThread {
      activeSurfaceCore?.onPipModeChanged(isInPipMode)
    }
  }

  // ExoPlayerDelegate

  override fun onPropertyChange(name: String, value: Any?) {
    val propId = observedProperties[name]?.id ?: return
    channels.emitProperty(propId, value)
  }

  override fun onEvent(name: String, data: Map<String, Any>?) {
    channels.emitEvent(name, data)
  }

  private fun notifyBackendSwitched() {
    channels.emitEvent("backend-switched")
  }

  private fun appendExternalSubtitleOptions(
    options: MutableList<String>,
    externalSubtitles: List<Map<String, Any?>>?
  ) {
    val escapedUris = externalSubtitles.orEmpty()
      .mapNotNull { it["uri"] as? String }
      .filter { it.isNotEmpty() }
      .distinct()
      .map(::escapeMpvPathListEntry)
      .toList()

    if (escapedUris.isEmpty()) return

    val pathList = escapedUris.joinToString(":")
    options.add("sub-files=%${pathList.toByteArray(Charsets.UTF_8).size}%$pathList")
  }

  private fun escapeMpvPathListEntry(value: String): String = value.replace("\\", "\\\\").replace(":", "\\:")

  private fun appendHttpHeaderOptions(options: MutableList<String>, headers: Map<String, String>?) {
    if (headers.isNullOrEmpty()) return

    options.add("http-header-fields-clr=")
    headers.forEach { (key, value) ->
      val header = "$key: $value"
      options.add("http-header-fields-append=%${header.toByteArray(Charsets.UTF_8).size}%$header")
    }
  }

  /**
   * Decode intent for a fallback mpv core, read from the `hwdec` value Dart
   * already wrote for this session. It picks the core's initial vo chain
   * ([MpvPlayerCore.initialVideoOutput]), so a software-decoding session must
   * not inherit the hardware default: only gpu-next applies Dolby Vision RPU
   * reshaping, and a session that asked for software decode is usually the
   * one that needs it.
   */
  private fun fallbackHardwareDecoding(): Boolean = pendingMpvProperties["hwdec"]?.let { it != "no" } ?: true

  /**
   * Configure a freshly initialized MPV fallback core: replay the properties
   * and observers Dart registered against the ExoPlayer session, then resume
   * the media at the handoff position. Runs in MpvPlayerCore.initialize's
   * completion callback on the main thread.
   */
  private fun prepareMpvFallback(core: MpvPlayerCore) {
    val pendingProps = pendingMpvProperties.filterKeys { it != "audio-spdif" }.toList()
    val observedProps = observedProperties.toList()

    // hwdec is not seeded here — Dart's write in pendingMpvProperties is the
    // single source of the fallback core's chain.
    core.setProperty("ao", "audiotrack")
    // Dart routes dv-conversion-mode through setDvConversionMode, so unlike
    // hwdec it never reaches pendingMpvProperties.
    core.setProperty("dv-conversion-mode", dvConversionMode)

    for ((propName, propValue) in pendingProps) {
      core.setProperty(propName, propValue) { outcome ->
        if (outcome.isFailure) {
          Log.w(TAG, "Failed to replay queued MPV property")
        }
      }
    }

    // Derived last so it wins over any replayed value, and resolved here rather than
    // when the setting was applied: the HDMI/AVR route can change between ExoPlayer
    // startup and the moment mpv takes over (#1703).
    val audioSpdif = activity
      ?.takeIf { audioPassthroughRequested }
      ?.let(::supportedMpvSpdifCodecs)
      .orEmpty()
    pendingMpvProperties["audio-spdif"] = audioSpdif
    core.setProperty("audio-spdif", audioSpdif)

    for ((propName, observed) in observedProps) {
      core.observeProperty(propName, observed.format)
    }

    core.setVisible(true)

    Thread {
      val peakDetection = core.getProperty("hdr-compute-peak")
      if (peakDetection == "no") {
        Log.i(TAG, "No compute shaders — overriding tone-mapping to reinhard")
        core.setProperty("tone-mapping", "reinhard")
        core.setProperty("tone-mapping-param", "0.7")
        core.setProperty("tone-mapping-mode", "luma")
      }
    }.start()

    core.requestAudioFocus()
  }

  private fun emitFallbackErrorOnce(mediaGeneration: Int, message: String) {
    if (mediaGeneration != this.mediaGeneration || terminalEventGeneration == mediaGeneration) return
    terminalEventGeneration = mediaGeneration
    onEvent("end-file", mapOf("reason" to "error", "message" to message))
  }

  private fun failActiveFallback(fallbackGeneration: Int, logMessage: String, error: Throwable? = null) {
    if (error == null) {
      Log.e(TAG, logMessage)
    } else {
      Log.e(TAG, logMessage, error)
    }
    val core = mpvCore
    mpvCore = null
    core?.dispose()
    usingMpvFallback = false
    fallbackInProgress = false
    backendSwitchPending = false
    mpvForwardGeneration = null
    mpvCoreNeedsReplacement = false
    mpvSignalGate = null
    fallbackMediaGeneration = null

    val pending = pendingOpen
    pendingOpen = null
    val inFlight = inFlightOpen
    inFlightOpen = null
    val activeGeneration = pending?.mediaGeneration ?: inFlight?.mediaGeneration ?: fallbackGeneration
    pending?.error("FALLBACK_FAILED", "Compatible player failed to initialize")
    inFlight?.error("FALLBACK_FAILED", "Compatible player failed to initialize")
    emitFallbackErrorOnce(activeGeneration, "Compatible player failed to initialize")
  }

  override fun onFormatUnsupported(
    mediaGeneration: Int,
    uri: String,
    headers: Map<String, String>?,
    positionMs: Long,
    playWhenReady: Boolean,
    errorMessage: String
  ): Boolean {
    if (mediaGeneration != this.mediaGeneration) {
      Log.d(TAG, "Ignoring stale fallback request for media generation $mediaGeneration")
      return true
    }
    if (usingMpvFallback || fallbackInProgress) {
      Log.w(TAG, "Fallback already active/in-progress, coalescing duplicate request")
      return true
    }

    val currentActivity = activity ?: return false
    val fallbackRequest = MediaOpenRequest(
      mediaGeneration = mediaGeneration,
      uri = uri,
      headers = headers,
      startPositionMs = positionMs,
      hasStartPosition = positionMs > 0L,
      autoPlay = playWhenReady,
      isLive = false,
      externalSubtitles = currentExternalSubtitles?.map { it.toMap() },
      // The mpv fallback core paces frames itself; the rate only gates ExoPlayer tunneling.
      contentFrameRate = -1f,
      result = null
    )
    fallbackInProgress = true
    fallbackMediaGeneration = mediaGeneration

    Log.i(TAG, "ExoPlayer error, switching to MPV fallback at ${positionMs}ms: $errorMessage")
    if (debugLoggingEnabled) {
      onEvent(
        "log-message",
        mapOf(
          "prefix" to "fallback",
          "level" to "warn",
          "text" to "Switching to MPV at ${positionMs}ms: $errorMessage"
        )
      )
    }

    onPropertyChange("paused-for-cache", true)
    onPropertyChange("pause", true)

    currentActivity.runOnUiThread {
      try {
        playerCore?.dispose()
        playerCore = null
        mpvCore?.dispose()
        mpvCore = null
        usingMpvFallback = false

        val generation = sessionGeneration
        mainHandler.post {
          if (generation != sessionGeneration) return@post
          val act = activity ?: return@post

          try {
            val core = createMpvCore(act)
            core.delegate = MpvDelegate(core)
            mpvCore = core

            val initializationSettled = AtomicBoolean(false)
            val timeout = Runnable {
              if (!initializationSettled.compareAndSet(false, true)) return@Runnable
              if (generation != sessionGeneration || mpvCore !== core) {
                if (mpvCore === core) mpvCore = null
                core.dispose()
                return@Runnable
              }
              failActiveFallback(mediaGeneration, "Timed out initializing MPV fallback")
            }
            mainHandler.postDelayed(timeout, MPV_FALLBACK_INIT_TIMEOUT_MS)

            try {
              initializeMpvCore(core) onInitialized@{ success ->
                if (!initializationSettled.compareAndSet(false, true)) return@onInitialized
                mainHandler.removeCallbacks(timeout)
                if (generation != sessionGeneration || mpvCore !== core) {
                  if (mpvCore === core) mpvCore = null
                  core.dispose()
                  return@onInitialized
                }
                if (!success) {
                  failActiveFallback(mediaGeneration, "Failed to initialize MPV fallback")
                  return@onInitialized
                }

                usingMpvFallback = true
                fallbackInProgress = false
                fallbackMediaGeneration = null
                backendSwitchPending = true
                val request = pendingOpen?.also { pendingOpen = null } ?: fallbackRequest
                if (request.mediaGeneration != this.mediaGeneration) {
                  completeSupersededOpen(request)
                  return@onInitialized
                }
                core.setPauseIntentForLoad(paused = !request.autoPlay)
                prepareMpvFallback(core)
                dispatchMpvOpen(request, core, act, generation)
              }
            } catch (e: Exception) {
              if (initializationSettled.compareAndSet(false, true)) {
                mainHandler.removeCallbacks(timeout)
                failActiveFallback(mediaGeneration, "Failed to initialize MPV fallback", e)
              }
            }
          } catch (e: Exception) {
            failActiveFallback(mediaGeneration, "Failed to switch to MPV fallback", e)
          }
        }
      } catch (e: Exception) {
        failActiveFallback(mediaGeneration, "Failed to switch to MPV fallback", e)
      }
    }

    return true
  }
}
