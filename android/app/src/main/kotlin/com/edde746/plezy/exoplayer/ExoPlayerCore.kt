package com.edde746.plezy.exoplayer

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.Surface
import android.view.SurfaceView
import android.view.TextureView
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.view.WindowManager
import android.widget.FrameLayout
import androidx.annotation.OptIn
import androidx.annotation.RequiresApi
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.text.CueGroup
import androidx.media3.common.TrackGroup
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import androidx.media3.common.VideoSize
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.mediacodec.MediaCodecSelector
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.extractor.DefaultExtractorsFactory
import androidx.media3.extractor.mkv.MatroskaExtractor
import androidx.media3.ui.CaptionStyleCompat
import androidx.media3.ui.SubtitleView
import io.github.peerless2012.ass.media.AssHandler
import io.github.peerless2012.ass.media.extractor.AssMatroskaExtractor
import io.github.peerless2012.ass.media.factory.AssRenderersFactory
import io.github.peerless2012.ass.media.parser.AssSubtitleParserFactory
import io.github.peerless2012.ass.media.type.AssRenderType
import io.github.peerless2012.ass.media.widget.AssSubtitleView
import java.math.BigDecimal
import java.math.RoundingMode

interface ExoPlayerDelegate {
    fun onPropertyChange(name: String, value: Any?)
    fun onEvent(name: String, data: Map<String, Any>?)

    /**
     * Called when ExoPlayer encounters a format it cannot play.
     * The plugin should handle fallback to MPV.
     * @return true if fallback was handled, false to emit error event to Flutter
     */
    fun onFormatUnsupported(
        uri: String,
        headers: Map<String, String>?,
        positionMs: Long,
        errorMessage: String
    ): Boolean = false
}

@OptIn(UnstableApi::class)
class ExoPlayerCore(private val activity: Activity) : Player.Listener {

    companion object {
        private const val TAG = "ExoPlayerCore"
        private const val SHORT_VIDEO_LENGTH_MS = 300000L // 5 minutes
        private const val WATCHDOG_CHECK_INTERVAL_MS = 1000L
        private const val WATCHDOG_TIMEOUT_MS = 8000L
    }

    private var surfaceView: SurfaceView? = null
    private var surfaceContainer: FrameLayout? = null
    private var subtitleView: SubtitleView? = null
    private var assHandler: AssHandler? = null
    private var overlayLayoutListener: ViewTreeObserver.OnGlobalLayoutListener? = null
    private var lastVideoSize: VideoSize? = null
    private var exoPlayer: ExoPlayer? = null
    private var trackSelector: DefaultTrackSelector? = null
    private var tunnelingUserEnabled: Boolean = true
    private var tunnelingDisabledForCodec: Boolean = false
    private var pendingStartPositionMs: Long = 0L

    // Frame watchdog: detects black screen (audio plays but 0 video frames rendered)
    private var frameWatchdogRunnable: Runnable? = null
    private var frameWatchdogStartTime: Long = 0L
    var delegate: ExoPlayerDelegate? = null
    var debugLoggingEnabled: Boolean = false
    var isInitialized: Boolean = false
        private set

    // Frame rate matching
    private var currentVideoFps: Float = 0f
    private var displayListener: DisplayManager.DisplayListener? = null
    private val handler = Handler(Looper.getMainLooper())

    // Audio focus
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var hasAudioFocus: Boolean = false
    private var wasPlayingBeforeFocusLoss: Boolean = false

    // Track state for event emission
    private var lastPosition: Long = 0
    private var lastDuration: Long = 0
    private var lastBufferedPosition: Long = 0
    private var positionUpdateRunnable: Runnable? = null

    // External subtitles added dynamically
    private val externalSubtitles = mutableListOf<MediaItem.SubtitleConfiguration>()
    private var currentMediaUri: String? = null
    private var currentHeaders: Map<String, String>? = null

    private val audioFocusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AudioManager.AUDIOFOCUS_GAIN -> {
                emitLog("debug", "audio", "Focus gained")
                hasAudioFocus = true
                if (wasPlayingBeforeFocusLoss && isInitialized) {
                    exoPlayer?.play()
                    wasPlayingBeforeFocusLoss = false
                }
            }
            AudioManager.AUDIOFOCUS_LOSS -> {
                emitLog("debug", "audio", "Focus lost permanently")
                hasAudioFocus = false
                if (isInitialized) {
                    wasPlayingBeforeFocusLoss = exoPlayer?.isPlaying == true
                    exoPlayer?.pause()
                }
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                emitLog("debug", "audio", "Focus lost transiently")
                hasAudioFocus = false
                if (isInitialized) {
                    wasPlayingBeforeFocusLoss = exoPlayer?.isPlaying == true
                    exoPlayer?.pause()
                }
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                emitLog("debug", "audio", "Focus lost transiently (can duck)")
                // Don't pause — let the system handle volume ducking for notifications
            }
        }
    }

    private fun emitLog(level: String, prefix: String, message: String) {
        when (level) {
            "error" -> Log.e(TAG, "[$prefix] $message")
            "warn"  -> Log.w(TAG, "[$prefix] $message")
            "info"  -> Log.i(TAG, "[$prefix] $message")
            else    -> Log.d(TAG, "[$prefix] $message")
        }
        if (debugLoggingEnabled) {
            delegate?.onEvent("log-message", mapOf(
                "prefix" to prefix, "level" to level, "text" to message
            ))
        }
    }

    private fun redactUri(uri: String): String {
        return try {
            val parsed = Uri.parse(uri)
            val params = parsed.queryParameterNames
            if (params.isEmpty()) return uri
            val builder = parsed.buildUpon().clearQuery()
            for (name in params) {
                val lower = name.lowercase()
                if (lower.contains("token") || lower.contains("key") || lower.contains("auth")) {
                    builder.appendQueryParameter(name, "[REDACTED]")
                } else {
                    builder.appendQueryParameter(name, parsed.getQueryParameter(name))
                }
            }
            builder.build().toString()
        } catch (_: Exception) {
            uri
        }
    }

    private fun ensureFlutterOverlayOnTop() {
        val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
        contentView.post {
            if (!isInitialized) return@post
            var flutterContainer: ViewGroup? = null

            for (i in 0 until contentView.childCount) {
                val child = contentView.getChildAt(i)
                if (child is ViewGroup && child.javaClass.name.contains("FlutterView")) {
                    flutterContainer = child
                    break
                }
            }

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
                contentView.bringChildToFront(container)
                for (j in 0 until container.childCount) {
                    val flutterChild = container.getChildAt(j)
                    if (flutterChild is SurfaceView) {
                        // Don't use setZOrderOnTop - let Flutter render in normal view order
                        // This allows SubtitleView (added via addContentView) to render above
                        flutterChild.setZOrderOnTop(false)
                        flutterChild.setZOrderMediaOverlay(true)
                        flutterChild.holder.setFormat(PixelFormat.TRANSLUCENT)
                        break
                    } else if (flutterChild is TextureView) {
                        flutterChild.isOpaque = false
                        break
                    }
                }
            }

        }
    }

    private fun configureSubtitleOverlaySurface() {
        subtitleView?.post {
            val count = subtitleView?.childCount ?: 0
            for (i in 0 until count) {
                val child = subtitleView?.getChildAt(i)
                if (child is SurfaceView) {
                    child.setZOrderOnTop(false)
                    child.setZOrderMediaOverlay(true)
                    child.holder.setFormat(PixelFormat.TRANSLUCENT)
                } else if (child is TextureView) {
                    child.isOpaque = false
                }
            }
        }
    }

    fun initialize(bufferSizeBytes: Int? = null, tunnelingEnabled: Boolean = true): Boolean {
        if (isInitialized) {
            Log.d(TAG, "Already initialized")
            return true
        }

        tunnelingUserEnabled = tunnelingEnabled

        try {
            audioManager = activity.getSystemService(Context.AUDIO_SERVICE) as AudioManager

            // Create FrameLayout container for video (enables centering for aspect ratio)
            surfaceContainer = FrameLayout(activity).apply {
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
                setBackgroundColor(Color.BLACK)
            }

            // Create SurfaceView for video rendering
            surfaceView = SurfaceView(activity).apply {
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                ).apply {
                    gravity = Gravity.CENTER
                }
                holder.addCallback(surfaceCallback)
                setZOrderOnTop(false)
                setZOrderMediaOverlay(false)
            }

            surfaceContainer!!.addView(surfaceView)

            // Create SubtitleView - added to surfaceContainer above video
            // With OVERLAY_OPEN_GL mode, libass-android adds AssSubtitleTextureView as a child
            // which renders ASS subtitles with full styling using GPU texture composition
            subtitleView = SubtitleView(activity).apply {
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )
            }
            // Add SubtitleView to surfaceContainer (above video SurfaceView)
            // Flutter renders on top of entire surfaceContainer, keeping subtitles below UI
            surfaceContainer!!.addView(subtitleView)
            Log.d(TAG, "SubtitleView created and added to surfaceContainer")

            val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
            contentView.addView(surfaceContainer, 0)

            // Find FlutterView and configure z-order
            // Video SurfaceView is at the bottom (setZOrderOnTop=false, setZOrderMediaOverlay=false)
            // Flutter SurfaceView uses setZOrderMediaOverlay to render above video and subtitles
            for (i in 0 until contentView.childCount) {
                val child = contentView.getChildAt(i)
                if (child is ViewGroup && child.javaClass.name.contains("FlutterView")) {
                    contentView.bringChildToFront(child)
                    for (j in 0 until child.childCount) {
                        val flutterChild = child.getChildAt(j)
                        if (flutterChild is SurfaceView) {
                            // Use setZOrderMediaOverlay instead of setZOrderOnTop
                            // This puts Flutter above video but below normal views
                            flutterChild.setZOrderOnTop(false)
                            flutterChild.setZOrderMediaOverlay(true)
                            flutterChild.holder.setFormat(PixelFormat.TRANSLUCENT)
                            break
                        }
                    }
                    break
                }
            }

            ensureFlutterOverlayOnTop()
            overlayLayoutListener = ViewTreeObserver.OnGlobalLayoutListener {
                ensureFlutterOverlayOnTop()
                // Recalculate surface size on layout change (orientation/PiP transitions)
                lastVideoSize?.let { vs ->
                    if (vs.width > 0 && vs.height > 0) {
                        updateSurfaceViewSize(vs.width, vs.height, vs.pixelWidthHeightRatio)
                    }
                }
            }
            contentView.viewTreeObserver.addOnGlobalLayoutListener(overlayLayoutListener)

            Log.d(TAG, "SurfaceView added to content view")

            // Create track selector with text tracks enabled
            trackSelector = DefaultTrackSelector(activity).apply {
                setParameters(
                    buildUponParameters()
                        .setTunnelingEnabled(tunnelingUserEnabled)
                        .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, false)
                        .setPreferredTextLanguage("en")
                )
            }

            // Create ExoPlayer with FFmpeg audio decoder fallback
            val audioAttributes = androidx.media3.common.AudioAttributes.Builder()
                .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
                .setUsage(C.USAGE_MEDIA)
                .build()

            // Use DefaultRenderersFactory with FFmpeg fallback for unsupported audio codecs
            val renderersFactory = DefaultRenderersFactory(activity).apply {
                setEnableDecoderFallback(true)
                setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_ON)
                // Force FFmpeg for FLAC — hardware FLAC decoders (e.g. Samsung c2.sec.flac.decoder)
                // have buggy 32KB input buffer limits causing InsufficientCapacityException.
                setMediaCodecSelector { mimeType, requiresSecureDecoder, requiresTunnelingDecoder ->
                    if (mimeType == MimeTypes.AUDIO_FLAC) {
                        emptyList()
                    } else {
                        MediaCodecSelector.DEFAULT.getDecoderInfos(
                            mimeType, requiresSecureDecoder, requiresTunnelingDecoder
                        )
                    }
                }
            }

            // Create factories for buildWithAssSupport (like AndroidTV-FireTV)
            val dataSourceFactory = DefaultDataSource.Factory(activity)
            val extractorsFactory = DefaultExtractorsFactory()

            // Inline buildWithAssSupport to retain AssHandler reference for font scale control.
            // OVERLAY_OPEN_GL uses TextureView which follows normal View hierarchy z-ordering,
            // preventing hardware overlay promotion issues on devices like Nvidia Shield.
            Log.d(TAG, "SubtitleView childCount before ASS setup: ${subtitleView?.childCount}")

            val renderType = AssRenderType.OVERLAY_OPEN_GL
            val handler = AssHandler(renderType)
            assHandler = handler

            val assParserFactory = AssSubtitleParserFactory(handler)

            // Wrap extractors to replace MatroskaExtractor with ASS-aware variant
            val wrappedExtractorsFactory = androidx.media3.extractor.ExtractorsFactory {
                extractorsFactory.createExtractors().map { extractor ->
                    if (extractor is androidx.media3.extractor.mkv.MatroskaExtractor) {
                        AssMatroskaExtractor(assParserFactory, handler)
                    } else {
                        extractor
                    }
                }.toTypedArray()
            }

            val mediaSourceFactory = DefaultMediaSourceFactory(dataSourceFactory, wrappedExtractorsFactory)
                .setSubtitleParserFactory(assParserFactory)

            val wrappedRenderersFactory = AssRenderersFactory(handler, renderersFactory)

            // Compute memory-aware buffer limits to prevent CCodec OOM crashes
            val activityManager = activity.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val memoryInfo = ActivityManager.MemoryInfo()
            activityManager.getMemoryInfo(memoryInfo)
            val availableMB = memoryInfo.availMem / (1024 * 1024)

            val targetBufferBytes = if (bufferSizeBytes != null && bufferSizeBytes > 0) {
                bufferSizeBytes
            } else {
                // Scale buffer to available memory to reduce hardware decoder pressure
                when {
                    availableMB <= 512 -> 30 * 1024 * 1024
                    availableMB <= 1024 -> 50 * 1024 * 1024
                    availableMB <= 2048 -> 60 * 1024 * 1024
                    else -> 130 * 1024 * 1024
                }
            }

            val loadControl = DefaultLoadControl.Builder().apply {
                setTargetBufferBytes(targetBufferBytes)
                setPrioritizeTimeOverSizeThresholds(false)
                if (availableMB <= 2048) {
                    setBufferDurationsMs(15_000, 50_000, 2_500, 5_000)
                } else {
                    setBufferDurationsMs(30_000, 60_000, 2_500, 5_000)
                }
            }.build()
            emitLog("info", "init", "Buffer: ${targetBufferBytes / 1024 / 1024}MB limit, available=${availableMB}MB, tunneling=${tunnelingUserEnabled}")

            exoPlayer = ExoPlayer.Builder(activity)
                .setTrackSelector(trackSelector!!)
                .setLoadControl(loadControl)
                .setAudioAttributes(audioAttributes, false) // We handle audio focus manually
                .setMediaSourceFactory(mediaSourceFactory)
                .setRenderersFactory(wrappedRenderersFactory)
                .build()

            // Add ASS overlay view to SubtitleView for OVERLAY modes
            subtitleView?.let { sv ->
                val assView = AssSubtitleView(sv.context, handler)
                sv.addView(assView)
            }

            // Initialize handler (registers as Player.Listener, creates Handler)
            handler.init(exoPlayer!!)

            exoPlayer!!.addListener(this)
            surfaceView?.let { exoPlayer!!.setVideoSurfaceView(it) }

            Log.d(TAG, "SubtitleView childCount after ASS setup: ${subtitleView?.childCount}")
            configureSubtitleOverlaySurface()

            // Debug: Log SubtitleView child hierarchy
            subtitleView?.post {
                Log.d(TAG, "SubtitleView post-layout: width=${subtitleView?.width}, height=${subtitleView?.height}, childCount=${subtitleView?.childCount}")
                for (i in 0 until (subtitleView?.childCount ?: 0)) {
                    val child = subtitleView?.getChildAt(i)
                    Log.d(TAG, "  Child $i: ${child?.javaClass?.simpleName}, w=${child?.width}, h=${child?.height}, visibility=${child?.visibility}")
                }
            }

            // Start position update loop
            startPositionUpdates()

            isInitialized = true
            Log.d(TAG, "Initialized successfully")
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize: ${e.message}", e)
            return false
        }
    }

    private val surfaceCallback = object : android.view.SurfaceHolder.Callback {
        override fun surfaceCreated(holder: android.view.SurfaceHolder) {
            emitLog("debug", "surface", "Created")
            ensureFlutterOverlayOnTop()
        }

        override fun surfaceChanged(holder: android.view.SurfaceHolder, format: Int, width: Int, height: Int) {
            emitLog("debug", "surface", "Changed: ${width}x${height}")
        }

        override fun surfaceDestroyed(holder: android.view.SurfaceHolder) {
            emitLog("debug", "surface", "Destroyed")
        }
    }

    private fun startPositionUpdates() {
        positionUpdateRunnable = object : Runnable {
            override fun run() {
                if (isInitialized && exoPlayer != null) {
                    val player = exoPlayer!!
                    val currentPosition = player.currentPosition
                    val duration = player.duration
                    val bufferedPosition = player.bufferedPosition

                    // Emit position changes (every 250ms update)
                    if (currentPosition != lastPosition) {
                        lastPosition = currentPosition
                        delegate?.onPropertyChange("time-pos", currentPosition / 1000.0)
                    }

                    // Emit duration changes
                    if (duration != lastDuration && duration != C.TIME_UNSET) {
                        lastDuration = duration
                        delegate?.onPropertyChange("duration", duration / 1000.0)
                    }

                    // Emit buffer changes
                    if (bufferedPosition != lastBufferedPosition && bufferedPosition != C.TIME_UNSET) {
                        lastBufferedPosition = bufferedPosition
                        delegate?.onPropertyChange("demuxer-cache-time", bufferedPosition / 1000.0)
                    }

                    handler.postDelayed(this, 250)
                }
            }
        }
        handler.post(positionUpdateRunnable!!)
    }

    private fun stopPositionUpdates() {
        positionUpdateRunnable?.let { handler.removeCallbacks(it) }
        positionUpdateRunnable = null
    }

    // Player.Listener

    override fun onCues(cueGroup: CueGroup) {
        // With OVERLAY_CANVAS mode, ASS subtitles are rendered directly by AssSubtitleView
        // This callback is for non-ASS subtitles (SRT, VTT, etc.)
        if (cueGroup.cues.isNotEmpty()) {
            Log.d(TAG, "onCues: received ${cueGroup.cues.size} cues (non-ASS)")
        }
        subtitleView?.setCues(cueGroup.cues)
    }

    override fun onIsPlayingChanged(isPlaying: Boolean) {
        Log.d(TAG, "onIsPlayingChanged: $isPlaying")
        delegate?.onPropertyChange("pause", !isPlaying)
    }

    override fun onPlaybackStateChanged(state: Int) {
        val stateStr = when (state) {
            Player.STATE_IDLE -> "idle"
            Player.STATE_BUFFERING -> "buffering"
            Player.STATE_READY -> "ready"
            Player.STATE_ENDED -> "ended"
            else -> "unknown"
        }
        emitLog("debug", "state", stateStr)

        when (state) {
            Player.STATE_BUFFERING -> {
                delegate?.onPropertyChange("paused-for-cache", true)
            }
            Player.STATE_READY -> {
                // Restore start position if it was lost during track reselection
                // (e.g. tunneling state change in onTracksChanged triggers renderer teardown)
                if (pendingStartPositionMs > 0L) {
                    val currentPos = exoPlayer?.currentPosition ?: 0L
                    if (currentPos < 1000L) {
                        emitLog("warn", "state", "Position lost (at ${currentPos}ms, expected ${pendingStartPositionMs}ms) — restoring")
                        exoPlayer?.seekTo(pendingStartPositionMs)
                    }
                    pendingStartPositionMs = 0L
                }
                delegate?.onPropertyChange("paused-for-cache", false)
                delegate?.onEvent("playback-restart", null)
                emitTrackList()

                // Start frame watchdog to detect black screen (HDR tunneling issue)
                startFrameWatchdog()
            }
            Player.STATE_ENDED -> {
                stopFrameWatchdog()
                delegate?.onPropertyChange("eof-reached", true)
                delegate?.onEvent("end-file", mapOf("reason" to "eof"))
            }
        }
    }

    override fun onTracksChanged(tracks: Tracks) {
        Log.d(TAG, "onTracksChanged")
        // Log selected video and audio track details
        val videoGroup = tracks.groups.firstOrNull { it.type == C.TRACK_TYPE_VIDEO && it.isSelected }
        val audioGroup = tracks.groups.firstOrNull { it.type == C.TRACK_TYPE_AUDIO && it.isSelected }
        if (videoGroup != null) {
            val vf = videoGroup.mediaTrackGroup.getFormat(0)
            val hdr = vf.colorInfo?.let { ci ->
                val transfer = ci.colorTransfer
                if (transfer != null && transfer != 0) " HDR(transfer=$transfer)" else ""
            } ?: ""
            emitLog("info", "tracks", "Video: ${vf.codecs} ${vf.width}x${vf.height}$hdr")
        }
        if (audioGroup != null) {
            val af = audioGroup.mediaTrackGroup.getFormat(0)
            emitLog("info", "tracks", "Audio: ${af.codecs} ${af.channelCount}ch ${af.sampleRate}Hz")
        }
        evaluateAudioCodecForTunneling()
        emitTrackList()
    }

    override fun onPlayerError(error: PlaybackException) {
        emitLog("error", "player", "Error code=${error.errorCode}: ${error.message}, cause=${error.cause?.javaClass?.simpleName}")
        stopFrameWatchdog()

        if (currentMediaUri != null) {
            Log.w(TAG, "ExoPlayer error (code ${error.errorCode}) - attempting fallback to MPV")
            val handled = delegate?.onFormatUnsupported(
                uri = currentMediaUri!!,
                headers = currentHeaders,
                positionMs = lastPosition,
                errorMessage = error.message ?: "Unknown error"
            ) ?: false

            if (handled) return
        }

        delegate?.onEvent("end-file", mapOf(
            "reason" to "error",
            "message" to (error.message ?: "Unknown error")
        ))
    }

    override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
        Log.d(TAG, "onMediaItemTransition: ${mediaItem?.mediaId}, reason: $reason")
        delegate?.onEvent("file-loaded", null)
        delegate?.onPropertyChange("eof-reached", false)
    }

    override fun onVideoSizeChanged(videoSize: VideoSize) {
        Log.d(TAG, "Video size changed: ${videoSize.width}x${videoSize.height}, ratio: ${videoSize.pixelWidthHeightRatio}")
        lastVideoSize = videoSize
        updateSurfaceViewSize(videoSize.width, videoSize.height, videoSize.pixelWidthHeightRatio)
    }

    private fun updateSurfaceViewSize(videoWidth: Int, videoHeight: Int, pixelRatio: Float) {
        if (videoWidth == 0 || videoHeight == 0) return

        val surface = surfaceView ?: return
        val subtitle = subtitleView
        val contentView = activity.findViewById<ViewGroup>(android.R.id.content)

        val containerWidth = contentView.width
        val containerHeight = contentView.height
        if (containerWidth == 0 || containerHeight == 0) return

        // Calculate video aspect ratio (accounting for non-square pixels)
        val videoAspect = (videoWidth * pixelRatio) / videoHeight
        val containerAspect = containerWidth.toFloat() / containerHeight

        val (newWidth, newHeight) = if (videoAspect > containerAspect) {
            // Video is wider - fit to width, letterbox top/bottom
            containerWidth to (containerWidth / videoAspect).toInt()
        } else {
            // Video is taller - fit to height, pillarbox left/right
            (containerHeight * videoAspect).toInt() to containerHeight
        }

        activity.runOnUiThread {
            surface.layoutParams = FrameLayout.LayoutParams(newWidth, newHeight).apply {
                gravity = Gravity.CENTER
            }
            surface.requestLayout()
            subtitle?.let { sv ->
                sv.layoutParams = FrameLayout.LayoutParams(newWidth, newHeight).apply {
                    gravity = Gravity.CENTER
                }
                sv.requestLayout()
            }
        }
    }

    private fun emitTrackList() {
        val player = exoPlayer ?: return
        val tracks = player.currentTracks

        val trackList = mutableListOf<Map<String, Any?>>()

        // Group tracks by type and use group index as track ID (matching select functions)
        val audioGroups = tracks.groups.filter { it.type == C.TRACK_TYPE_AUDIO }
        val textGroups = tracks.groups.filter { it.type == C.TRACK_TYPE_TEXT }
        val videoGroups = tracks.groups.filter { it.type == C.TRACK_TYPE_VIDEO }

        var selectedAudioId: String? = null
        var selectedSubId: String? = null

        // Process audio tracks
        audioGroups.forEachIndexed { groupIndex, group ->
            val trackGroup = group.mediaTrackGroup
            // Use first format in group as the representative track
            val format = trackGroup.getFormat(0)
            val trackId = "${C.TRACK_TYPE_AUDIO}_$groupIndex"
            val isSelected = group.isSelected

            val track = mutableMapOf<String, Any?>(
                "type" to "audio",
                "id" to trackId,
                "title" to format.label,
                "lang" to format.language,
                "codec" to format.codecs,
                "default" to (format.selectionFlags and C.SELECTION_FLAG_DEFAULT != 0),
                "selected" to isSelected,
                "demux-channel-count" to format.channelCount,
                "demux-samplerate" to format.sampleRate
            )
            trackList.add(track)

            if (isSelected) {
                selectedAudioId = trackId
            }
        }

        // Process subtitle tracks
        Log.d(TAG, "emitTrackList: found ${textGroups.size} subtitle track groups")
        textGroups.forEachIndexed { groupIndex, group ->
            val trackGroup = group.mediaTrackGroup
            val format = trackGroup.getFormat(0)
            val trackId = "${C.TRACK_TYPE_TEXT}_$groupIndex"
            val isSelected = group.isSelected

            Log.d(TAG, "Subtitle track $groupIndex: codec=${format.codecs}, lang=${format.language}, selected=$isSelected")

            val track = mutableMapOf<String, Any?>(
                "type" to "sub",
                "id" to trackId,
                "title" to format.label,
                "lang" to format.language,
                "codec" to format.codecs,
                "default" to (format.selectionFlags and C.SELECTION_FLAG_DEFAULT != 0),
                "selected" to isSelected,
                "external" to false
            )
            trackList.add(track)

            if (isSelected) {
                selectedSubId = trackId
            }
        }

        // Process video tracks (for completeness, typically only one)
        videoGroups.forEachIndexed { groupIndex, group ->
            val trackGroup = group.mediaTrackGroup
            val format = trackGroup.getFormat(0)
            val trackId = "${C.TRACK_TYPE_VIDEO}_$groupIndex"

            val track = mutableMapOf<String, Any?>(
                "type" to "video",
                "id" to trackId,
                "title" to format.label,
                "lang" to format.language,
                "codec" to format.codecs,
                "default" to (format.selectionFlags and C.SELECTION_FLAG_DEFAULT != 0),
                "selected" to group.isSelected
            )
            trackList.add(track)
        }

        // Emit selected track IDs
        selectedAudioId?.let { delegate?.onPropertyChange("aid", it) }
        if (selectedSubId != null) {
            delegate?.onPropertyChange("sid", selectedSubId)
        } else if (textGroups.isNotEmpty()) {
            // No subtitle selected
            delegate?.onPropertyChange("sid", "no")
        }

        // Add external subtitles to track list
        externalSubtitles.forEachIndexed { index, subtitle ->
            val extTrackId = "ext_sub_$index"
            trackList.add(mapOf(
                "type" to "sub",
                "id" to extTrackId,
                "title" to (subtitle.label ?: "External"),
                "lang" to subtitle.language,
                "codec" to subtitle.mimeType,
                "default" to false,
                "external" to true,
                "external-filename" to subtitle.uri.toString()
            ))
        }

        delegate?.onPropertyChange("track-list", trackList)
    }

    // Tunneling control — disabled when audio codec has no hardware decoder (requires FFmpeg)

    private fun hasHardwareAudioDecoder(mimeType: String): Boolean {
        // FLAC hardware decoders are excluded via MediaCodecSelector (Samsung c2.sec.flac.decoder
        // has buggy 32KB input buffer limits), so report no hardware decoder for tunneling purposes.
        if (mimeType == MimeTypes.AUDIO_FLAC) return false
        try {
            val codecList = android.media.MediaCodecList(android.media.MediaCodecList.REGULAR_CODECS)
            for (info in codecList.codecInfos) {
                if (info.isEncoder) continue
                for (type in info.supportedTypes) {
                    if (type.equals(mimeType, ignoreCase = true)) {
                        val name = info.name
                        if (!name.startsWith("OMX.google.") &&
                            !name.startsWith("c2.android.") &&
                            !name.contains(".sw.") &&
                            !name.startsWith("c2.ffmpeg.")) {
                            Log.d(TAG, "Found hardware audio decoder for $mimeType: $name")
                            return true
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to query audio decoders for $mimeType: ${e.message}")
        }
        Log.d(TAG, "No hardware audio decoder for $mimeType — FFmpeg will handle it")
        return false
    }

    private fun updateTunnelingState() {
        val selector = trackSelector ?: return
        val player = exoPlayer ?: return
        val currentSpeed = player.playbackParameters.speed
        val shouldTunnel = tunnelingUserEnabled && (currentSpeed == 1f) && !tunnelingDisabledForCodec
        val currentTunneling = selector.parameters.tunnelingEnabled
        if (shouldTunnel == currentTunneling) return  // No change needed
        emitLog("info", "tunneling", "tunneling $currentTunneling -> $shouldTunnel (user=$tunnelingUserEnabled, speed=$currentSpeed, codecDisabled=$tunnelingDisabledForCodec)")
        selector.setParameters(
            selector.buildUponParameters()
                .setTunnelingEnabled(shouldTunnel)
        )
        // Track reselection from setParameters() can reset position during initial load.
        // Restore the pending start position if it hasn't been consumed yet.
        if (pendingStartPositionMs > 0L) {
            player.seekTo(pendingStartPositionMs)
        }
    }

    private fun evaluateAudioCodecForTunneling() {
        val player = exoPlayer ?: return
        val selectedAudioGroup = player.currentTracks.groups.firstOrNull {
            it.type == C.TRACK_TYPE_AUDIO && it.isSelected
        } ?: return

        val format = selectedAudioGroup.mediaTrackGroup.getFormat(0)
        val mimeType = format.sampleMimeType ?: return

        val newDisabled = !hasHardwareAudioDecoder(mimeType)
        if (newDisabled != tunnelingDisabledForCodec) {
            tunnelingDisabledForCodec = newDisabled
            emitLog("info", "tunneling", "Audio codec ${format.codecs} ($mimeType): tunneling ${if (newDisabled) "DISABLED (no hw decoder)" else "enabled"}")
            updateTunnelingState()
        }
    }

    // Frame watchdog: detects when ExoPlayer plays audio but renders 0 video frames
    // (common with HDR tunneling on unsupported devices — black screen, no error)

    private fun startFrameWatchdog() {
        stopFrameWatchdog()
        emitLog("debug", "watchdog", "Started (timeout=${WATCHDOG_TIMEOUT_MS}ms)")
        frameWatchdogStartTime = System.currentTimeMillis()
        frameWatchdogRunnable = object : Runnable {
            override fun run() {
                val player = exoPlayer ?: return
                val renderedFrames = player.videoDecoderCounters?.renderedOutputBufferCount ?: 0

                if (renderedFrames > 0) {
                    emitLog("debug", "watchdog", "$renderedFrames frames rendered, cleared")
                    stopFrameWatchdog()
                    return
                }

                val elapsed = System.currentTimeMillis() - frameWatchdogStartTime

                // Check if we have a video track selected
                val hasVideoTrack = player.currentTracks.groups.any {
                    it.type == C.TRACK_TYPE_VIDEO && it.isSelected
                }

                if (elapsed >= WATCHDOG_TIMEOUT_MS && player.isPlaying && hasVideoTrack) {
                    emitLog("warn", "watchdog", "0 frames rendered after ${elapsed}ms — triggering fallback")
                    stopFrameWatchdog()
                    // Trigger fallback via the same delegate path as player errors
                    val uri = currentMediaUri ?: return
                    delegate?.onFormatUnsupported(
                        uri = uri,
                        headers = currentHeaders,
                        positionMs = player.currentPosition,
                        errorMessage = "Black screen detected: 0 video frames rendered after ${elapsed}ms"
                    )
                    return
                }

                handler.postDelayed(this, WATCHDOG_CHECK_INTERVAL_MS)
            }
        }
        handler.postDelayed(frameWatchdogRunnable!!, WATCHDOG_CHECK_INTERVAL_MS)
    }

    private fun stopFrameWatchdog() {
        frameWatchdogRunnable?.let { handler.removeCallbacks(it) }
        frameWatchdogRunnable = null
    }

    // Public API

    fun open(uri: String, headers: Map<String, String>?, startPositionMs: Long, autoPlay: Boolean, isLive: Boolean = false) {
        if (!isInitialized) return

        currentMediaUri = uri
        currentHeaders = headers
        externalSubtitles.clear()
        tunnelingDisabledForCodec = false
        pendingStartPositionMs = startPositionMs

        if (isLive) {
            // Live MKV streams lack Cues (seek index). FLAG_DISABLE_SEEK_FOR_CUES tells
            // MatroskaExtractor to not seek for them, treating the stream as unseekable
            // so data flows immediately without hanging.
            val dataSourceFactory = if (!headers.isNullOrEmpty()) {
                DefaultDataSource.Factory(activity,
                    androidx.media3.datasource.DefaultHttpDataSource.Factory()
                        .setDefaultRequestProperties(headers))
            } else {
                DefaultDataSource.Factory(activity)
            }

            val extractorsFactory = androidx.media3.extractor.ExtractorsFactory {
                arrayOf(MatroskaExtractor(MatroskaExtractor.FLAG_DISABLE_SEEK_FOR_CUES))
            }

            val mediaSource = ProgressiveMediaSource.Factory(dataSourceFactory, extractorsFactory)
                .createMediaSource(MediaItem.fromUri(uri))

            exoPlayer?.apply {
                setMediaSource(mediaSource, startPositionMs)
                prepare()
                playWhenReady = autoPlay
            }

            emitLog("info", "media", "Opened live: ${redactUri(uri)}, startPosition: ${startPositionMs}ms, autoPlay: $autoPlay")
            return
        }

        val mediaItemBuilder = MediaItem.Builder()
            .setUri(uri)

        // Add headers if provided
        if (!headers.isNullOrEmpty()) {
            val dataSourceFactory = androidx.media3.datasource.DefaultHttpDataSource.Factory()
                .setDefaultRequestProperties(headers)
            // Note: For proper header support, we'd need to configure this at player level
            // For now, headers are handled via URL parameters if needed
        }

        val mediaItem = mediaItemBuilder.build()

        exoPlayer?.apply {
            setMediaItem(mediaItem, startPositionMs)
            prepare()
            playWhenReady = autoPlay
        }

        emitLog("info", "media", "Opened: ${redactUri(uri)}, startPosition: ${startPositionMs}ms, autoPlay: $autoPlay, tunneling=$tunnelingUserEnabled")
    }

    fun play() {
        exoPlayer?.play()
    }

    fun pause() {
        exoPlayer?.pause()
    }

    fun stop() {
        stopFrameWatchdog()
        exoPlayer?.stop()
        setVisible(false)
    }

    fun seekTo(positionMs: Long) {
        exoPlayer?.seekTo(positionMs)
    }

    fun setVolume(volume: Float) {
        exoPlayer?.volume = volume.coerceIn(0f, 1f)
        delegate?.onPropertyChange("volume", (volume * 100).toDouble())
    }

    fun setPlaybackSpeed(speed: Float) {
        val clampedSpeed = speed.coerceIn(0.25f, 4f)
        exoPlayer?.setPlaybackSpeed(clampedSpeed)
        updateTunnelingState()
        delegate?.onPropertyChange("speed", speed.toDouble())
    }

    fun selectAudioTrack(trackId: String) {
        val player = exoPlayer ?: return
        val selector = trackSelector ?: return

        // Parse track ID (format: "type_index")
        val parts = trackId.split("_")
        if (parts.size < 2) return

        val trackIndex = parts[1].toIntOrNull() ?: return

        val audioGroups = player.currentTracks.groups.filter { it.type == C.TRACK_TYPE_AUDIO }
        if (trackIndex >= 0 && trackIndex < audioGroups.size) {
            val group = audioGroups[trackIndex]

            // Pre-evaluate the new track's codec for tunneling before applying the override,
            // so tunneling state is set correctly in the same parameter update.
            val format = group.mediaTrackGroup.getFormat(0)
            val mimeType = format.sampleMimeType
            if (mimeType != null) {
                tunnelingDisabledForCodec = !hasHardwareAudioDecoder(mimeType)
                Log.i(TAG, "Audio track switch to ${format.codecs} ($mimeType): tunneling ${if (tunnelingDisabledForCodec) "DISABLED" else "enabled"}")
            }

            val currentSpeed = player.playbackParameters.speed
            val shouldTunnel = tunnelingUserEnabled && (currentSpeed == 1f) && !tunnelingDisabledForCodec

            selector.parameters = selector.buildUponParameters()
                .setOverrideForType(TrackSelectionOverride(group.mediaTrackGroup, 0))
                .setTrackTypeDisabled(C.TRACK_TYPE_AUDIO, false)
                .setTunnelingEnabled(shouldTunnel)
                .build()

            delegate?.onPropertyChange("aid", trackId)
        }
    }

    fun selectSubtitleTrack(trackId: String?) {
        val player = exoPlayer ?: return
        val selector = trackSelector ?: return

        if (trackId == null || trackId == "no") {
            // Disable subtitles
            selector.parameters = selector.buildUponParameters()
                .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
                .build()
            delegate?.onPropertyChange("sid", "no")
            return
        }

        // Check if external subtitle
        if (trackId.startsWith("ext_sub_")) {
            val index = trackId.removePrefix("ext_sub_").toIntOrNull() ?: return
            if (index >= 0 && index < externalSubtitles.size) {
                // Reload media with selected external subtitle
                reloadWithExternalSubtitle(index)
                return
            }
        }

        // Parse track ID for embedded subtitles
        val parts = trackId.split("_")
        if (parts.size < 2) return

        val trackIndex = parts[1].toIntOrNull() ?: return

        val textGroups = player.currentTracks.groups.filter { it.type == C.TRACK_TYPE_TEXT }
        if (trackIndex >= 0 && trackIndex < textGroups.size) {
            val group = textGroups[trackIndex]
            selector.parameters = selector.buildUponParameters()
                .setOverrideForType(TrackSelectionOverride(group.mediaTrackGroup, 0))
                .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, false)
                .build()

            delegate?.onPropertyChange("sid", trackId)
        }
    }

    private fun reloadWithExternalSubtitle(subtitleIndex: Int) {
        val uri = currentMediaUri ?: return
        val player = exoPlayer ?: return

        val currentPosition = player.currentPosition
        val wasPlaying = player.isPlaying

        val mediaItemBuilder = MediaItem.Builder()
            .setUri(uri)

        // Add the selected external subtitle
        if (subtitleIndex >= 0 && subtitleIndex < externalSubtitles.size) {
            val subtitle = externalSubtitles[subtitleIndex]
            mediaItemBuilder.setSubtitleConfigurations(listOf(subtitle))
        }

        val mediaItem = mediaItemBuilder.build()

        player.setMediaItem(mediaItem, currentPosition)
        player.prepare()
        player.playWhenReady = wasPlaying

        delegate?.onPropertyChange("sid", "ext_sub_$subtitleIndex")
    }

    fun addSubtitleTrack(uri: String, title: String?, language: String?, mimeType: String?, select: Boolean) {
        val subtitleConfig = MediaItem.SubtitleConfiguration.Builder(Uri.parse(uri))
            .setLabel(title ?: "External")
            .setLanguage(language)
            .setMimeType(mimeType ?: detectSubtitleMimeType(uri))
            .setSelectionFlags(if (select) C.SELECTION_FLAG_DEFAULT else 0)
            .build()

        externalSubtitles.add(subtitleConfig)

        // Emit updated track list
        emitTrackList()

        if (select) {
            selectSubtitleTrack("ext_sub_${externalSubtitles.size - 1}")
        }
    }

    private fun detectSubtitleMimeType(uri: String): String {
        val lowerUri = uri.lowercase()
        return when {
            lowerUri.endsWith(".srt") -> MimeTypes.APPLICATION_SUBRIP
            lowerUri.endsWith(".ass") || lowerUri.endsWith(".ssa") -> MimeTypes.TEXT_SSA
            lowerUri.endsWith(".vtt") -> MimeTypes.TEXT_VTT
            lowerUri.endsWith(".ttml") -> MimeTypes.APPLICATION_TTML
            else -> MimeTypes.APPLICATION_SUBRIP
        }
    }

    fun setVisible(visible: Boolean) {
        activity.runOnUiThread {
            surfaceContainer?.visibility = if (visible) View.VISIBLE else View.INVISIBLE
            // subtitleView is inside surfaceContainer, inherits visibility
            Log.d(TAG, "setVisible($visible)")
        }
    }

    fun setSubtitleStyle(
        fontSize: Float,
        textColor: String,
        borderSize: Float,
        borderColor: String,
        bgColor: String,
        bgOpacity: Int,
        subtitlePosition: Int = 100
    ) {
        activity.runOnUiThread {
            // 1. Non-ASS subtitles: CaptionStyleCompat on SubtitleView
            val fgColor = Color.parseColor(textColor)
            val bgAlpha = (bgOpacity * 255 / 100)
            val bgColorInt = Color.parseColor(bgColor).let {
                Color.argb(bgAlpha, Color.red(it), Color.green(it), Color.blue(it))
            }
            val edgeColor = Color.parseColor(borderColor)
            val edgeType = if (borderSize > 0) CaptionStyleCompat.EDGE_TYPE_OUTLINE
                           else CaptionStyleCompat.EDGE_TYPE_NONE

            val style = CaptionStyleCompat(
                fgColor,
                bgColorInt,
                Color.TRANSPARENT,
                edgeType,
                edgeColor,
                null
            )
            subtitleView?.setStyle(style)
            // Font size: MPV sub-font-size is scaled pixels at 720p height
            // Convert to fractional size (0.0-1.0 relative to view height)
            val fraction = fontSize / 720f
            subtitleView?.setFractionalTextSize(fraction)

            // Subtitle position: adjust gravity and bottom padding
            val clampedPosition = subtitlePosition.coerceIn(0, 100)
            val gravity = when {
                clampedPosition <= 33 -> Gravity.TOP
                clampedPosition <= 66 -> Gravity.CENTER
                else -> Gravity.BOTTOM
            }
            (subtitleView?.layoutParams as? FrameLayout.LayoutParams)?.let { params ->
                params.gravity = gravity or Gravity.CENTER_HORIZONTAL
                subtitleView?.layoutParams = params
            }
            // Fine-grained positioning within bottom region via bottom padding fraction
            if (clampedPosition > 66) {
                val bottomFraction = (100 - clampedPosition) / 100f
                subtitleView?.setBottomPaddingFraction(bottomFraction)
            } else {
                subtitleView?.setBottomPaddingFraction(0f)
            }

            // 2. ASS subtitles: font scale via libass
            // MPV default sub-font-size is 38
            val defaultSize = 38f
            val scale = fontSize / defaultSize
            try {
                assHandler?.render?.setFontScale(scale)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to set ASS font scale: ${e.message}")
            }

            Log.d(TAG, "setSubtitleStyle: fontSize=$fontSize, textColor=$textColor, borderSize=$borderSize, bgOpacity=$bgOpacity, position=$subtitlePosition, assScale=$scale")
        }
    }

    fun onPipModeChanged(isInPipMode: Boolean) {
        activity.runOnUiThread {
            // Force recalculation of surface size based on new container dimensions
            // Use a slight delay to allow the window to resize first
            handler.postDelayed({
                val videoSize = exoPlayer?.videoSize
                if (videoSize != null && videoSize.width > 0 && videoSize.height > 0) {
                    updateSurfaceViewSize(videoSize.width, videoSize.height, videoSize.pixelWidthHeightRatio)
                }
            }, 100)
        }
    }

    // Audio Focus

    fun requestAudioFocus(): Boolean {
        val am = audioManager ?: return false

        Log.d(TAG, "Requesting audio focus")

        val result = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
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

    // Frame Rate Matching

    private fun getDisplayManager(): DisplayManager {
        return activity.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
    }

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

        emitLog("info", "framerate", "fps=$fps, duration=${videoDurationMs}ms, API=${Build.VERSION.SDK_INT}")

        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> setFrameRateS(fps, surface, videoDurationMs)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> setFrameRateR(fps, surface)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> setFrameRateM(fps)
        }
    }

    fun clearVideoFrameRate() {
        Log.d(TAG, "clearVideoFrameRate")
        currentVideoFps = 0f
        displayListener?.let {
            getDisplayManager().unregisterDisplayListener(it)
            displayListener = null
        }
    }

    private fun registerDisplayListener() {
        displayListener?.let {
            getDisplayManager().unregisterDisplayListener(it)
        }

        displayListener = object : DisplayManager.DisplayListener {
            override fun onDisplayAdded(displayId: Int) = Unit
            override fun onDisplayRemoved(displayId: Int) = Unit
            override fun onDisplayChanged(displayId: Int) {
                handler.postDelayed({
                    if (exoPlayer?.isPlaying == false && wasPlayingBeforeFocusLoss) {
                        Log.d(TAG, "Display changed, resuming playback")
                        exoPlayer?.play()
                    }
                }, 2000L)
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

        if (videoDurationMs < SHORT_VIDEO_LENGTH_MS) {
            Log.d(TAG, "Short video, using seamless-only switching")
            surface.setFrameRate(
                fps,
                Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
                Surface.CHANGE_FRAME_RATE_ONLY_IF_SEAMLESS
            )
            return
        }

        var seamless = false
        activity.display?.mode?.alternativeRefreshRates?.let { refreshRates ->
            for (rate in refreshRates) {
                if (fps.toString().startsWith(rate.toString()) ||
                    rate.toString().startsWith(fps.toString()) ||
                    rate % fps == 0f) {
                    seamless = true
                    break
                }
            }
        }

        if (seamless) {
            emitLog("info", "framerate", "Seamless switch available for ${fps}fps")
            surface.setFrameRate(
                fps,
                Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
                Surface.CHANGE_FRAME_RATE_ALWAYS
            )
            registerDisplayListener()
        } else {
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
                Log.d(TAG, "Non-seamless switch not allowed, using seamless-only")
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
        @Suppress("DEPRECATION")
        val display = wm.defaultDisplay ?: return

        display.supportedModes?.let { supportedModes ->
            val currentMode = display.mode
            var modeToUse = currentMode

            for (mode in supportedModes) {
                if (mode.physicalHeight != currentMode.physicalHeight ||
                    mode.physicalWidth != currentMode.physicalWidth) {
                    continue
                }

                if (BigDecimal(fps.toString()).setScale(1, RoundingMode.FLOOR) ==
                    BigDecimal(mode.refreshRate.toString()).setScale(1, RoundingMode.FLOOR)) {
                    modeToUse = mode
                    break
                } else if (mode.refreshRate % fps == 0f) {
                    modeToUse = mode
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
            }
        }
    }

    // Stats

    fun getStats(): Map<String, Any?> {
        val player = exoPlayer ?: return emptyMap()
        val videoFormat = player.videoFormat
        val audioFormat = player.audioFormat

        // Get decoder info from the format's codecs field and check if hardware accelerated
        val videoDecoderInfo = getVideoDecoderInfo(videoFormat)

        return mapOf(
            // Video metrics
            "videoCodec" to videoFormat?.codecs,
            "videoMimeType" to videoFormat?.sampleMimeType,
            "videoWidth" to videoFormat?.width,
            "videoHeight" to videoFormat?.height,
            "videoFps" to videoFormat?.frameRate,
            "videoBitrate" to videoFormat?.bitrate,
            "videoDecoderName" to videoDecoderInfo,
            "videoDroppedFrames" to player.videoDecoderCounters?.droppedBufferCount,
            "videoRenderedFrames" to player.videoDecoderCounters?.renderedOutputBufferCount,
            // Color info
            "colorSpace" to videoFormat?.colorInfo?.colorSpace,
            "colorRange" to videoFormat?.colorInfo?.colorRange,
            "colorTransfer" to videoFormat?.colorInfo?.colorTransfer,
            "hdrStaticInfo" to (videoFormat?.colorInfo?.hdrStaticInfo != null),
            // Audio metrics
            "audioCodec" to audioFormat?.codecs,
            "audioMimeType" to audioFormat?.sampleMimeType,
            "audioSampleRate" to audioFormat?.sampleRate,
            "audioChannels" to audioFormat?.channelCount,
            "audioBitrate" to audioFormat?.bitrate,
            // Buffer metrics
            "bufferedPositionMs" to player.bufferedPosition,
            "currentPositionMs" to player.currentPosition,
            "totalBufferedDurationMs" to player.totalBufferedDuration,
            // Playback state
            "playbackSpeed" to player.playbackParameters.speed,
            "isPlaying" to player.isPlaying,
            "playbackState" to player.playbackState,
        )
    }

    private fun getVideoDecoderInfo(videoFormat: androidx.media3.common.Format?): String? {
        if (videoFormat == null) return null
        val mimeType = videoFormat.sampleMimeType ?: return null

        // Check available decoders for this mime type
        try {
            val codecList = android.media.MediaCodecList(android.media.MediaCodecList.ALL_CODECS)
            for (info in codecList.codecInfos) {
                if (info.isEncoder) continue
                for (type in info.supportedTypes) {
                    if (type.equals(mimeType, ignoreCase = true)) {
                        // Return the first hardware decoder found, or software if none
                        val name = info.name
                        if (!name.startsWith("OMX.google.") && !name.contains(".sw.")) {
                            return name // Hardware decoder
                        }
                    }
                }
            }
            // Fallback - assume software if no HW decoder found
            return "Software"
        } catch (e: Exception) {
            return null
        }
    }

    // Cleanup

    fun dispose() {
        Log.d(TAG, "Disposing")

        stopFrameWatchdog()
        stopPositionUpdates()
        clearVideoFrameRate()
        abandonAudioFocus()
        audioManager = null

        tunnelingDisabledForCodec = false
        pendingStartPositionMs = 0L
        exoPlayer?.clearVideoSurface()
        exoPlayer?.removeListener(this)
        exoPlayer?.release()
        exoPlayer = null
        trackSelector = null
        assHandler = null

        val cb = surfaceCallback
        val sv = surfaceView
        overlayLayoutListener?.let { listener ->
            val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
            contentView.viewTreeObserver.removeOnGlobalLayoutListener(listener)
        }
        overlayLayoutListener = null

        // Defer all view removal to avoid AOSP bug where
        // dispatchWindowVisibilityChanged iterates stale children array
        // when removeView() runs during an active performTraversals pass.
        val container = surfaceContainer
        val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
        contentView.post {
            sv?.holder?.removeCallback(cb)
            container?.let { contentView.removeView(it) }
        }
        surfaceContainer = null
        surfaceView = null
        subtitleView = null

        isInitialized = false
        Log.d(TAG, "Disposed")
    }
}
