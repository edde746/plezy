package com.edde746.plezy.mpv

import android.app.Activity
import android.net.Uri
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MpvPlayerPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler, ActivityAware, com.edde746.plezy.shared.PlayerDelegate {

    companion object {
        private const val TAG = "MpvPlayerPlugin"
        private const val METHOD_CHANNEL = "com.plezy/mpv_player"
        private const val EVENT_CHANNEL = "com.plezy/mpv_player/events"
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var playerCore: MpvPlayerCore? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private val nameToId = mutableMapOf<String, Int>()
    private var sessionGeneration = 0

    // Pending `MethodChannel.Result`s for an init that is currently in flight.
    // Concurrent `invoke('initialize')` calls share the same outcome instead
    // of each tearing down the in-flight core and starting their own — which
    // was the root cause of #930.
    private val pendingInitResults = mutableListOf<MethodChannel.Result>()
    @Volatile private var isInitializing = false

    // FlutterPlugin

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)

        Log.d(TAG, "Attached to engine")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        Log.d(TAG, "Detached from engine")
    }

    // ActivityAware

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        Log.d(TAG, "Attached to activity")
    }

    override fun onDetachedFromActivity() {
        ++sessionGeneration
        playerCore?.dispose()
        playerCore = null
        // Any in-flight init callback would never fire (its scope is cancelled
        // by dispose), so close out queued callers explicitly.
        completePendingInits(success = false)
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
        activity = null
        activityBinding = null
        Log.d(TAG, "Detached from activity for config changes")
    }

    // EventChannel.StreamHandler

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        Log.d(TAG, "Event stream connected")
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        Log.d(TAG, "Event stream disconnected")
    }

    // MethodChannel.MethodCallHandler

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> handleInitialize(result)
            "dispose" -> handleDispose(result)
            "setProperty" -> handleSetProperty(call, result)
            "getProperty" -> handleGetProperty(call, result)
            "observeProperty" -> handleObserveProperty(call, result)
            "command" -> handleCommand(call, result)
            "setVisible" -> handleSetVisible(call, result)
            "updateFrame" -> handleUpdateFrame(result)
            "setVideoFrameRate" -> handleSetVideoFrameRate(call, result)
            "clearVideoFrameRate" -> handleClearVideoFrameRate(result)
            "requestAudioFocus" -> handleRequestAudioFocus(result)
            "abandonAudioFocus" -> handleAbandonAudioFocus(result)
            "openContentFd" -> handleOpenContentFd(call, result)
            "isInitialized" -> result.success(playerCore?.isInitialized ?: false)
            "setLogLevel" -> result.success(null)
            else -> result.notImplemented()
        }
    }

    private fun handleInitialize(result: MethodChannel.Result) {
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

        // Coalesce concurrent inits: the second caller waits for the first
        // call's outcome instead of disposing the in-flight core. The Dart
        // side memoizes too, but this is defense in depth for any direct
        // `invoke('initialize')` that bypasses _ensureInitialized.
        synchronized(pendingInitResults) {
            pendingInitResults += result
            if (isInitializing) {
                Log.d(TAG, "Init already in flight, queuing caller")
                return
            }
            isInitializing = true
        }

        currentActivity.runOnUiThread {
            val gen: Int
            val core: MpvPlayerCore
            try {
                // Caller invariant: dispose() was already called explicitly,
                // OR `playerCore?.isInitialized == true` and we early-exited
                // above. We never tear down a core that's mid-initialization.
                if (playerCore != null && playerCore?.isInitialized != true) {
                    Log.w(TAG, "Discarding stale uninitialized core before re-init")
                    playerCore?.dispose()
                    playerCore = null
                }

                gen = ++sessionGeneration
                core = MpvPlayerCore(currentActivity).apply {
                    delegate = this@MpvPlayerPlugin
                }
                playerCore = core
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize: ${e.message}", e)
                completePendingInits(success = false, errorMessage = e.message)
                return@runOnUiThread
            }

            core.initialize { success ->
                val stale = gen != sessionGeneration || playerCore !== core
                if (stale) {
                    Log.d(TAG, "Stale init callback (gen=$gen, current=$sessionGeneration)")
                } else {
                    // Start hidden - now safe because setVisible operates on the container,
                    // not the SurfaceView directly (matching ExoPlayer's approach)
                    core.setVisible(false)
                    Log.d(TAG, "Initialized: $success")
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
        activity?.runOnUiThread {
            val core = playerCore
            ++sessionGeneration
            playerCore = null

            // Any in-flight init callback is cancelled with the scope, so
            // close out queued callers here instead of leaking them.
            completePendingInits(success = false)

            core?.dispose {
                Log.d(TAG, "Disposed")
                result.success(null)
            } ?: result.success(null)
        } ?: result.success(null)
    }

    private fun handleSetProperty(call: MethodCall, result: MethodChannel.Result) {
        val name = call.argument<String>("name")
        val value = call.argument<String>("value")

        if (name == null || value == null) {
            result.error("INVALID_ARGS", "Missing 'name' or 'value'", null)
            return
        }

        playerCore?.setProperty(name, value)
        result.success(null)
    }

    private fun handleGetProperty(call: MethodCall, result: MethodChannel.Result) {
        val name = call.argument<String>("name")

        if (name == null) {
            result.error("INVALID_ARGS", "Missing 'name'", null)
            return
        }

        val value = playerCore?.getProperty(name)
        result.success(value)
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

        playerCore?.command(args.toTypedArray())
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

        Log.d(TAG, "setVideoFrameRate: fps=$fps, duration=$duration, extraDelayMs=$extraDelayMs")
        val core = playerCore
        if (core == null) {
            result.success(false)
            return
        }
        core.setVideoFrameRate(fps, duration, extraDelayMs) { switched ->
            result.success(switched)
        }
    }

    private fun handleClearVideoFrameRate(result: MethodChannel.Result) {
        Log.d(TAG, "clearVideoFrameRate")
        playerCore?.clearVideoFrameRate()
        result.success(null)
    }

    private fun handleRequestAudioFocus(result: MethodChannel.Result) {
        Log.d(TAG, "requestAudioFocus")
        val granted = playerCore?.requestAudioFocus() ?: false
        result.success(granted)
    }

    private fun handleAbandonAudioFocus(result: MethodChannel.Result) {
        Log.d(TAG, "abandonAudioFocus")
        playerCore?.abandonAudioFocus()
        result.success(null)
    }

    private fun handleOpenContentFd(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri")
        if (uriString == null) {
            result.error("INVALID_ARGS", "Missing 'uri'", null)
            return
        }

        val contentResolver = activity?.contentResolver
        if (contentResolver == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        // Open file descriptor off UI thread to prevent ANR on slow storage
        Thread {
            try {
                val uri = Uri.parse(uriString)
                val pfd = contentResolver.openFileDescriptor(uri, "r")
                if (pfd == null) {
                    activity?.runOnUiThread {
                        result.error("OPEN_FAILED", "Failed to open file descriptor for $uriString", null)
                    }
                    return@Thread
                }

                val fd = pfd.detachFd()
                Log.d(TAG, "Opened content FD $fd for $uriString")
                activity?.runOnUiThread { result.success(fd) }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to open content FD: ${e.message}", e)
                activity?.runOnUiThread { result.error("OPEN_FAILED", e.message, null) }
            }
        }.start()
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
