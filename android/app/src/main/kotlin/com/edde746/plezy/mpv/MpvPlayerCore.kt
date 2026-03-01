package com.edde746.plezy.mpv

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Surface
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import com.edde746.plezy.shared.AudioFocusManager
import com.edde746.plezy.shared.FlutterOverlayHelper
import com.edde746.plezy.shared.FrameRateManager
import dev.jdtech.mpv.MPVLib
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

interface MpvPlayerDelegate {
    fun onPropertyChange(name: String, value: Any?)
    fun onEvent(name: String, data: Map<String, Any>?)
}

class MpvPlayerCore(private val activity: Activity) :
    SurfaceHolder.Callback,
    MPVLib.EventObserver,
    MPVLib.LogObserver {

    companion object {
        private const val TAG = "MpvPlayerCore"

        // Guards MPVLib.create/destroy which share global native state
        private val mpvLock = Object()
    }

    private var surfaceView: SurfaceView? = null
    private var surfaceContainer: android.widget.FrameLayout? = null
    private var overlayLayoutListener: ViewTreeObserver.OnGlobalLayoutListener? =
        null
    @Volatile private var nativeReady: Boolean = false
    @Volatile private var disposing: Boolean = false
    private var pendingSurface: Surface? = null
    private var lastSurfaceSize: String? = null
    var delegate: MpvPlayerDelegate? = null
    var isInitialized: Boolean = false
        private set

    // Executor for running MPV commands off the UI thread to prevent ANR
    private val commandExecutor = Executors.newSingleThreadExecutor()

    // Frame rate matching
    private var frameRateManager: FrameRateManager? = null
    private val handler = Handler(Looper.getMainLooper())

    // Audio focus
    private var audioFocusManager: AudioFocusManager? = null

    private var flutterOverlayApplied = false

    private fun ensureFlutterOverlayOnTop() {
        if (flutterOverlayApplied) return
        val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
        contentView.post {
            if (!isInitialized) return@post
            val container = FlutterOverlayHelper.findFlutterContainer(contentView, surfaceContainer)
                ?: return@post
            if (contentView.getChildAt(contentView.childCount - 1) == container) {
                flutterOverlayApplied = true
                return@post
            }
            FlutterOverlayHelper.configureFlutterZOrder(contentView, container, zOrderOnTop = true)
            flutterOverlayApplied = true
        }
    }

    fun initialize(onResult: (Boolean) -> Unit) {
        if (isInitialized) {
            Log.d(TAG, "Already initialized")
            onResult(true)
            return
        }

        try {
            disposing = false
            pendingSurface = null

            // Initialize audio focus handling
            audioFocusManager = AudioFocusManager(
                context = activity,
                handler = handler,
                onPause = {
                    if (isInitialized) {
                        try { MPVLib.setPropertyBoolean("pause", true) }
                        catch (e: Exception) { Log.w(TAG, "Failed to pause on focus loss", e) }
                    }
                },
                onResume = {
                    if (isInitialized) {
                        try { MPVLib.setPropertyBoolean("pause", false) }
                        catch (e: Exception) { Log.w(TAG, "Failed to resume after focus gain", e) }
                    }
                },
                isPaused = {
                    try { MPVLib.getPropertyBoolean("pause") }
                    catch (e: Exception) { true }
                }
            )
            frameRateManager = FrameRateManager(
                activity = activity,
                handler = handler,
                onDisplayChanged = {
                    try {
                        if (MPVLib.getPropertyBoolean("pause")) {
                            Log.d(TAG, "Display changed, resuming playback")
                            MPVLib.setPropertyBoolean("pause", false)
                        }
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to resume after display change", e)
                    }
                }
            )

            // Create FrameLayout container for video (matches ExoPlayer pattern)
            // Setting visibility on container instead of SurfaceView directly allows
            // the surface to be created even when hidden (required with RenderMode.texture)
            surfaceContainer = android.widget.FrameLayout(activity).apply {
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
                setBackgroundColor(Color.BLACK)
            }

            // Create SurfaceView for video rendering
            surfaceView = SurfaceView(activity).apply {
                layoutParams = android.widget.FrameLayout.LayoutParams(
                    android.widget.FrameLayout.LayoutParams.MATCH_PARENT,
                    android.widget.FrameLayout.LayoutParams.MATCH_PARENT
                )
                holder.addCallback(this@MpvPlayerCore)

                // Critical: Ensure SurfaceView renders BEHIND Flutter's view
                setZOrderOnTop(false)
                setZOrderMediaOverlay(false)
            }

            // Add SurfaceView to container
            surfaceContainer!!.addView(surfaceView)

            // Insert container at bottom of view hierarchy (behind Flutter)
            val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
            contentView.addView(surfaceContainer, 0)

            // Find FlutterView and set it on top of our video surface
            FlutterOverlayHelper.findFlutterContainer(contentView, surfaceContainer)?.let { container ->
                FlutterOverlayHelper.configureFlutterZOrder(contentView, container, zOrderOnTop = true)
                flutterOverlayApplied = true
            }
            // Repeat after layout settles to catch late-added Flutter surfaces (release builds)
            ensureFlutterOverlayOnTop()
            overlayLayoutListener = ViewTreeObserver.OnGlobalLayoutListener {
                ensureFlutterOverlayOnTop()
                // Re-apply surface size on layout change (orientation transitions)
                val sv = surfaceView
                if (sv != null) applySurfaceSize(sv.width, sv.height)
            }
            contentView.viewTreeObserver.addOnGlobalLayoutListener(overlayLayoutListener)

            Log.d(TAG, "SurfaceView added to content view")

            // Native MPVLib init on background thread — waits for any
            // in-flight destroy to finish without blocking the UI thread.
            val ctx = activity.applicationContext
            Thread {
                try {
                    synchronized(mpvLock) {
                        if (disposing) {
                            handler.post { onResult(false) }
                            return@Thread
                        }
                        MPVLib.create(ctx)
                        setupMpvDefaults()
                        MPVLib.init()
                        nativeReady = true
                    }
                    handler.post {
                        if (disposing) {
                            if (nativeReady) {
                                Thread {
                                    synchronized(mpvLock) {
                                        try {
                                            MPVLib.destroy()
                                        } catch (_: Exception) {
                                        } finally {
                                            nativeReady = false
                                        }
                                    }
                                }.start()
                            }
                            onResult(false)
                            return@post
                        }

                        MPVLib.addObserver(this)
                        MPVLib.addLogObserver(this)
                        isInitialized = true

                        // surfaceCreated can fire before MPV init finishes.
                        // Defer attaching the surface until native init is ready.
                        pendingSurface?.takeIf { it.isValid }?.let {
                            attachSurfaceInternal(it)
                        }
                        pendingSurface = null

                        Log.d(TAG, "Initialized successfully")
                        onResult(true)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to initialize native: ${e.message}", e)
                    nativeReady = false
                    handler.post { onResult(false) }
                }
            }.start()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize: ${e.message}", e)
            onResult(false)
        }
    }

    private fun setupMpvDefaults() {
        // Video output configuration
        MPVLib.setOptionString("vo", "gpu")
        MPVLib.setOptionString("gpu-context", "android")
        MPVLib.setOptionString("opengl-es", "yes")
        // hwdec is set from Flutter via setProperty based on user preference

        // Prevent crashes/artifacts from hardware film grain synthesis (mpv #14651)
        MPVLib.setOptionString("vd-lavc-film-grain", "cpu")

        // Audio configuration
        MPVLib.setOptionString("ao", "audiotrack")
    }

    // Audio Focus

    fun requestAudioFocus(): Boolean = audioFocusManager?.requestAudioFocus() ?: false

    fun abandonAudioFocus() { audioFocusManager?.abandonAudioFocus() }

    // SurfaceHolder.Callback

    override fun surfaceCreated(holder: SurfaceHolder) {
        Log.d(TAG, "Surface created")
        if (disposing) return

        val surface = holder.surface
        if (!nativeReady) {
            pendingSurface = surface
            Log.d(TAG, "Deferring surface attach until MPV native init completes")
            return
        }

        attachSurfaceInternal(surface)
        // Reassert overlay order whenever the surface is recreated
        flutterOverlayApplied = false
        ensureFlutterOverlayOnTop()
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        Log.d(TAG, "Surface changed: ${width}x${height}")
        applySurfaceSize(width, height)
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        Log.d(TAG, "Surface destroyed")
        pendingSurface = null
        if (!nativeReady || disposing) return
        detachSurfaceInternal()
    }

    private fun attachSurfaceInternal(surface: Surface) {
        if (!nativeReady || disposing || !surface.isValid) return
        try {
            MPVLib.attachSurface(surface)
            MPVLib.setOptionString("force-window", "yes")
            // Restore video output after surface is available
            MPVLib.setPropertyString("vo", "gpu")
        } catch (e: Exception) {
            Log.w(TAG, "Failed to attach MPV surface", e)
        }
    }

    private fun applySurfaceSize(width: Int, height: Int) {
        if (!nativeReady || disposing || width <= 0 || height <= 0) return
        val size = "${width}x${height}"
        if (size == lastSurfaceSize) return
        lastSurfaceSize = size
        try {
            MPVLib.setPropertyString("android-surface-size", size)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to apply surface size to MPV", e)
        }
    }

    private fun detachSurfaceInternal() {
        lastSurfaceSize = null
        if (!nativeReady) return
        // Disable video output before detaching (like mpv-android)
        try {
            MPVLib.setPropertyString("vo", "null")
            MPVLib.setOptionString("force-window", "no")
            MPVLib.detachSurface()
        } catch (e: Exception) {
            Log.w(TAG, "Failed to detach MPV surface", e)
        }
    }

    // MPVLib.EventObserver

    override fun eventProperty(property: String) {
        // No value provided
    }

    override fun eventProperty(property: String, value: Long) {
        activity.runOnUiThread {
            delegate?.onPropertyChange(property, value)
        }
    }

    override fun eventProperty(property: String, value: Double) {
        activity.runOnUiThread {
            delegate?.onPropertyChange(property, value)
        }
    }

    override fun eventProperty(property: String, value: Boolean) {
        activity.runOnUiThread {
            delegate?.onPropertyChange(property, value)
        }
    }

    override fun eventProperty(property: String, value: String) {
        activity.runOnUiThread {
            delegate?.onPropertyChange(property, value)
        }
    }

    override fun event(eventId: Int) {
        val eventName = when (eventId) {
            MPVLib.MPV_EVENT_FILE_LOADED -> "file-loaded"
            MPVLib.MPV_EVENT_END_FILE -> "end-file"
            MPVLib.MPV_EVENT_PLAYBACK_RESTART -> "playback-restart"
            else -> null
        }
        eventName?.let { name ->
            activity.runOnUiThread {
                delegate?.onEvent(name, null)
            }
        }
    }

    // MPVLib.LogObserver

    override fun logMessage(prefix: String, level: Int, text: String) {
        val levelStr = when (level) {
            MPVLib.MPV_LOG_LEVEL_FATAL -> "fatal"
            MPVLib.MPV_LOG_LEVEL_ERROR -> "error"
            MPVLib.MPV_LOG_LEVEL_WARN -> "warn"
            MPVLib.MPV_LOG_LEVEL_INFO -> "info"
            MPVLib.MPV_LOG_LEVEL_V -> "v"
            MPVLib.MPV_LOG_LEVEL_DEBUG -> "debug"
            MPVLib.MPV_LOG_LEVEL_TRACE -> "trace"
            else -> "info"
        }
        activity.runOnUiThread {
            delegate?.onEvent("log-message", mapOf(
                "prefix" to prefix,
                "level" to levelStr,
                "text" to text
            ))
        }
    }

    // Public API

    fun setProperty(name: String, value: String) {
        if (!isInitialized) return
        MPVLib.setPropertyString(name, value)
    }

    fun getProperty(name: String): String? {
        if (!isInitialized) return null
        return try {
            MPVLib.getPropertyString(name)
        } catch (e: Exception) {
            null
        }
    }

    fun observeProperty(name: String, format: String) {
        if (!isInitialized) return

        val mpvFormat = when (format) {
            "double" -> MPVLib.MPV_FORMAT_DOUBLE
            "flag" -> MPVLib.MPV_FORMAT_FLAG
            "string" -> MPVLib.MPV_FORMAT_STRING
            "node" -> MPVLib.MPV_FORMAT_NODE
            else -> MPVLib.MPV_FORMAT_NONE
        }
        MPVLib.observeProperty(name, mpvFormat)
    }

    fun command(args: Array<String>) {
        if (!isInitialized || args.isEmpty()) return
        MPVLib.command(args)
    }

    /**
     * Execute an MPV command asynchronously off the UI thread.
     * This prevents ANR when commands like loadfile block waiting for network I/O.
     * The result is called back on the UI thread when the command completes.
     */
    fun commandAsync(args: Array<String>, result: MethodChannel.Result) {
        if (!isInitialized || args.isEmpty()) {
            result.success(null)
            return
        }

        commandExecutor.execute {
            try {
                MPVLib.command(args)
                activity.runOnUiThread {
                    result.success(null)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Async command failed: ${e.message}", e)
                activity.runOnUiThread {
                    result.error("COMMAND_FAILED", e.message, null)
                }
            }
        }
    }

    fun setVisible(visible: Boolean) {
        activity.runOnUiThread {
            // Set visibility on the container, not the SurfaceView directly.
            // This allows the SurfaceView surface to be created even when hidden,
            // which is required with RenderMode.texture (TextureView mode).
            surfaceContainer?.visibility = if (visible) View.VISIBLE else View.INVISIBLE
            Log.d(TAG, "setVisible($visible)")
        }
    }

    fun onPipModeChanged(isInPipMode: Boolean) {
        // MPV handles aspect ratio internally via its own surface management
    }

    // Frame Rate Matching

    fun setVideoFrameRate(fps: Float, videoDurationMs: Long) {
        frameRateManager?.setVideoFrameRate(fps, videoDurationMs, surfaceView?.holder?.surface)
    }

    fun clearVideoFrameRate() {
        frameRateManager?.clearVideoFrameRate()
    }

    // Cleanup

    fun dispose() {
        if (disposing) return
        disposing = true
        Log.d(TAG, "Disposing")

        // Shutdown command executor
        commandExecutor.shutdown()

        // Clean up frame rate and audio focus
        frameRateManager?.clearVideoFrameRate()
        frameRateManager = null
        audioFocusManager?.release()
        audioFocusManager = null

        if (nativeReady) {
            try {
                MPVLib.removeObserver(this)
                MPVLib.removeLogObserver(this)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to remove MPV observers during dispose", e)
            }
            detachSurfaceInternal()
        }

        overlayLayoutListener?.let { listener ->
            val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
            contentView.viewTreeObserver.removeOnGlobalLayoutListener(listener)
        }
        overlayLayoutListener = null

        // Defer all view removal to avoid AOSP bug where
        // dispatchWindowVisibilityChanged iterates stale children array
        // when removeView() runs during an active performTraversals pass.
        val sv = surfaceView
        val container = surfaceContainer
        val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
        contentView.post {
            sv?.holder?.removeCallback(this)
            container?.let { contentView.removeView(it) }
        }
        surfaceContainer = null
        surfaceView = null
        pendingSurface = null
        isInitialized = false

        // Run native destroy on background thread to avoid ANR —
        // MPVLib.destroy() blocks on pthread_cond_wait while mpv's
        // internal threads (lua, demux, vo) shut down.
        if (nativeReady) {
            Thread {
                synchronized(mpvLock) {
                    try {
                        MPVLib.destroy()
                    } catch (e: Exception) {
                        Log.w(TAG, "MPV destroy failed", e)
                    } finally {
                        nativeReady = false
                    }
                }
                Log.d(TAG, "Disposed (native)")
            }.start()
        }
    }
}
