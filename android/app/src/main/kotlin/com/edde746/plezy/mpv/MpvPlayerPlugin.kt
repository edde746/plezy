package com.edde746.plezy.mpv

import android.app.Activity
import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

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

  private lateinit var methodChannel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private var eventSink: EventChannel.EventSink? = null
  private var playerCore: MpvPlayerCore? = null
  private var activity: Activity? = null
  private var activityBinding: ActivityPluginBinding? = null
  private var applicationContext: Context? = null
  private val nameToId = mutableMapOf<String, Int>()
  private var sessionGeneration = 0

  private val mainHandler = Handler(Looper.getMainLooper())

  /** Same semantics as Activity.runOnUiThread, without needing an Activity. */
  private fun runOnMain(block: () -> Unit) {
    if (Looper.myLooper() == Looper.getMainLooper()) block() else mainHandler.post(block)
  }

  // Pending `MethodChannel.Result`s for an init that is currently in flight.
  // Concurrent `invoke('initialize')` calls share the same outcome instead
  // of each tearing down the in-flight core and starting their own — which
  // was the root cause of #930.
  private val pendingInitResults = mutableListOf<MethodChannel.Result>()

  @Volatile private var isInitializing = false

  // FlutterPlugin

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = binding.applicationContext

    methodChannel = MethodChannel(binding.binaryMessenger, channelBase)
    methodChannel.setMethodCallHandler(this)

    eventChannel = EventChannel(binding.binaryMessenger, "$channelBase/events")
    eventChannel.setStreamHandler(this)

    Log.d(tag, "Attached to engine")
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    if (audioOnly) {
      // The audio core is not activity-bound; engine detach is its terminal
      // native lifecycle event (mirrors the video core's activity detach).
      disposeCoreForTeardown()
    }
    applicationContext = null
    Log.d(tag, "Detached from engine")
  }

  private fun disposeCoreForTeardown() {
    ++sessionGeneration
    playerCore?.dispose()
    playerCore = null
    // Any in-flight init callback would never fire (its scope is cancelled
    // by dispose), so close out queued callers explicitly.
    completePendingInits(success = false)
  }

  // ActivityAware

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    activityBinding = binding
    Log.d(tag, "Attached to activity")
  }

  override fun onDetachedFromActivity() {
    // The audio-only core deliberately outlives the activity (background
    // music); it is torn down on engine detach / Dart dispose instead.
    if (!audioOnly) {
      disposeCoreForTeardown()
    }
    activity = null
    activityBinding = null
    Log.d(tag, "Detached from activity")
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    activityBinding = binding
    Log.d(tag, "Reattached to activity for config changes")
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
    activityBinding = null
    Log.d(tag, "Detached from activity for config changes")
  }

  // EventChannel.StreamHandler

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
    Log.d(tag, "Event stream connected")
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
    Log.d(tag, "Event stream disconnected")
  }

  // MethodChannel.MethodCallHandler

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "initialize" -> handleInitialize(result)
      "dispose" -> handleDispose(result)
      "setProperty" -> handleSetProperty(call, result)
      "getProperty" -> handleGetProperty(call, result)
      "getStats" -> handleGetStats(result)
      "observeProperty" -> handleObserveProperty(call, result)
      "command" -> handleCommand(call, result)
      "setVisible" -> handleSetVisible(call, result)
      "updateFrame" -> handleUpdateFrame(result)
      "setVideoFrameRate" -> handleSetVideoFrameRate(call, result)
      "clearVideoFrameRate" -> handleClearVideoFrameRate(result)
      "requestAudioFocus" -> handleRequestAudioFocus(result)
      "abandonAudioFocus" -> handleAbandonAudioFocus(result)
      "openContentFd" -> handleOpenContentFd(call, result)
      "closeContentFd" -> handleCloseContentFd(call, result)
      "isInitialized" -> result.success(playerCore?.isInitialized ?: false)
      "setLogLevel" -> result.success(null)
      else -> result.notImplemented()
    }
  }

  private fun handleInitialize(result: MethodChannel.Result) {
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
      Log.d(tag, "Already initialized")
      result.success(true)
      return
    }

    // Coalesce concurrent inits: the second caller waits for the first
    // call's outcome instead of disposing the in-flight core. The Dart
    // side memoizes too, but this is defense in depth for any direct
    // `invoke('initialize')` that bypasses _ensureInitialized.
    synchronized(pendingInitResults) {
      pendingInitResults += result
      if (isInitializing) {
        Log.d(tag, "Init already in flight, queuing caller")
        return
      }
      isInitializing = true
    }

    runOnMain {
      val gen: Int
      val core: MpvPlayerCore
      try {
        // Caller invariant: dispose() was already called explicitly,
        // OR `playerCore?.isInitialized == true` and we early-exited
        // above. We never tear down a core that's mid-initialization.
        if (playerCore != null && playerCore?.isInitialized != true) {
          Log.w(tag, "Discarding stale uninitialized core before re-init")
          playerCore?.dispose()
          playerCore = null
        }

        gen = ++sessionGeneration
        core = MpvPlayerCore(coreContext, audioOnly).apply {
          delegate = this@MpvPlayerPlugin
        }
        playerCore = core
      } catch (e: Exception) {
        Log.e(tag, "Failed to initialize: ${e.message}", e)
        completePendingInits(success = false, errorMessage = e.message)
        return@runOnMain
      }

      core.initialize { success ->
        val stale = gen != sessionGeneration || playerCore !== core
        if (stale) {
          Log.d(tag, "Stale init callback (gen=$gen, current=$sessionGeneration)")
        } else {
          // Start hidden - now safe because setVisible operates on the container,
          // not the SurfaceView directly (matching ExoPlayer's approach).
          // No-op on the audio-only core, which has no render layer.
          core.setVisible(false)
          Log.d(tag, "Initialized: $success")
        }
        completePendingInits(success = !stale && success)
      }
    }
  }

  private fun completePendingInits(success: Boolean, errorMessage: String? = null) {
    val pending = synchronized(pendingInitResults) {
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

  private fun handleDispose(result: MethodChannel.Result) {
    runOnMain {
      val core = playerCore
      ++sessionGeneration
      playerCore = null

      // Any in-flight init callback is cancelled with the scope, so
      // close out queued callers here instead of leaking them.
      completePendingInits(success = false)

      core?.dispose {
        Log.d(tag, "Disposed")
        result.success(null)
      } ?: result.success(null)
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
    if (core == null) {
      result.success(null)
      return
    }

    core.setProperty(name, value) {
      result.success(null)
    }
  }

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
    Thread {
      val stats = core.getStats()
      runOnMain {
        if (gen != sessionGeneration || playerCore !== core) {
          result.success(mapOf("playerType" to "mpv"))
        } else {
          result.success(stats)
        }
      }
    }.start()
  }

  private fun handleObserveProperty(call: MethodCall, result: MethodChannel.Result) {
    val name = call.argument<String>("name")
    val format = call.argument<String>("format")
    val id = call.argument<Int>("id")

    if (name == null || format == null || id == null) {
      result.error("INVALID_ARGS", "Missing 'name', 'format', or 'id'", null)
      return
    }

    nameToId[name] = id
    playerCore?.observeProperty(name, format)
    result.success(null)
  }

  private fun handleCommand(call: MethodCall, result: MethodChannel.Result) {
    val args = call.argument<List<String>>("args")

    if (args == null) {
      result.error("INVALID_ARGS", "Missing 'args'", null)
      return
    }

    val core = playerCore
    if (core == null) {
      result.success(null)
      return
    }
    core.command(args.toTypedArray()) {
      result.success(null)
    }
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

    Log.d(tag, "setVideoFrameRate: fps=$fps, duration=$duration, extraDelayMs=$extraDelayMs, video=${videoWidth}x$videoHeight")
    val core = playerCore
    if (core == null) {
      result.success(false)
      return
    }
    core.setVideoFrameRate(fps, duration, extraDelayMs, videoWidth, videoHeight) { switched ->
      result.success(switched)
    }
  }

  private fun handleClearVideoFrameRate(result: MethodChannel.Result) {
    Log.d(tag, "clearVideoFrameRate")
    playerCore?.clearVideoFrameRate()
    result.success(null)
  }

  private fun handleRequestAudioFocus(result: MethodChannel.Result) {
    Log.d(tag, "requestAudioFocus")
    val granted = playerCore?.requestAudioFocus() ?: false
    result.success(granted)
  }

  private fun handleAbandonAudioFocus(result: MethodChannel.Result) {
    Log.d(tag, "abandonAudioFocus")
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
        Log.d(tag, "Opened content FD $fd for $uriString")
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
      Log.d(tag, "Closed content FD $fd")
      result.success(null)
    } catch (e: Exception) {
      Log.e(tag, "Failed to close content FD $fd: ${e.message}", e)
      result.error("CLOSE_FAILED", e.message, null)
    }
  }

  // PlayerDelegate

  override fun onPropertyChange(name: String, value: Any?) {
    val propId = nameToId[name] ?: return
    eventSink?.success(listOf(propId, value))
  }

  override fun onEvent(name: String, data: Map<String, Any>?) {
    val event = mutableMapOf<String, Any>(
      "type" to "event",
      "name" to name
    )
    data?.let { event["data"] = it }
    eventSink?.success(event)
  }
}

/**
 * The audio-only music instance on `com.plezy/mpv_audio_player[/events]`.
 * A distinct class (not just a configured [MpvPlayerPlugin]) because
 * FlutterEngine's plugin registry keys plugins by class and would silently
 * drop a second [MpvPlayerPlugin] registration.
 */
class MpvAudioPlayerPlugin : MpvPlayerPlugin(channelBase = "com.plezy/mpv_audio_player", audioOnly = true)
