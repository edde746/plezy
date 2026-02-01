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
    EventChannel.StreamHandler, ActivityAware, MpvPlayerDelegate {

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
        playerCore?.dispose()
        playerCore = null
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
            "setVideoFrameRate" -> handleSetVideoFrameRate(call, result)
            "clearVideoFrameRate" -> handleClearVideoFrameRate(result)
            "requestAudioFocus" -> handleRequestAudioFocus(result)
            "abandonAudioFocus" -> handleAbandonAudioFocus(result)
            "openContentFd" -> handleOpenContentFd(call, result)
            "isInitialized" -> result.success(playerCore?.isInitialized ?: false)
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

        currentActivity.runOnUiThread {
            try {
                playerCore = MpvPlayerCore(currentActivity).apply {
                    delegate = this@MpvPlayerPlugin
                }
                val success = playerCore?.initialize() ?: false

                // Start hidden - now safe because setVisible operates on the container,
                // not the SurfaceView directly (matching ExoPlayer's approach)
                playerCore?.setVisible(false)

                Log.d(TAG, "Initialized: $success")
                result.success(success)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize: ${e.message}", e)
                result.error("INIT_FAILED", e.message, null)
            }
        }
    }

    private fun handleDispose(result: MethodChannel.Result) {
        activity?.runOnUiThread {
            playerCore?.dispose()
            playerCore = null
            Log.d(TAG, "Disposed")
            result.success(null)
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

        if (name == null || format == null) {
            result.error("INVALID_ARGS", "Missing 'name' or 'format'", null)
            return
        }

        playerCore?.observeProperty(name, format)
        result.success(null)
    }

    private fun handleCommand(call: MethodCall, result: MethodChannel.Result) {
        val args = call.argument<List<String>>("args")

        if (args == null) {
            result.error("INVALID_ARGS", "Missing 'args'", null)
            return
        }

        // Use async command to prevent ANR - command executes off UI thread
        // and result is called back when complete
        playerCore?.commandAsync(args.toTypedArray(), result)
            ?: result.success(null)
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

    private fun handleSetVideoFrameRate(call: MethodCall, result: MethodChannel.Result) {
        val fps = call.argument<Double>("fps")?.toFloat() ?: 0f
        val duration = call.argument<Number>("duration")?.toLong() ?: 0L

        Log.d(TAG, "setVideoFrameRate: fps=$fps, duration=$duration")
        playerCore?.setVideoFrameRate(fps, duration)
        result.success(null)
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

        try {
            val uri = Uri.parse(uriString)
            val contentResolver = activity?.contentResolver
            if (contentResolver == null) {
                result.error("NO_ACTIVITY", "Activity not available", null)
                return
            }

            val pfd = contentResolver.openFileDescriptor(uri, "r")
            if (pfd == null) {
                result.error("OPEN_FAILED", "Failed to open file descriptor for $uriString", null)
                return
            }

            // detachFd() transfers ownership of the FD to the caller (MPV via fdclose://)
            val fd = pfd.detachFd()
            Log.d(TAG, "Opened content FD $fd for $uriString")
            result.success(fd)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open content FD: ${e.message}", e)
            result.error("OPEN_FAILED", e.message, null)
        }
    }

    // MpvPlayerDelegate

    override fun onPropertyChange(name: String, value: Any?) {
        eventSink?.success(
            mapOf(
                "type" to "property",
                "name" to name,
                "value" to value
            )
        )
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
