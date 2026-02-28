package com.edde746.plezy.mpv

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
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
import android.view.TextureView
import android.view.WindowManager
import androidx.annotation.RequiresApi
import dev.jdtech.mpv.MPVLib
import io.flutter.plugin.common.MethodChannel
import java.math.BigDecimal
import java.math.RoundingMode
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
        private const val SHORT_VIDEO_LENGTH_MS = 300000L // 5 minutes

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
    private var currentVideoFps: Float = 0f
    private var displayListener: DisplayManager.DisplayListener? = null
    private val handler = Handler(Looper.getMainLooper())

    // Audio focus
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var hasAudioFocus: Boolean = false
    private var wasPlayingBeforeFocusLoss: Boolean = false

    private val audioFocusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AudioManager.AUDIOFOCUS_GAIN -> {
                Log.d(TAG, "Audio focus gained")
                hasAudioFocus = true
                // Resume playback if we were playing before focus loss
                if (wasPlayingBeforeFocusLoss && isInitialized) {
                    try {
                        MPVLib.setPropertyBoolean("pause", false)
                        wasPlayingBeforeFocusLoss = false
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to resume playback after focus gain", e)
                    }
                }
            }
            AudioManager.AUDIOFOCUS_LOSS -> {
                Log.d(TAG, "Audio focus lost permanently")
                hasAudioFocus = false
                // Pause playback on permanent focus loss
                if (isInitialized) {
                    try {
                        val isPaused = MPVLib.getPropertyBoolean("pause")
                        wasPlayingBeforeFocusLoss = !isPaused
                        if (!isPaused) {
                            MPVLib.setPropertyBoolean("pause", true)
                        }
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to pause on focus loss", e)
                    }
                }
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                Log.d(TAG, "Audio focus lost transiently")
                hasAudioFocus = false
                // Pause playback, remember to resume
                if (isInitialized) {
                    try {
                        val isPaused = MPVLib.getPropertyBoolean("pause")
                        wasPlayingBeforeFocusLoss = !isPaused
                        if (!isPaused) {
                            MPVLib.setPropertyBoolean("pause", true)
                        }
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to pause on transient focus loss", e)
                    }
                }
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                Log.d(TAG, "Audio focus lost transiently (can duck), continuing playback")
                // Don't pause — let the system handle volume ducking for notifications
            }
        }
    }

    private var flutterOverlayApplied = false

    private fun ensureFlutterOverlayOnTop() {
        if (flutterOverlayApplied) return
        val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
        contentView.post {
            if (!isInitialized) return@post
            var flutterContainer: ViewGroup? = null

            // First pass: look for FlutterView by name (debug builds)
            for (i in 0 until contentView.childCount) {
                val child = contentView.getChildAt(i)
                if (child is ViewGroup && child.javaClass.name.contains("FlutterView")) {
                    flutterContainer = child
                    break
                }
            }

            // Fallback for release (FlutterView may be obfuscated): pick the last ViewGroup
            // that is not our mpv container and has children.
            if (flutterContainer == null) {
                for (i in contentView.childCount - 1 downTo 0) {
                    val child = contentView.getChildAt(i)
                    if (child is ViewGroup && child != surfaceContainer && child.childCount > 0) {
                        flutterContainer = child
                        break
                    }
                }
            }

            flutterContainer?.let { container ->
                // Skip if Flutter container is already the topmost child
                if (contentView.getChildAt(contentView.childCount - 1) == container) {
                    flutterOverlayApplied = true
                    return@post
                }
                contentView.bringChildToFront(container)
                for (j in 0 until container.childCount) {
                    val flutterChild = container.getChildAt(j)
                    if (flutterChild is SurfaceView) {
                        flutterChild.setZOrderOnTop(true)
                        flutterChild.setZOrderMediaOverlay(true)
                        flutterChild.holder.setFormat(PixelFormat.TRANSLUCENT)
                        break
                    } else if (flutterChild is TextureView) {
                        // TextureView uses alpha composition; ensure it stays above.
                        flutterChild.isOpaque = false
                        break
                    }
                }
                flutterOverlayApplied = true
            }
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

            // Initialize AudioManager for audio focus handling
            audioManager = activity.getSystemService(Context.AUDIO_SERVICE) as AudioManager

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
                // Keep video composited in the normal view hierarchy (avoid hardware overlay promotion)
                // so Flutter controls reliably draw above it in release builds.
                alpha = 0.999f
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

            // Find FlutterView and its internal FlutterSurfaceView, set it on top
            for (i in 0 until contentView.childCount) {
                val child = contentView.getChildAt(i)
                if (child is ViewGroup && child.javaClass.name.contains("FlutterView")) {
                    contentView.bringChildToFront(child)
                    // Look inside FlutterView for FlutterSurfaceView
                    for (j in 0 until child.childCount) {
                        val flutterChild = child.getChildAt(j)
                        if (flutterChild is SurfaceView) {
                            // Put Flutter in media overlay layer (above our video which is in normal layer)
                            flutterChild.setZOrderOnTop(true)
                            flutterChild.setZOrderMediaOverlay(true)
                            flutterChild.holder.setFormat(PixelFormat.TRANSLUCENT)
                            break
                        }
                    }
                    break
                }
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

    /**
     * Request audio focus before starting playback.
     * This will cause other media apps to pause.
     * @return true if audio focus was granted
     */
    fun requestAudioFocus(): Boolean {
        val am = audioManager ?: return false

        Log.d(TAG, "Requesting audio focus")

        val result = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Android 8.0+ uses AudioFocusRequest
            val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MOVIE)
                        .build()
                )
                .setOnAudioFocusChangeListener(audioFocusChangeListener, handler)
                .build()

            audioFocusRequest = focusRequest
            am.requestAudioFocus(focusRequest)
        } else {
            // Legacy API for older Android versions
            @Suppress("DEPRECATION")
            am.requestAudioFocus(
                audioFocusChangeListener,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN
            )
        }

        hasAudioFocus = (result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
        Log.d(TAG, "Audio focus request result: $result, granted: $hasAudioFocus")
        return hasAudioFocus
    }

    /**
     * Abandon audio focus when playback stops.
     * This allows other apps to resume their audio.
     */
    fun abandonAudioFocus() {
        val am = audioManager ?: return

        Log.d(TAG, "Abandoning audio focus")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { am.abandonAudioFocusRequest(it) }
            audioFocusRequest = null
        } else {
            @Suppress("DEPRECATION")
            am.abandonAudioFocus(audioFocusChangeListener)
        }

        hasAudioFocus = false
        wasPlayingBeforeFocusLoss = false
    }

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

    private fun getDisplayManager(): DisplayManager {
        return activity.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
    }

    /**
     * Set the video frame rate for display refresh rate matching.
     * Based on VLC Android's FrameRateManager implementation.
     */
    fun setVideoFrameRate(fps: Float, videoDurationMs: Long) {
        currentVideoFps = fps
        if (fps <= 0f) {
            Log.d(TAG, "setVideoFrameRate: Invalid fps ($fps), skipping")
            return
        }

        val surface = surfaceView?.holder?.surface
        if (surface == null) {
            Log.d(TAG, "setVideoFrameRate: Surface not available")
            return
        }

        Log.d(TAG, "setVideoFrameRate: fps=$fps, duration=${videoDurationMs}ms, API=${Build.VERSION.SDK_INT}")

        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> setFrameRateS(fps, surface, videoDurationMs)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> setFrameRateR(fps, surface)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> setFrameRateM(fps)
        }
    }

    /**
     * Clear frame rate setting and cleanup display listener.
     */
    fun clearVideoFrameRate() {
        Log.d(TAG, "clearVideoFrameRate")
        currentVideoFps = 0f
        displayListener?.let {
            getDisplayManager().unregisterDisplayListener(it)
            displayListener = null
        }
    }

    /**
     * Create and register display listener for mode switch completion.
     * Resumes playback after display mode change (needed for HDMI/projectors).
     */
    private fun registerDisplayListener() {
        displayListener?.let {
            getDisplayManager().unregisterDisplayListener(it)
        }

        displayListener = object : DisplayManager.DisplayListener {
            override fun onDisplayAdded(displayId: Int) = Unit
            override fun onDisplayRemoved(displayId: Int) = Unit
            override fun onDisplayChanged(displayId: Int) {
                // Mode switch may pause playback (HDMI), wait and resume
                handler.postDelayed({
                    try {
                        val isPaused = MPVLib.getPropertyBoolean("pause")
                        if (isPaused) {
                            Log.d(TAG, "Display changed, resuming playback")
                            MPVLib.setPropertyBoolean("pause", false)
                        }
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to resume playback after display change", e)
                    }
                }, 2000L) // Wait 2 seconds for mode switch to complete
                getDisplayManager().unregisterDisplayListener(this)
                displayListener = null
            }
        }
        getDisplayManager().registerDisplayListener(displayListener, handler)
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun setFrameRateR(fps: Float, surface: Surface) {
        Log.d(TAG, "setFrameRateR: Setting frame rate to $fps")
        surface.setFrameRate(fps, Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE)
        registerDisplayListener()
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private fun setFrameRateS(fps: Float, surface: Surface, videoDurationMs: Long) {
        Log.d(TAG, "setFrameRateS: fps=$fps, duration=${videoDurationMs}ms")

        // For short videos (<5min), only switch if seamless
        if (videoDurationMs < SHORT_VIDEO_LENGTH_MS) {
            Log.d(TAG, "Short video, using seamless-only switching")
            surface.setFrameRate(
                fps,
                Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
                Surface.CHANGE_FRAME_RATE_ONLY_IF_SEAMLESS
            )
            return
        }

        // For longer videos, check if switch will be seamless
        var seamless = false
        activity.display?.mode?.alternativeRefreshRates?.let { refreshRates ->
            for (rate in refreshRates) {
                // Check if rates match or are integer multiples
                if (fps.toString().startsWith(rate.toString()) ||
                    rate.toString().startsWith(fps.toString()) ||
                    rate % fps == 0f) {
                    seamless = true
                    break
                }
            }
        }

        if (seamless) {
            Log.d(TAG, "Seamless switch available, using CHANGE_FRAME_RATE_ALWAYS")
            surface.setFrameRate(
                fps,
                Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
                Surface.CHANGE_FRAME_RATE_ALWAYS
            )
            registerDisplayListener()
        } else {
            // Non-seamless: only switch if user enabled it at OS level
            val userPreference = getDisplayManager().matchContentFrameRateUserPreference
            if (userPreference == DisplayManager.MATCH_CONTENT_FRAMERATE_ALWAYS) {
                Log.d(TAG, "User preference allows non-seamless switch")
                surface.setFrameRate(
                    fps,
                    Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
                    Surface.CHANGE_FRAME_RATE_ALWAYS
                )
                registerDisplayListener()
            } else {
                Log.d(TAG, "Non-seamless switch not allowed by user preference, using seamless-only")
                surface.setFrameRate(
                    fps,
                    Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
                    Surface.CHANGE_FRAME_RATE_ONLY_IF_SEAMLESS
                )
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun setFrameRateM(fps: Float) {
        Log.d(TAG, "setFrameRateM: fps=$fps")
        val wm = activity.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val display = wm.defaultDisplay ?: return

        display.supportedModes?.let { supportedModes ->
            val currentMode = display.mode
            var modeToUse = currentMode

            for (mode in supportedModes) {
                // Skip modes with different resolution
                if (mode.physicalHeight != currentMode.physicalHeight ||
                    mode.physicalWidth != currentMode.physicalWidth) {
                    continue
                }

                Log.d(TAG, "Supported mode: ${mode.modeId} - ${mode.refreshRate}Hz")

                // Check for exact match
                if (BigDecimal(fps.toString()).setScale(1, RoundingMode.FLOOR) ==
                    BigDecimal(mode.refreshRate.toString()).setScale(1, RoundingMode.FLOOR)) {
                    modeToUse = mode
                    Log.d(TAG, "Found exact match: ${mode.refreshRate}Hz")
                    break
                }
                // Check for integer multiple (e.g., 48Hz for 24fps)
                else if (mode.refreshRate % fps == 0f) {
                    modeToUse = mode
                    Log.d(TAG, "Found integer multiple: ${mode.refreshRate}Hz")
                    break
                }
            }

            if (modeToUse != currentMode) {
                Log.d(TAG, "Switching to mode ${modeToUse.modeId} (${modeToUse.refreshRate}Hz)")
                activity.window?.attributes?.let { attrs ->
                    attrs.preferredDisplayModeId = modeToUse.modeId
                    activity.window?.attributes = attrs
                }
                registerDisplayListener()
            } else {
                Log.d(TAG, "No better mode found, staying at ${currentMode.refreshRate}Hz")
            }
        }
    }

    // Cleanup

    fun dispose() {
        if (disposing) return
        disposing = true
        Log.d(TAG, "Disposing")

        // Shutdown command executor
        commandExecutor.shutdown()

        // Clean up frame rate listener
        clearVideoFrameRate()

        // Release audio focus
        abandonAudioFocus()
        audioManager = null

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
