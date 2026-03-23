package com.edde746.plezy.mpv

import android.app.Activity
import android.graphics.Color
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
import com.edde746.plezy.shared.PlayerDelegate
import dev.jdtech.mpv.*
import kotlinx.coroutines.*

class MpvPlayerCore(private val activity: Activity) : SurfaceHolder.Callback {

    companion object {
        private const val TAG = "MpvPlayerCore"
    }

    private var surfaceView: SurfaceView? = null
    private var surfaceContainer: android.widget.FrameLayout? = null
    private var overlayLayoutListener: ViewTreeObserver.OnGlobalLayoutListener? = null
    @Volatile private var disposing: Boolean = false
    private var pendingSurface: Surface? = null
    private var lastSurfaceSize: String? = null
    var delegate: PlayerDelegate? = null
    var isInitialized: Boolean = false
        private set

    private var player: MpvPlayer? = null
    private var scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    // Frame rate matching
    private var frameRateManager: FrameRateManager? = null
    private val handler = Handler(Looper.getMainLooper())

    // Audio focus
    private var audioFocusManager: AudioFocusManager? = null
    @Volatile private var cachedPaused: Boolean = true

    private var flutterOverlayApplied = false

    private fun ensureFlutterOverlayOnTop() {
        if (disposing || flutterOverlayApplied) return
        val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
        contentView.post {
            if (disposing || !isInitialized) return@post
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
            cachedPaused = true
            pendingSurface = null

            // Initialize audio focus handling
            audioFocusManager = AudioFocusManager(
                context = activity,
                handler = handler,
                onPause = {
                    scope.launch {
                        try { player?.setProperty("pause", true) }
                        catch (e: Exception) { Log.w(TAG, "Failed to pause on focus loss", e) }
                    }
                },
                onResume = {
                    scope.launch {
                        try { player?.setProperty("pause", false) }
                        catch (e: Exception) { Log.w(TAG, "Failed to resume after focus gain", e) }
                    }
                },
                isPaused = { cachedPaused }
            )
            frameRateManager = FrameRateManager(
                activity = activity,
                handler = handler,
                onDisplayChanged = {
                    scope.launch {
                        try {
                            if (player?.getFlag("pause") == true) {
                                Log.d(TAG, "Display changed, resuming playback")
                                player?.setProperty("pause", false)
                            }
                        } catch (e: Exception) {
                            Log.w(TAG, "Failed to resume after display change", e)
                        }
                    }
                }
            )

            // Create FrameLayout container for video
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
            ensureFlutterOverlayOnTop()
            overlayLayoutListener = ViewTreeObserver.OnGlobalLayoutListener {
                ensureFlutterOverlayOnTop()
                val sv = surfaceView
                if (sv != null) applySurfaceSize(sv.width, sv.height)
            }
            contentView.viewTreeObserver.addOnGlobalLayoutListener(overlayLayoutListener)

            Log.d(TAG, "SurfaceView added to content view")

            // Create MpvPlayer on background thread via coroutine
            scope.launch {
                try {
                    if (disposing) {
                        onResult(false)
                        return@launch
                    }
                    val p = MpvPlayer.create(activity.applicationContext) {
                        setOption("vo", "gpu")
                        setOption("gpu-context", "android")
                        setOption("opengl-es", "yes")
                        setOption("vd-lavc-film-grain", "cpu")
                        setOption("ao", "audiotrack,opensles")
                    }

                    if (disposing) {
                        p.close()
                        onResult(false)
                        return@launch
                    }

                    player = p
                    isInitialized = true

                    // Attach pending surface
                    pendingSurface?.takeIf { it.isValid }?.let { attachSurfaceInternal(it) }
                    pendingSurface = null

                    // Start collecting events/properties/logs
                    collectEvents(p)
                    collectPropertyChanges(p)
                    collectLogMessages(p)

                    Log.d(TAG, "Initialized successfully")
                    onResult(true)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to initialize native: ${e.message}", e)
                    onResult(false)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize: ${e.message}", e)
            onResult(false)
        }
    }

    // Flow collectors

    private fun collectEvents(p: MpvPlayer) {
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            p.eventFlow.collect { event ->
                when (event) {
                    is MpvEvent.EndFile -> {
                        val data = event.reason?.let { mapOf("reason" to it.id) }
                        delegate?.onEvent("end-file", data)
                    }
                    is MpvEvent.FileLoaded -> delegate?.onEvent("file-loaded", null)
                    is MpvEvent.PlaybackRestart -> delegate?.onEvent("playback-restart", null)
                    else -> {}
                }
            }
        }
    }

    private fun collectPropertyChanges(p: MpvPlayer) {
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            p.propertyFlow.collect { change ->
                // Skip None — matches old MPVLib behavior where eventProperty(name)
                // with no value was a no-op. Forwarding null would incorrectly clear
                // track selections (aid/sid) before the file loads.
                if (change is PropertyChange.None) return@collect
                val value: Any? = when (change) {
                    is PropertyChange.Flag -> change.value
                    is PropertyChange.Int64 -> change.value
                    is PropertyChange.Double -> change.value
                    is PropertyChange.Str -> change.value
                    is PropertyChange.None -> null
                }
                if (change.name == "pause" && change is PropertyChange.Flag) {
                    cachedPaused = change.value
                }
                delegate?.onPropertyChange(change.name, value)
            }
        }
    }

    private fun collectLogMessages(p: MpvPlayer) {
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            p.logFlow.collect { msg ->
                delegate?.onEvent("log-message", mapOf(
                    "prefix" to msg.prefix,
                    "level" to msg.level.name.lowercase(),
                    "text" to msg.text
                ))
            }
        }
    }

    // Audio Focus

    fun requestAudioFocus(): Boolean = audioFocusManager?.requestAudioFocus() ?: false

    fun abandonAudioFocus() { audioFocusManager?.abandonAudioFocus() }

    // SurfaceHolder.Callback

    override fun surfaceCreated(holder: SurfaceHolder) {
        Log.d(TAG, "Surface created")
        if (disposing) return

        val surface = holder.surface
        if (player == null) {
            pendingSurface = surface
            Log.d(TAG, "Deferring surface attach until MPV init completes")
            return
        }

        attachSurfaceInternal(surface)
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
        if (player == null || disposing) return
        detachSurfaceInternal()
    }

    private fun attachSurfaceInternal(surface: Surface) {
        val p = player ?: return
        if (disposing || !surface.isValid) return
        try {
            p.attachSurface(surface)
            scope.launch {
                p.setProperty("force-window", "yes")
                p.setProperty("vo", "gpu")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to attach MPV surface", e)
        }
    }

    private fun applySurfaceSize(width: Int, height: Int) {
        val p = player ?: return
        if (disposing || width <= 0 || height <= 0) return
        val size = "${width}x${height}"
        if (size == lastSurfaceSize) return
        lastSurfaceSize = size
        scope.launch {
            try { p.setProperty("android-surface-size", size) }
            catch (e: Exception) { Log.w(TAG, "Failed to apply surface size to MPV", e) }
        }
    }

    private fun detachSurfaceInternal() {
        lastSurfaceSize = null
        val p = player ?: return
        try {
            scope.launch {
                p.setProperty("vo", "null")
                p.setProperty("force-window", "no")
            }
            p.detachSurface()
        } catch (e: Exception) {
            Log.w(TAG, "Failed to detach MPV surface", e)
        }
    }

    // Public API

    fun setProperty(name: String, value: String) {
        if (!isInitialized || disposing) return
        scope.launch {
            try { player?.setProperty(name, value) }
            catch (e: Exception) { Log.w(TAG, "setProperty($name) failed", e) }
        }
    }

    fun getProperty(name: String): String? {
        if (!isInitialized || disposing) return null
        return try {
            runBlocking(Dispatchers.IO) { player?.getString(name) }
        } catch (e: Exception) {
            null
        }
    }

    fun observeProperty(name: String, format: String) {
        val p = player ?: return
        if (!isInitialized) return
        val fmt = when (format) {
            "double" -> PropertyFormat.Double
            "flag" -> PropertyFormat.Flag
            "string" -> PropertyFormat.String
            else -> PropertyFormat.None
        }
        p.observeProperty(name, fmt)
    }

    fun command(args: Array<String>) {
        if (!isInitialized || disposing || args.isEmpty()) return
        scope.launch {
            try { player?.command(*args) }
            catch (e: Exception) { Log.w(TAG, "command failed", e) }
        }
    }

    fun setVisible(visible: Boolean) {
        if (disposing) return
        activity.runOnUiThread {
            if (disposing) return@runOnUiThread
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

    fun dispose(onComplete: (() -> Unit)? = null) {
        if (disposing) {
            onComplete?.invoke()
            return
        }
        disposing = true
        check(Looper.myLooper() == Looper.getMainLooper())
        Log.d(TAG, "Disposing")

        handler.removeCallbacksAndMessages(null)

        // Clean up frame rate and audio focus
        frameRateManager?.clearVideoFrameRate()
        frameRateManager = null
        audioFocusManager?.release()
        audioFocusManager = null

        // Cancel all coroutines
        scope.cancel()

        // Capture locals for deferred cleanup
        val sv = surfaceView
        val container = surfaceContainer
        val contentView = activity.findViewById<ViewGroup>(android.R.id.content)

        surfaceContainer = null
        surfaceView = null

        // Remove layout listener synchronously
        overlayLayoutListener?.let { listener ->
            contentView.viewTreeObserver.removeOnGlobalLayoutListener(listener)
        }
        overlayLayoutListener = null

        pendingSurface = null
        isInitialized = false

        // Deferred view removal
        Handler(Looper.getMainLooper()).postAtFrontOfQueue {
            sv?.holder?.removeCallback(this)
            if (container?.parent != null) {
                contentView.removeView(container)
            }
        }

        // Close player on background thread
        val p = player
        if (p != null) {
            Thread {
                try {
                    p.close()
                } catch (e: Exception) {
                    Log.w(TAG, "MPV close failed", e)
                }
                player = null
                Log.d(TAG, "Disposed (native)")
                Handler(Looper.getMainLooper()).post { onComplete?.invoke() }
            }.start()
        } else {
            onComplete?.invoke()
        }

        // Reset scope for potential re-initialization
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    }
}
