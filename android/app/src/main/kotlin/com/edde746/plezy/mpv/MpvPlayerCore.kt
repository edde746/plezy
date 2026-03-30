package com.edde746.plezy.mpv

import android.app.Activity
import android.graphics.Color
import android.graphics.PixelFormat
import android.media.ImageReader
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
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

class MpvPlayerCore(private val activity: Activity) : SurfaceHolder.Callback {

    companion object {
        private const val TAG = "MpvPlayerCore"
    }

    private var surfaceView: SurfaceView? = null
    private var surfaceContainer: android.widget.FrameLayout? = null
    private var overlayLayoutListener: ViewTreeObserver.OnGlobalLayoutListener? = null
    @Volatile private var disposing: Boolean = false
    @Volatile private var pendingSurface: Surface? = null
    @Volatile private var attachedSurface: Surface? = null
    private var placeholderImageReader: ImageReader? = null
    @Volatile private var placeholderSurface: Surface? = null
    @Volatile private var lastAppliedSurfaceSize: String? = null
    @Volatile private var lastKnownSurfaceWidth: Int = 0
    @Volatile private var lastKnownSurfaceHeight: Int = 0
    var delegate: PlayerDelegate? = null
    var isInitialized: Boolean = false
        private set

    @Volatile private var player: MpvPlayer? = null
    private var scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    // Frame rate matching
    private var frameRateManager: FrameRateManager? = null
    private val handler = Handler(Looper.getMainLooper())

    // Audio focus
    private var audioFocusManager: AudioFocusManager? = null
    @Volatile private var cachedPaused: Boolean = true
    @Volatile private var pausedForSurfaceLoss: Boolean = false
    @Volatile private var hasAttachedSurface: Boolean = false
    @Volatile private var attachedToPlaceholder: Boolean = false
    @Volatile private var videoOutputRestoring: Boolean = false
    @Volatile private var deferredResumeRequested: Boolean = false
    @Volatile private var resumeBlockedByPublicPause: Boolean = false
    @Volatile private var videoOutputEpoch: Long = 0L
    private val videoOutputMutex = Mutex()
    private var pendingVideoOutputDisableJob: Job? = null
    private var pendingVideoOutputRefreshJob: Job? = null

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

    private fun ensurePlaceholderSurface() {
        if (placeholderSurface?.isValid == true) return
        placeholderImageReader?.close()
        placeholderImageReader = ImageReader.newInstance(1, 1, PixelFormat.RGBA_8888, 2)
        placeholderSurface = placeholderImageReader?.surface
        Log.d(TAG, "Created MPV placeholder surface")
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
            pausedForSurfaceLoss = false
            pendingSurface = null
            attachedSurface = null
            attachedToPlaceholder = false
            hasAttachedSurface = false
            videoOutputRestoring = false
            deferredResumeRequested = false
            resumeBlockedByPublicPause = false
            videoOutputEpoch = 0L
            pendingVideoOutputDisableJob?.cancel()
            pendingVideoOutputDisableJob = null
            lastAppliedSurfaceSize = null
            lastKnownSurfaceWidth = 0
            lastKnownSurfaceHeight = 0
            ensurePlaceholderSurface()

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
                    requestAutoResume("audio focus gain")
                },
                isPaused = { cachedPaused }
            )
            frameRateManager = FrameRateManager(
                activity = activity,
                handler = handler,
                onDisplayChanged = {
                    requestAutoResume("display change")
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

                    refreshVideoOutput("initialize")

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
        pendingSurface = surface.takeIf { it.isValid }
        pendingVideoOutputDisableJob?.cancel()
        videoOutputEpoch += 1L
        rememberCurrentSurfaceSize()
        if (player == null) {
            Log.d(TAG, "Deferring video output refresh until MPV init completes")
            return
        }

        refreshVideoOutput("surfaceCreated")
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        Log.d(TAG, "Surface changed: ${width}x${height}")
        rememberSurfaceSize(width, height)
        refreshVideoOutput("surfaceChanged")
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        Log.d(TAG, "Surface destroyed")
        pendingSurface = null
        if (player == null || disposing) return
        detachSurfaceInternal(reason = "surfaceDestroyed")
    }

    private fun rememberSurfaceSize(width: Int, height: Int) {
        if (width <= 0 || height <= 0) return
        lastKnownSurfaceWidth = width
        lastKnownSurfaceHeight = height
    }

    private fun rememberCurrentSurfaceSize() {
        val sv = surfaceView ?: return
        rememberSurfaceSize(sv.width, sv.height)
    }

    private fun currentCandidateSurface(): Surface? =
        surfaceView?.holder?.surface?.takeIf { it.isValid }
            ?: pendingSurface?.takeIf { it.isValid }

    private fun hasAttachedRealSurface(): Boolean =
        hasAttachedSurface && !attachedToPlaceholder && (attachedSurface?.isValid == true)

    private fun hasReadyVideoOutput(): Boolean =
        hasAttachedRealSurface() && !videoOutputRestoring

    private fun isCurrentVideoOutputEpoch(epoch: Long): Boolean =
        !disposing && epoch == videoOutputEpoch

    private fun isVideoOutputRefreshCurrent(epoch: Long): Boolean {
        if (disposing) return false
        if (epoch != videoOutputEpoch) return false
        return hasAttachedRealSurface()
    }

    private fun refreshVideoOutput(reason: String) {
        if (disposing) return

        rememberCurrentSurfaceSize()
        val p = player
        val surface = currentCandidateSurface()
        if (p == null) {
            pendingSurface = surface?.takeIf { it.isValid }
            Log.d(TAG, "refreshVideoOutput($reason): player not ready yet")
            return
        }

        if (surface == null || !surface.isValid) {
            hasAttachedSurface = false
            attachedSurface = null
            attachedToPlaceholder = false
            pendingSurface = null
            lastAppliedSurfaceSize = null
            videoOutputRestoring = true
            Log.d(TAG, "refreshVideoOutput($reason): no valid surface available")
            return
        }

        val refreshEpoch = videoOutputEpoch
        pendingVideoOutputDisableJob?.cancel()
        videoOutputRestoring = true
        flutterOverlayApplied = false
        ensureFlutterOverlayOnTop()
        Log.d(TAG, "refreshVideoOutput($reason): scheduling async refresh (epoch=$refreshEpoch)")
        pendingVideoOutputRefreshJob = scope.launch(Dispatchers.IO) {
            try {
                videoOutputMutex.withLock {
                    if (!isCurrentVideoOutputEpoch(refreshEpoch)) {
                        Log.d(TAG, "Skipping stale MPV video output refresh ($reason, epoch=$refreshEpoch)")
                        return@withLock
                    }
                    if (!surface.isValid) {
                        hasAttachedSurface = false
                        attachedSurface = null
                        attachedToPlaceholder = false
                        pendingSurface = null
                        lastAppliedSurfaceSize = null
                        videoOutputRestoring = true
                        Log.d(TAG, "Skipping MPV video output refresh with invalid surface ($reason, epoch=$refreshEpoch)")
                        return@withLock
                    }

                    val needsAttach = !hasAttachedSurface || attachedSurface !== surface
                    val wasAttachedToPlaceholder = attachedToPlaceholder
                    val wasPausedForSurfaceLoss = pausedForSurfaceLoss
                    if (needsAttach) {
                        p.attachSurface(surface)
                        attachedSurface = surface
                        hasAttachedSurface = true
                        attachedToPlaceholder = false
                        pendingSurface = null
                        Log.d(TAG, "refreshVideoOutput($reason): attached surface")
                    } else {
                        Log.d(TAG, "refreshVideoOutput($reason): surface already attached, refreshing surface state")
                    }

                    if (!isVideoOutputRefreshCurrent(refreshEpoch)) {
                        Log.d(TAG, "Skipping stale MPV video output refresh after attach ($reason, epoch=$refreshEpoch)")
                        return@withLock
                    }
                    applySurfaceSizeInternal(p, force = true)
                    if (!isVideoOutputRefreshCurrent(refreshEpoch)) {
                        Log.d(TAG, "Skipping stale MPV video output refresh after surface size ($reason, epoch=$refreshEpoch)")
                        return@withLock
                    }
                    videoOutputRestoring = false
                    applyDeferredResumeIfNeeded(p, reason)
                    if (wasPausedForSurfaceLoss) {
                        pausedForSurfaceLoss = false
                        Log.d(TAG, "Cleared surface-loss pause after $reason")
                    }
                    if (wasAttachedToPlaceholder) {
                        Log.d(TAG, "Restored MPV real surface after placeholder ($reason)")
                    }
                    Log.d(TAG, "Video output ready after $reason")
                }
            } catch (e: CancellationException) {
                Log.d(TAG, "Canceled pending MPV video output refresh ($reason, epoch=$refreshEpoch)")
            } catch (e: Exception) {
                Log.w(TAG, "Failed to finalize MPV video output refresh ($reason)", e)
            }
        }
    }

    private fun applySurfaceSize(width: Int, height: Int) {
        val p = player ?: return
        if (disposing || width <= 0 || height <= 0) return
        rememberSurfaceSize(width, height)
        if (!hasReadyVideoOutput()) return
        scope.launch {
            try { applySurfaceSizeInternal(p) }
            catch (e: Exception) { Log.w(TAG, "Failed to apply surface size to MPV", e) }
        }
    }

    private suspend fun applySurfaceSizeInternal(p: MpvPlayer, force: Boolean = false) {
        if (disposing) return
        val width = lastKnownSurfaceWidth
        val height = lastKnownSurfaceHeight
        if (width <= 0 || height <= 0) return

        val size = "${width}x${height}"
        if (!force && size == lastAppliedSurfaceSize) return
        p.setProperty("android-surface-size", size)
        lastAppliedSurfaceSize = size
        Log.d(TAG, "Applied MPV surface size $size${if (force) " (forced)" else ""}")
    }

    private fun schedulePlaceholderSurfaceAttach(
        p: MpvPlayer,
        reason: String,
        epoch: Long
    ) {
        pendingVideoOutputDisableJob?.cancel()
        pendingVideoOutputDisableJob = scope.launch(Dispatchers.IO) {
            try {
                videoOutputMutex.withLock {
                    if (!isCurrentVideoOutputEpoch(epoch)) {
                        Log.d(TAG, "Skipping stale MPV placeholder attach ($reason, epoch=$epoch)")
                        return@withLock
                    }
                    val wasPaused = try {
                        p.getFlag("pause") == true
                    } catch (e: Exception) {
                        cachedPaused
                    }
                    if (!wasPaused) {
                        try {
                            p.setProperty("pause", true)
                            cachedPaused = true
                            pausedForSurfaceLoss = true
                            Log.d(TAG, "Paused MPV for surface loss ($reason, epoch=$epoch)")
                        } catch (e: Exception) {
                            pausedForSurfaceLoss = false
                            Log.w(TAG, "Failed to pause MPV before placeholder attach ($reason)", e)
                        }
                    } else {
                        pausedForSurfaceLoss = false
                    }
                    val surface = placeholderSurface?.takeIf { it.isValid } ?: run {
                        Log.w(TAG, "No valid MPV placeholder surface available for $reason")
                        return@withLock
                    }
                    p.attachSurface(surface)
                    attachedSurface = surface
                    hasAttachedSurface = true
                    attachedToPlaceholder = true
                    lastAppliedSurfaceSize = null
                    Log.d(TAG, "Attached MPV placeholder surface ($reason, epoch=$epoch)")
                }
            } catch (e: CancellationException) {
                Log.d(TAG, "Canceled pending MPV placeholder attach ($reason, epoch=$epoch)")
            } catch (e: Exception) {
                Log.w(TAG, "Failed to attach MPV placeholder surface ($reason)", e)
            }
        }
    }

    private fun detachSurfaceInternal(reason: String) {
        val hadAttachedSurface = hasAttachedSurface || attachedSurface != null
        hasAttachedSurface = false
        attachedSurface = null
        attachedToPlaceholder = false
        videoOutputRestoring = true
        lastAppliedSurfaceSize = null
        val detachEpoch = videoOutputEpoch + 1L
        videoOutputEpoch = detachEpoch

        val p = player ?: return
        if (!hadAttachedSurface) {
            Log.d(TAG, "detachSurfaceInternal($reason): no attached surface to clear")
            return
        }

        schedulePlaceholderSurfaceAttach(
            p = p,
            reason = reason,
            epoch = detachEpoch
        )
        Log.d(TAG, "Cleared MPV surface attachment ($reason, epoch=$detachEpoch)")
    }

    private fun normalizePauseValue(value: String): Boolean? = when (value.lowercase()) {
        "yes", "true", "1" -> true
        "no", "false", "0" -> false
        else -> null
    }

    private fun requestAutoResume(reason: String) {
        val p = player ?: return
        if (disposing) return

        if (resumeBlockedByPublicPause) {
            deferredResumeRequested = false
            Log.d(TAG, "Skipping auto-resume after $reason because playback is explicitly paused")
            return
        }

        if (!hasReadyVideoOutput()) {
            deferredResumeRequested = true
            Log.d(TAG, "Deferring auto-resume after $reason until video output is ready")
            return
        }

        scope.launch {
            try {
                if (p.getFlag("pause") == true) {
                    Log.d(TAG, "Auto-resuming playback after $reason")
                    p.setProperty("pause", false)
                } else {
                    Log.d(TAG, "Skipping auto-resume after $reason because playback is already running")
                }
            } catch (e: Exception) {
                Log.w(TAG, "Failed to resume after $reason", e)
            }
        }
    }

    private suspend fun applyDeferredResumeIfNeeded(p: MpvPlayer, reason: String) {
        if (!deferredResumeRequested) return

        if (resumeBlockedByPublicPause) {
            deferredResumeRequested = false
            Log.d(TAG, "Dropping deferred auto-resume after $reason because playback is explicitly paused")
            return
        }

        deferredResumeRequested = false
        if (p.getFlag("pause") == true) {
            Log.d(TAG, "Applying deferred auto-resume after $reason")
            p.setProperty("pause", false)
        } else {
            Log.d(TAG, "Skipping deferred auto-resume after $reason because playback is already running")
        }
    }

    // Public API

    fun setProperty(name: String, value: String) {
        if (!isInitialized || disposing) return
        if (name == "pause") {
            val paused = normalizePauseValue(value)
            if (paused == true) {
                cachedPaused = true
                pausedForSurfaceLoss = false
                resumeBlockedByPublicPause = true
                deferredResumeRequested = false
                Log.d(TAG, "Public pause state updated: paused=true")
            } else if (paused == false) {
                resumeBlockedByPublicPause = false
                if (!hasReadyVideoOutput()) {
                    deferredResumeRequested = true
                    Log.d(TAG, "Deferring public resume until video output is ready")
                    return
                }
                cachedPaused = false
                pausedForSurfaceLoss = false
                Log.d(TAG, "Public pause state updated: paused=false")
            }
        }
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
            if (visible) {
                flutterOverlayApplied = false
                ensureFlutterOverlayOnTop()
                rememberCurrentSurfaceSize()
                val surface = currentCandidateSurface()
                if (surface != null) {
                    pendingSurface = surface
                    refreshVideoOutput("setVisible")
                } else {
                    val sv = surfaceView
                    if (sv != null) {
                        applySurfaceSize(sv.width, sv.height)
                    }
                }
            }
            Log.d(TAG, "setVisible($visible)")
        }
    }

    fun onPipModeChanged(isInPipMode: Boolean) {
        // MPV handles aspect ratio internally via its own surface management
    }

    fun updateFrame() {
        if (disposing) return
        activity.runOnUiThread {
            if (disposing) return@runOnUiThread
            flutterOverlayApplied = false
            ensureFlutterOverlayOnTop()
            rememberCurrentSurfaceSize()
            val p = player
            if (p == null) {
                Log.d(TAG, "updateFrame(): skipping Android MPV surface refresh because player is not ready")
                return@runOnUiThread
            }
            if (!hasReadyVideoOutput()) {
                val surface = currentCandidateSurface()
                if (surface != null) {
                    pendingSurface = surface
                    refreshVideoOutput("updateFrame")
                } else {
                    Log.d(TAG, "updateFrame(): skipping Android MPV surface refresh because no surface is attached")
                }
                return@runOnUiThread
            }
            scope.launch {
                try {
                    applySurfaceSizeInternal(p, force = true)
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to update Android MPV surface frame", e)
                }
            }
        }
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
        pendingVideoOutputDisableJob?.cancel()
        pendingVideoOutputDisableJob = null
        pendingVideoOutputRefreshJob?.cancel()
        pendingVideoOutputRefreshJob = null

        // Clear surface state flags (no native calls on main thread to avoid ANR)
        val p = player
        if (p != null) {
            hasAttachedSurface = false
            attachedSurface = null
            pausedForSurfaceLoss = false
            attachedToPlaceholder = false
            videoOutputRestoring = false
            lastAppliedSurfaceSize = null
            videoOutputEpoch += 1L
        }

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
        placeholderSurface?.release()
        placeholderSurface = null
        placeholderImageReader?.close()
        placeholderImageReader = null
        pausedForSurfaceLoss = false
        attachedToPlaceholder = false
        videoOutputRestoring = false
        deferredResumeRequested = false
        resumeBlockedByPublicPause = false
        videoOutputEpoch = 0L
        pendingVideoOutputDisableJob = null
        isInitialized = false

        // Detach surface and close player on background thread, then remove views
        if (p != null) {
            Thread {
                try {
                    // Detach surface BEFORE close to prevent GPU mutex contention with view removal
                    try {
                        runBlocking {
                            p.setProperty("force-window", "no")
                            p.setProperty("vo", "null")
                        }
                        p.detachSurface()
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to detach surface during dispose", e)
                    }
                    p.close()
                } catch (e: Exception) {
                    Log.w(TAG, "MPV close failed", e)
                }
                player = null
                Log.d(TAG, "Disposed (native)")
                Handler(Looper.getMainLooper()).post {
                    sv?.holder?.removeCallback(this)
                    if (container?.parent != null) {
                        contentView.removeView(container)
                    }
                    onComplete?.invoke()
                }
            }.start()
        } else {
            // No player — safe to remove views immediately
            Handler(Looper.getMainLooper()).postAtFrontOfQueue {
                sv?.holder?.removeCallback(this)
                if (container?.parent != null) {
                    contentView.removeView(container)
                }
            }
            onComplete?.invoke()
        }

        // Reset scope for potential re-initialization
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    }
}
