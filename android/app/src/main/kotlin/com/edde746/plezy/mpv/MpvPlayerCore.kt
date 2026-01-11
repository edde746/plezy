package com.edde746.plezy.mpv

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
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
import java.math.BigDecimal
import java.math.RoundingMode

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
    }

    private var surfaceView: SurfaceView? = null
    private var overlayLayoutListener: ViewTreeObserver.OnGlobalLayoutListener? =
        null
    private var voInUse: String = "gpu"
    var delegate: MpvPlayerDelegate? = null
    var isInitialized: Boolean = false
        private set

    // Frame rate matching
    private var currentVideoFps: Float = 0f
    private var displayListener: DisplayManager.DisplayListener? = null
    private val handler = Handler(Looper.getMainLooper())

    private fun ensureFlutterOverlayOnTop() {
        val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
        contentView.post {
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
            // that is not our mpv SurfaceView and has children.
            if (flutterContainer == null) {
                for (i in contentView.childCount - 1 downTo 0) {
                    val child = contentView.getChildAt(i)
                    if (child is ViewGroup && child != surfaceView?.parent && child.childCount > 0) {
                        flutterContainer = child
                        break
                    }
                }
            }

            flutterContainer?.let { container ->
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
            }
        }
    }

    fun initialize(): Boolean {
        if (isInitialized) {
            Log.d(TAG, "Already initialized")
            return true
        }

        try {
            // Create SurfaceView for video rendering
            surfaceView = SurfaceView(activity).apply {
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
                setBackgroundColor(Color.BLACK)
                // Keep video composited in the normal view hierarchy (avoid hardware overlay promotion)
                // so Flutter controls reliably draw above it in release builds.
                alpha = 0.999f
                holder.addCallback(this@MpvPlayerCore)

                // Critical: Ensure SurfaceView renders BEHIND Flutter's view
                setZOrderOnTop(false)
                setZOrderMediaOverlay(false)
            }

            // Insert SurfaceView at bottom of view hierarchy (behind Flutter)
            val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
            contentView.addView(surfaceView, 0)

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
            }
            contentView.viewTreeObserver.addOnGlobalLayoutListener(overlayLayoutListener)

            Log.d(TAG, "SurfaceView added to content view")

            // Initialize MPVLib
            MPVLib.create(activity.applicationContext)

            // Configure MPV defaults
            setupMpvDefaults()

            // Initialize MPV
            MPVLib.init()

            // Register event and log observers
            MPVLib.addObserver(this)
            MPVLib.addLogObserver(this)

            isInitialized = true
            Log.d(TAG, "Initialized successfully")
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize: ${e.message}", e)
            return false
        }
    }

    private fun setupMpvDefaults() {
        // Video output configuration
        MPVLib.setOptionString("vo", "gpu")
        MPVLib.setOptionString("gpu-context", "android")
        MPVLib.setOptionString("opengl-es", "yes")
        // hwdec is set from Flutter via setProperty based on user preference

        // Audio configuration
        MPVLib.setOptionString("ao", "audiotrack")
    }

    // SurfaceHolder.Callback

    override fun surfaceCreated(holder: SurfaceHolder) {
        Log.d(TAG, "Surface created")
        MPVLib.attachSurface(holder.surface)
        MPVLib.setOptionString("force-window", "yes")
        // Restore video output after surface is available
        MPVLib.setPropertyString("vo", voInUse)
        // Reassert overlay order whenever the surface is recreated
        ensureFlutterOverlayOnTop()
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        Log.d(TAG, "Surface changed: ${width}x${height}")
        MPVLib.setPropertyString("android-surface-size", "${width}x${height}")
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        Log.d(TAG, "Surface destroyed")
        // Disable video output before detaching (like mpv-android)
        MPVLib.setPropertyString("vo", "null")
        MPVLib.setOptionString("force-window", "no")
        MPVLib.detachSurface()
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

    fun setVisible(visible: Boolean) {
        activity.runOnUiThread {
            surfaceView?.visibility = if (visible) View.VISIBLE else View.INVISIBLE
            Log.d(TAG, "setVisible($visible)")
        }
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
        Log.d(TAG, "Disposing")

        // Clean up frame rate listener
        clearVideoFrameRate()

        MPVLib.removeObserver(this)
        MPVLib.removeLogObserver(this)

        surfaceView?.holder?.removeCallback(this)
        overlayLayoutListener?.let { listener ->
            val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
            contentView.viewTreeObserver.removeOnGlobalLayoutListener(listener)
        }

        val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
        surfaceView?.let { contentView.removeView(it) }
        surfaceView = null

        MPVLib.destroy()
        isInitialized = false

        Log.d(TAG, "Disposed")
    }
}
