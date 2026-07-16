package com.edde746.plezy.exoplayer

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.util.Log
import com.edde746.plezy.libass.media.AssHandler
import com.edde746.plezy.mpv.MpvPlayerCore
import com.edde746.plezy.shared.MpvContentUriResolver
import com.edde746.plezy.shared.PlayerChannelBinding
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ExoPlayerPlugin :
  FlutterPlugin,
  MethodChannel.MethodCallHandler,
  EventChannel.StreamHandler,
  ActivityAware,
  ExoPlayerDelegate {

  companion object {
    private const val TAG = "ExoPlayerPlugin"
    private const val METHOD_CHANNEL = "com.plezy/exo_player"
  }

  private val channels = PlayerChannelBinding(METHOD_CHANNEL, this, this, TAG)
  private val mainHandler get() = channels.mainHandler
  private var playerCore: ExoPlayerCore? = null
  private var mpvCore: MpvPlayerCore? = null // MPV fallback player
  private var usingMpvFallback: Boolean = false
  private var fallbackInProgress: Boolean = false
  private var activity: Activity? = null
  private var activityBinding: ActivityPluginBinding? = null

  // Every Dart observeProperty registration, kept so an ExoPlayer→MPV
  // fallback can re-observe exactly what Dart asked for instead of
  // maintaining a parallel hard-coded list.
  private data class ObservedProperty(val id: Int, val format: String)
  private val observedProperties = LinkedHashMap<String, ObservedProperty>()

  private var configuredBufferSizeBytes: Int? = null

  private var sessionGeneration = 0
  private var debugLoggingEnabled: Boolean = false

  // mpv properties set while ExoPlayer is active (including before
  // initialize — Dart queues its startup properties first), replayed into a
  // fallback MPV core. Keyed by property name (last write wins) and cleared
  // only at real session boundaries (dispose, engine detach, open while the
  // fallback is already active) so one playback's properties never leak into
  // the next session's fallback.
  private val pendingMpvProperties = LinkedHashMap<String, String>()
  private var currentExternalSubtitles: List<Map<String, Any?>>? = null

  // FlutterPlugin

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channels.attach(binding)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channels.detach()
  }

  // ActivityAware

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    activityBinding = binding
    Log.d(TAG, "Attached to activity")
  }

  override fun onDetachedFromActivity() {
    sessionGeneration++
    playerCore?.dispose()
    playerCore = null
    mpvCore?.dispose()
    mpvCore = null
    usingMpvFallback = false
    fallbackInProgress = false
    currentExternalSubtitles = null
    pendingMpvProperties.clear()
    activity = null
    activityBinding = null
    Log.d(TAG, "Detached from activity")
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    activityBinding = binding
    Log.d(TAG, "Reattached to activity for config changes")
  }

  override fun onDetachedFromActivityForConfigChanges() {
    sessionGeneration++
    fallbackInProgress = false
    activity = null
    activityBinding = null
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
      "dispose" -> handleDispose(result)
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
      "getHeapSize" -> {
        val am = activity?.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
        result.success(am?.largeMemoryClass ?: 0)
      }
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

    if (playerCore?.isInitialized == true) {
      Log.d(TAG, "Already initialized")
      result.success(true)
      return
    }

    val bufferSizeBytes = call.argument<Int>("bufferSizeBytes")
    val tunnelingEnabled = call.argument<Boolean>("tunnelingEnabled") ?: true
    val dvConversionMode = call.argument<String>("dvConversionMode") ?: "auto"
    val audioPassthroughEnabled = call.argument<Boolean>("audioPassthroughEnabled") ?: false
    val assVideoLatencyFrames = call.argument<Int>("assVideoLatencyFrames") ?: 0
    val subtitleRenderScale = call.argument<Double>("subtitleRenderScale")?.toFloat() ?: 1.0f
    configuredBufferSizeBytes = bufferSizeBytes
    // Global libass overlay render scale — set before the player/handler is built below so the
    // first frame-size apply already uses it.
    AssHandler.setRenderScale(subtitleRenderScale)

    currentActivity.runOnUiThread {
      sessionGeneration++
      // Do NOT clear pendingMpvProperties here: Dart queues its startup
      // properties (sub-ass, subtitle fonts, ...) before initialize, and the
      // fallback replay in setupMpvFallback needs them. Dispose/detach clear.

      if (mpvCore != null || fallbackInProgress) {
        mpvCore?.dispose()
        mpvCore = null
        usingMpvFallback = false
        fallbackInProgress = false
      }

      try {
        val core = ExoPlayerCore(currentActivity).apply {
          delegate = this@ExoPlayerPlugin
          this.debugLoggingEnabled = this@ExoPlayerPlugin.debugLoggingEnabled
        }
        playerCore = core
        val success = core.initialize(
          bufferSizeBytes = bufferSizeBytes,
          tunnelingEnabled = tunnelingEnabled,
          audioPassthroughEnabled = audioPassthroughEnabled
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

  private fun handleDispose(result: MethodChannel.Result) {
    activity?.runOnUiThread {
      sessionGeneration++
      playerCore?.dispose()
      playerCore = null
      mpvCore?.dispose()
      mpvCore = null
      usingMpvFallback = false
      fallbackInProgress = false
      currentExternalSubtitles = null
      pendingMpvProperties.clear()
      Log.d(TAG, "Disposed")
      result.success(null)
    } ?: result.success(null)
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

    if (uri == null) {
      result.error("INVALID_ARGS", "Missing 'uri'", null)
      return
    }
    val currentActivity = activity
    if (currentActivity == null) {
      result.error("NO_ACTIVITY", "Activity not available", null)
      return
    }
    val externalSubtitleSnapshot = externalSubtitles?.map { it.toMap() }
    currentExternalSubtitles = externalSubtitleSnapshot

    // Only clear pending MPV state when MPV is the active backend. A same-core
    // MPV reload must not inherit a fallback switch that was armed for the
    // previous load. When ExoPlayer is active, keep queued properties for a
    // potential ExoPlayer→MPV fallback.
    if (usingMpvFallback) {
      pendingMpvProperties.clear()
      val generation = sessionGeneration
      MpvContentUriResolver.resolve(uri, currentActivity.contentResolver, mainHandler) { source ->
        if (generation != sessionGeneration || activity !== currentActivity || !usingMpvFallback) {
          source.closeIfUnused()
          result.success(null)
          return@resolve
        }
        loadMpvMedia(
          source.value,
          headers,
          startPositionMs,
          hasStartPosition,
          autoPlay,
          externalSubtitleSnapshot
        )
        result.success(null)
      }
      return
    }

    currentActivity.runOnUiThread {
      playerCore?.open(uri, headers, startPositionMs, autoPlay, isLive, externalSubtitleSnapshot)
      result.success(null)
    }
  }

  private fun loadMpvMedia(
    uri: String,
    headers: Map<String, String>?,
    startPositionMs: Long,
    hasStartPosition: Boolean,
    autoPlay: Boolean,
    externalSubtitles: List<Map<String, Any?>>?
  ) {
    val startSeconds = startPositionMs / 1000.0
    val options = mutableListOf<String>()
    options.add(if (hasStartPosition && startPositionMs > 0L) "start=$startSeconds" else "start=none")
    if (!autoPlay) options.add("pause=yes")
    options.add("sid=no")
    options.add("secondary-sid=no")
    appendExternalSubtitleOptions(options, externalSubtitles)
    appendHttpHeaderOptions(options, headers)
    val optionsStr = options.joinToString(",")
    mpvCore?.command(arrayOf("loadfile", uri, "replace", "-1", optionsStr)) { success ->
      if (success && autoPlay) {
        mpvCore?.setProperty("pause", "no")
      }
    }
  }

  private fun handlePlay(result: MethodChannel.Result) {
    activity?.runOnUiThread {
      if (usingMpvFallback) {
        mpvCore?.setProperty("pause", "no")
      } else {
        playerCore?.play()
      }
      result.success(null)
    } ?: result.success(null)
  }

  private fun handlePause(result: MethodChannel.Result) {
    activity?.runOnUiThread {
      if (usingMpvFallback) {
        mpvCore?.setProperty("pause", "yes")
      } else {
        playerCore?.pause()
      }
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

    activity?.runOnUiThread {
      if (usingMpvFallback) {
        mpvCore?.setProperty("volume", volume.toString())
      } else {
        playerCore?.setVolume(volume / 100f) // Convert 0-100 to 0-1
      }
      result.success(null)
    } ?: result.success(null)
  }

  private fun handleSetRate(call: MethodCall, result: MethodChannel.Result) {
    val rate = call.argument<Number>("rate")?.toFloat()

    if (rate == null) {
      result.error("INVALID_ARGS", "Missing 'rate'", null)
      return
    }

    activity?.runOnUiThread {
      if (usingMpvFallback) {
        mpvCore?.setProperty("speed", rate.toString())
      } else {
        playerCore?.setPlaybackSpeed(rate)
      }
      result.success(null)
    } ?: result.success(null)
  }

  private fun handleSelectAudioTrack(call: MethodCall, result: MethodChannel.Result) {
    val trackId = call.argument<String>("trackId")

    if (trackId == null) {
      result.error("INVALID_ARGS", "Missing 'trackId'", null)
      return
    }

    activity?.runOnUiThread {
      if (usingMpvFallback) {
        // After fallback, track IDs come from mpv's track-list (already 1-indexed)
        mpvCore?.setProperty("aid", trackId)
      } else {
        playerCore?.selectAudioTrack(trackId)
      }
      result.success(null)
    } ?: result.success(null)
  }

  private fun handleSelectSubtitleTrack(call: MethodCall, result: MethodChannel.Result) {
    val trackId = call.argument<String>("trackId")

    // trackId can be null or "no" to disable subtitles
    activity?.runOnUiThread {
      if (usingMpvFallback) {
        mpvCore?.setProperty("sid", trackId ?: "no")
      } else {
        playerCore?.selectSubtitleTrack(trackId)
      }
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

    if (usingMpvFallback) {
      mpvCore?.setVisible(visible)
    } else {
      playerCore?.setVisible(visible)
    }
    result.success(null)
  }

  private fun handleUpdateFrame(result: MethodChannel.Result) {
    if (usingMpvFallback) {
      mpvCore?.updateFrame()
    } else {
      playerCore?.updateFrame()
    }
    result.success(null)
  }

  private fun handleSetVideoFrameRate(call: MethodCall, result: MethodChannel.Result) {
    val fps = call.argument<Double>("fps")?.toFloat() ?: 0f
    val duration = call.argument<Number>("duration")?.toLong() ?: 0L
    val extraDelayMs = call.argument<Number>("extraDelayMs")?.toLong() ?: 0L
    val videoWidth = call.argument<Number>("videoWidth")?.toInt() ?: 0
    val videoHeight = call.argument<Number>("videoHeight")?.toInt() ?: 0

    Log.d(TAG, "setVideoFrameRate: fps=$fps, duration=$duration, extraDelayMs=$extraDelayMs, video=${videoWidth}x$videoHeight")
    val onComplete: (Boolean) -> Unit = { switched -> result.success(switched) }
    if (usingMpvFallback) {
      val core = mpvCore
      if (core == null) {
        result.success(false)
      } else {
        core.setVideoFrameRate(fps, duration, extraDelayMs, videoWidth, videoHeight, onComplete)
      }
    } else {
      val core = playerCore
      if (core == null) {
        result.success(false)
      } else {
        core.setVideoFrameRate(fps, duration, extraDelayMs, videoWidth, videoHeight, onComplete)
      }
    }
  }

  private fun handleClearVideoFrameRate(result: MethodChannel.Result) {
    Log.d(TAG, "clearVideoFrameRate")
    if (usingMpvFallback) {
      mpvCore?.clearVideoFrameRate()
    } else {
      playerCore?.clearVideoFrameRate()
    }
    result.success(null)
  }

  private fun handleRequestAudioFocus(result: MethodChannel.Result) {
    Log.d(TAG, "requestAudioFocus")
    val granted = if (usingMpvFallback) {
      mpvCore?.requestAudioFocus() ?: false
    } else {
      playerCore?.requestAudioFocus() ?: false
    }
    result.success(granted)
  }

  private fun handleAbandonAudioFocus(result: MethodChannel.Result) {
    Log.d(TAG, "abandonAudioFocus")
    if (usingMpvFallback) {
      mpvCore?.abandonAudioFocus()
    } else {
      playerCore?.abandonAudioFocus()
    }
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

    if (usingMpvFallback) {
      // MPV fallback handles styling via setProperty, no-op here
      result.success(null)
      return
    }

    playerCore?.setSubtitleStyle(fontSize, textColor, borderSize, borderColor, bgColor, bgOpacity, subtitlePosition, bold, italic)
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
      result.success(false)
      return
    }
    activity?.runOnUiThread {
      val handled = playerCore?.setDebugDvConversionMode(mode) == true
      if (handled) {
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
    val audioSpdif = if (enabled) "ac3,eac3,dts,dts-hd,truehd" else ""
    pendingMpvProperties["audio-spdif"] = audioSpdif
    if (usingMpvFallback) {
      mpvCore?.setProperty("audio-spdif", audioSpdif)
      result.success(true)
      return
    }
    activity?.runOnUiThread {
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

    // Apply sync offsets to ExoPlayer when active
    if (!usingMpvFallback) {
      when (name) {
        "audio-delay" -> playerCore?.setAudioDelay(value.toDoubleOrNull() ?: 0.0)
        "sub-delay" -> playerCore?.setSubtitleDelay(value.toDoubleOrNull() ?: 0.0)
        // mpv semantics mirrored on the libass overlay: anchor non-positioned ASS
        // events to the visible screen (Dart sets 'yes' for cover mode / zoom > 1)
        "sub-ass-force-margins" -> playerCore?.setAssForceMargins(value == "yes")
        "force-seekable" -> playerCore?.setForceSeekable(value == "yes")
      }
    }

    if (usingMpvFallback) {
      mpvCore?.setProperty(name, value)
    } else {
      // Store for later application if ExoPlayer falls back to MPV
      pendingMpvProperties[name] = value
    }
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
      if (usingMpvFallback) {
        mpvCore?.onPipModeChanged(isInPipMode)
      } else {
        playerCore?.onPipModeChanged(isInPipMode)
      }
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
   * Configure a freshly initialized MPV fallback core: replay the properties
   * and observers Dart registered against the ExoPlayer session, then resume
   * the media at the handoff position. Runs in MpvPlayerCore.initialize's
   * completion callback on the main thread.
   */
  private fun setupMpvFallback(
    core: MpvPlayerCore,
    act: Activity,
    uri: String,
    headers: Map<String, String>?,
    positionMs: Long,
    externalSubtitles: List<Map<String, Any?>>?,
    playWhenReady: Boolean,
    generation: Int
  ) {
    // Snapshot Dart-registered state on main thread before clearing.
    val pendingProps = pendingMpvProperties.toList()
    pendingMpvProperties.clear()
    val observedProps = observedProperties.toList()
    val bufferSize = configuredBufferSizeBytes

    MpvContentUriResolver.resolve(uri, act.contentResolver, mainHandler) { source ->
      if (generation != sessionGeneration || mpvCore !== core || activity !== act || !usingMpvFallback) {
        source.closeIfUnused()
        core.dispose()
        return@resolve
      }

      // Configure basic MPV properties for Plex playback.
      core.setProperty("hwdec", "mediacodec,mediacodec-copy")
      core.setProperty("vo", "gpu")
      core.setProperty("ao", "audiotrack")

      if (bufferSize != null && bufferSize > 0) {
        core.setProperty("demuxer-max-bytes", bufferSize.toString())
      }

      for ((propName, propValue) in pendingProps) {
        core.setProperty(propName, propValue)
      }

      // Re-observe exactly what Dart registered via observeProperty, so the
      // event stream keeps flowing for every property the Dart side consumes.
      for ((propName, observed) in observedProps) {
        core.observeProperty(propName, observed.format)
      }

      core.setVisible(true)

      val startSeconds = positionMs / 1000.0
      val options = mutableListOf<String>()
      options.add(if (positionMs > 0L) "start=$startSeconds" else "start=none")
      if (!playWhenReady) options.add("pause=yes")
      options.add("sid=no")
      options.add("secondary-sid=no")
      appendExternalSubtitleOptions(options, externalSubtitles)
      appendHttpHeaderOptions(options, headers)
      val optionsStr = options.joinToString(",")
      notifyBackendSwitched()
      core.command(arrayOf("loadfile", source.value, "replace", "-1", optionsStr))

      // On GPUs without compute shaders, MPV can't do dynamic peak detection
      // and spline tone-mapping produces dim/washed-out results with extreme
      // static HDR peak metadata. Use reinhard which handles this better.
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
      Log.i(TAG, "Successfully switched to MPV fallback")
    }
  }

  override fun onFormatUnsupported(
    uri: String,
    headers: Map<String, String>?,
    positionMs: Long,
    playWhenReady: Boolean,
    errorMessage: String
  ): Boolean {
    if (usingMpvFallback || fallbackInProgress) {
      Log.w(TAG, "Fallback already active/in-progress, ignoring duplicate request")
      return true
    }

    val currentActivity = activity ?: return false
    val fallbackExternalSubtitles = currentExternalSubtitles?.map { it.toMap() }
    fallbackInProgress = true

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

    currentActivity.runOnUiThread {
      try {
        // Dispose ExoPlayer
        playerCore?.dispose()
        playerCore = null
        mpvCore?.dispose()
        mpvCore = null
        usingMpvFallback = false // Clear before handoff

        val generation = sessionGeneration

        mainHandler.post {
          if (generation != sessionGeneration) {
            fallbackInProgress = false
            return@post
          }
          val act = activity
          if (act == null) {
            fallbackInProgress = false
            return@post
          }

          try {
            val core = MpvPlayerCore(act).apply {
              delegate = this@ExoPlayerPlugin
            }
            mpvCore = core // publish so dispose/init can reach it

            core.initialize { success ->
              if (generation != sessionGeneration) {
                if (mpvCore === core) {
                  core.dispose()
                  mpvCore = null
                }
                fallbackInProgress = false
                return@initialize
              }
              if (!success) {
                if (mpvCore === core) {
                  core.dispose()
                  mpvCore = null
                }
                fallbackInProgress = false
                Log.e(TAG, "Failed to initialize MPV fallback")
                onEvent("end-file", mapOf("reason" to "error", "message" to "Fallback failed: $errorMessage"))
                return@initialize
              }

              usingMpvFallback = true
              fallbackInProgress = false

              setupMpvFallback(core, act, uri, headers, positionMs, fallbackExternalSubtitles, playWhenReady, generation)
            }
          } catch (e: Exception) {
            fallbackInProgress = false
            Log.e(TAG, "Failed to switch to MPV fallback", e)
            onEvent("end-file", mapOf("reason" to "error", "message" to "Fallback failed: ${e.message}"))
          }
        }
      } catch (e: Exception) {
        fallbackInProgress = false
        Log.e(TAG, "Failed to switch to MPV fallback", e)
        onEvent("end-file", mapOf("reason" to "error", "message" to "Fallback failed: ${e.message}"))
      }
    }

    return true // Fallback is being handled
  }
}
