package com.edde746.plezy.exoplayer

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.SurfaceView
import android.view.TextureView
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.widget.FrameLayout
import androidx.annotation.OptIn
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
import androidx.media3.exoplayer.analytics.AnalyticsListener
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.mediacodec.MediaCodecSelector
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.extractor.DefaultExtractorsFactory
import androidx.media3.extractor.mp4.FragmentedMp4Extractor
import androidx.media3.extractor.mp4.Mp4Extractor
import androidx.media3.extractor.mkv.MatroskaExtractor
import androidx.media3.ui.CaptionStyleCompat
import androidx.media3.ui.SubtitleView
import com.edde746.plezy.shared.AudioFocusManager
import com.edde746.plezy.shared.FlutterOverlayHelper
import com.edde746.plezy.shared.FrameRateManager
import io.github.peerless2012.ass.media.AssHandler
import io.github.peerless2012.ass.media.extractor.AssMatroskaExtractor
import io.github.peerless2012.ass.media.factory.AssRenderersFactory
import io.github.peerless2012.ass.media.parser.AssSubtitleParserFactory
import io.github.peerless2012.ass.media.type.AssRenderType
import io.github.peerless2012.ass.media.widget.AssSubtitleView

interface ExoPlayerDelegate : com.edde746.plezy.shared.PlayerDelegate {

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

        private const val WATCHDOG_CHECK_INTERVAL_MS = 1000L
        private const val WATCHDOG_TIMEOUT_MS = 8000L
        private const val DECODER_HANG_TIMEOUT_MS = 5000L

        // Codec capability caches — codec support doesn't change at runtime
        private val hwAudioDecoderCache = HashMap<String, Boolean>()
        private val tunneledPlaybackCache = HashMap<String, Boolean>()

        private var assGlCrashHandlerInstalled = false
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
    private var tunnelingDisabledForAudioCodec: Boolean = false
    private var tunnelingDisabledForVideoCodec: Boolean = false
    private val tunnelingDisabledForCodec: Boolean
        get() = tunnelingDisabledForAudioCodec || tunnelingDisabledForVideoCodec
    private var currentTunneledPlayback: Boolean = false
    private var lastSeekable: Boolean? = null
    @Volatile private var disposing: Boolean = false
    private var pendingStartPositionMs: Long = 0L

    // Frame watchdog: detects black screen (audio plays but 0 video frames rendered)
    private var frameWatchdogRunnable: Runnable? = null
    private var frameWatchdogStartTime: Long = 0L
    // Decoder hang detection: tracks gap between decoder init and first rendered frame
    private var decoderHangRunnable: Runnable? = null
    private var decoderInitName: String? = null
    private var audioDecoderInitName: String? = null
    private var firstFrameRendered: Boolean = false
    var delegate: ExoPlayerDelegate? = null
    var debugLoggingEnabled: Boolean = false
    var isInitialized: Boolean = false
        private set

    // Frame rate matching
    private var frameRateManager: FrameRateManager? = null
    private val handler = Handler(Looper.getMainLooper())

    // Audio focus
    private var audioFocusManager: AudioFocusManager? = null

    // Track state for event emission
    private var lastPosition: Long = 0
    private var lastDuration: Long = 0
    private var lastBufferedPosition: Long = 0
    private var positionUpdateRunnable: Runnable? = null

    // External subtitles added dynamically
    private val externalSubtitles = mutableListOf<MediaItem.SubtitleConfiguration>()
    private var currentMediaUri: String? = null
    private var currentHeaders: Map<String, String>? = null
    private var currentMediaIsLive: Boolean = false
    private var currentVisible: Boolean = false
    private var selectedAudioTrackId: String? = null
    private var selectedSubtitleTrackId: String? = null
    private var selectedExternalSubtitleIndex: Int? = null

    private fun emitLog(level: String, prefix: String, message: String) {
        when (level) {
            "error" -> Log.e(TAG, "[$prefix] $message")
            "warn"  -> Log.w(TAG, "[$prefix] $message")
            "info"  -> Log.i(TAG, "[$prefix] $message")
            else    -> Log.d(TAG, "[$prefix] $message")
        }
        if (debugLoggingEnabled || level == "error" || level == "warn") {
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
        if (disposing) return
        val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
        contentView.post {
            if (disposing || !isInitialized) return@post
            val container = FlutterOverlayHelper.findFlutterContainer(contentView, surfaceContainer)
                ?: return@post
            FlutterOverlayHelper.configureFlutterZOrder(contentView, container, zOrderOnTop = false)
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

    // DV conversion state
    private var dvMode: DvConversionMode = DvConversionMode.DISABLED
    private var dv7RetryAttempted = false
    @Volatile private var activeDoviMkvWrapper: DoviExtractorWrapper? = null
    @Volatile private var activeDoviMp4Wrapper: DoviExtractorWrapper? = null

    fun initialize(bufferSizeBytes: Int? = null, tunnelingEnabled: Boolean = true): Boolean {
        if (isInitialized) {
            Log.d(TAG, "Already initialized")
            return true
        }

        tunnelingUserEnabled = tunnelingEnabled
        this.dvMode = DoviBridge.getConversionMode()
        Log.i(TAG, "DV conversion: mode=$dvMode, bridge=${DoviBridge.isAvailable()}, " +
            "deviceDV7=${DoviBridge.deviceSupportsDvProfile7}, deviceDV8=${DoviBridge.deviceSupportsDvProfile8}")
        disposing = false

        try {
            audioFocusManager = AudioFocusManager(
                context = activity,
                handler = handler,
                onPause = { if (isInitialized) exoPlayer?.pause() },
                onResume = { if (isInitialized) exoPlayer?.play() },
                isPaused = { exoPlayer?.isPlaying != true },
                log = { emitLog("debug", "audio", it) }
            )
            frameRateManager = FrameRateManager(
                activity = activity,
                handler = handler,
                onDisplayChanged = {
                    if (exoPlayer?.isPlaying == false && audioFocusManager?.wasPlayingBeforeFocusLoss == true) {
                        Log.d(TAG, "Display changed, resuming playback")
                        exoPlayer?.play()
                    }
                },
                log = { emitLog("info", "framerate", it) }
            )

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
            // Video SurfaceView is at the bottom, Flutter uses setZOrderMediaOverlay to render above
            FlutterOverlayHelper.findFlutterContainer(contentView, surfaceContainer)?.let { container ->
                FlutterOverlayHelper.configureFlutterZOrder(contentView, container, zOrderOnTop = false)
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
            val renderersFactory = PlezyRenderersFactory(activity).apply {
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

            // Wrap extractors: replace MatroskaExtractor with ASS+DV variant,
            // wrap MP4 extractors with DV converter when enabled.
            // Reads this.dvMode each time (not captured) so DV7→8.1 retry can
            // change mode and reload without reinitializing the player.
            val wrappedExtractorsFactory = androidx.media3.extractor.ExtractorsFactory {
                val currentDvMode = this.dvMode
                val doviEnabled = currentDvMode != DvConversionMode.DISABLED
                extractorsFactory.createExtractors().map { extractor ->
                    when {
                        extractor is MatroskaExtractor -> {
                            val assExtractor = AssMatroskaExtractor(assParserFactory, handler)
                            if (doviEnabled) {
                                DoviExtractorWrapper(assExtractor, currentDvMode).also {
                                    activeDoviMkvWrapper = it
                                }
                            } else {
                                assExtractor
                            }
                        }
                        doviEnabled && (extractor is Mp4Extractor || extractor is FragmentedMp4Extractor) -> {
                            DoviExtractorWrapper(extractor, currentDvMode).also {
                                activeDoviMp4Wrapper = it
                            }
                        }
                        else -> extractor
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

            // Suppress ass-media GL thread crash when EGL init partially fails (e.g. Tegra).
            // AssRender.onSurfaceDestroyed() accesses uninitialized glProgram lateinit property
            // during error cleanup, which is a bug in the library. The render thread dying only
            // affects ASS subtitle GPU rendering; non-ASS subtitles are unaffected.
            if (!assGlCrashHandlerInstalled) {
                assGlCrashHandlerInstalled = true
                val previousHandler = Thread.getDefaultUncaughtExceptionHandler()
                Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
                    if (thread.name.contains("AssTexRenderThread") &&
                        throwable is UninitializedPropertyAccessException) {
                        Log.e(TAG, "ASS GL thread crash suppressed (EGL init failure)", throwable)
                    } else {
                        previousHandler?.uncaughtException(thread, throwable)
                    }
                }
            }

            exoPlayer!!.addListener(this)
            exoPlayer!!.addAnalyticsListener(decoderHangListener)
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
            if (disposing) return
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

    private fun emitSeekable(seekable: Boolean, force: Boolean = false) {
        if (!force && lastSeekable == seekable) return
        lastSeekable = seekable
        delegate?.onPropertyChange("seekable", seekable)
    }

    private fun emitCurrentSeekable(force: Boolean = false) {
        val player = exoPlayer
        val seekable = player?.isCurrentMediaItemSeekable == true && !currentMediaIsLive
        emitSeekable(seekable, force)
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
        emitCurrentSeekable()

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
        // Detect video track present but deselected (unsupported codec — plays audio only)
        val hasAnyVideoGroup = tracks.groups.any { it.type == C.TRACK_TYPE_VIDEO }
        val hasSelectedVideo = tracks.groups.any { it.type == C.TRACK_TYPE_VIDEO && it.isSelected }
        if (hasAnyVideoGroup && !hasSelectedVideo && currentMediaUri != null) {
            // Try DV conversion before falling to MPV
            if (retryWithDvConversion("video track not selected")) return
            emitLog("warn", "fallback", "Video track present but not selected (unsupported codec)")
            delegate?.onFormatUnsupported(
                uri = currentMediaUri!!,
                headers = currentHeaders,
                positionMs = lastPosition,
                errorMessage = "Video track present but no decoder available"
            )
            return
        }

        evaluateAudioCodecForTunneling()
        evaluateVideoCodecForTunneling()
        updateTunnelingState("tracks changed")
        emitTrackList()
    }

    override fun onPlayerError(error: PlaybackException) {
        emitLog("error", "player", "Error code=${error.errorCode}: ${error.message}, cause=${error.cause?.javaClass?.simpleName}")
        stopFrameWatchdog()
        cancelDecoderHangCheck()
        emitSeekable(false, force = true)

        // If native DV7 failed, retry with conversion before falling to MPV
        if (error.errorCode in 4001..4005 && retryWithDvConversion("decoder error ${error.errorCode}")) return

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

    /**
     * When native DV7 decoding fails (device falsely advertises DV7 support),
     * upgrade to DV7→8.1 conversion or HEVC strip and reload the media.
     * Returns true if retry was initiated.
     */
    private fun retryWithDvConversion(reason: String): Boolean {
        if (dv7RetryAttempted) return false
        if (dvMode != DvConversionMode.DISABLED) return false
        if (!DoviBridge.isAvailable()) return false
        val uri = currentMediaUri ?: return false

        dv7RetryAttempted = true
        val newMode = DoviBridge.getDv7FallbackMode()
        dvMode = newMode
        Log.i(TAG, "Native DV7 playback failed ($reason), retrying with $newMode")
        emitLog("info", "dv-fallback", "DV7 native failed ($reason), retrying as $newMode")

        open(
            uri = uri,
            headers = currentHeaders,
            startPositionMs = lastPosition,
            autoPlay = true,
        )
        return true
    }

    override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
        Log.d(TAG, "onMediaItemTransition: ${mediaItem?.mediaId}, reason: $reason")
        delegate?.onEvent("file-loaded", null)
        delegate?.onPropertyChange("eof-reached", false)
        emitCurrentSeekable(force = true)
    }

    override fun onVideoSizeChanged(videoSize: VideoSize) {
        Log.d(TAG, "Video size changed: ${videoSize.width}x${videoSize.height}, ratio: ${videoSize.pixelWidthHeightRatio}")
        lastVideoSize = videoSize
        updateSurfaceViewSize(videoSize.width, videoSize.height, videoSize.pixelWidthHeightRatio)
    }

    private fun updateSurfaceViewSize(videoWidth: Int, videoHeight: Int, pixelRatio: Float) {
        if (disposing) return
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
        if (selectedAudioId != null) {
            selectedAudioTrackId = selectedAudioId
            delegate?.onPropertyChange("aid", selectedAudioId)
        }

        val effectiveSubtitleId = when {
            selectedExternalSubtitleIndex != null -> "ext_sub_$selectedExternalSubtitleIndex"
            selectedSubId != null -> selectedSubId
            textGroups.isNotEmpty() || externalSubtitles.isNotEmpty() -> "no"
            else -> null
        }
        if (effectiveSubtitleId != null) {
            selectedSubtitleTrackId = effectiveSubtitleId
            delegate?.onPropertyChange("sid", effectiveSubtitleId)
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
                "selected" to (selectedExternalSubtitleIndex == index),
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
        hwAudioDecoderCache[mimeType]?.let { return it }
        val result = try {
            val codecList = android.media.MediaCodecList(android.media.MediaCodecList.REGULAR_CODECS)
            var found = false
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
                            found = true
                            break
                        }
                    }
                }
                if (found) break
            }
            if (!found) Log.d(TAG, "No hardware audio decoder for $mimeType — FFmpeg will handle it")
            found
        } catch (e: Exception) {
            Log.w(TAG, "Failed to query audio decoders for $mimeType: ${e.message}")
            false
        }
        hwAudioDecoderCache[mimeType] = result
        return result
    }

    private fun videoCodecSupportsTunneledPlayback(mimeType: String): Boolean {
        tunneledPlaybackCache[mimeType]?.let { return it }
        val result = try {
            val codecList = android.media.MediaCodecList(android.media.MediaCodecList.REGULAR_CODECS)
            var supported = false
            for (info in codecList.codecInfos) {
                if (info.isEncoder) continue
                for (type in info.supportedTypes) {
                    if (type.equals(mimeType, ignoreCase = true)) {
                        val name = info.name
                        if (name.startsWith("OMX.google.") ||
                            name.startsWith("c2.android.") ||
                            name.contains(".sw.") ||
                            name.startsWith("c2.ffmpeg.")) {
                            continue // Skip software decoders
                        }
                        val caps = info.getCapabilitiesForType(type)
                        if (caps.isFeatureSupported(android.media.MediaCodecInfo.CodecCapabilities.FEATURE_TunneledPlayback)) {
                            Log.d(TAG, "Hardware video decoder $name supports tunneled playback for $mimeType")
                            supported = true
                            break
                        } else {
                            Log.d(TAG, "Hardware video decoder $name does NOT support tunneled playback for $mimeType")
                        }
                    }
                }
                if (supported) break
            }
            supported
        } catch (e: Exception) {
            Log.w(TAG, "Failed to query video decoders for tunneling support ($mimeType): ${e.message}")
            false
        }
        tunneledPlaybackCache[mimeType] = result
        return result
    }

    private fun evaluateVideoCodecForTunneling() {
        val player = exoPlayer ?: return
        val selectedVideoGroup = player.currentTracks.groups.firstOrNull {
            it.type == C.TRACK_TYPE_VIDEO && it.isSelected
        } ?: return

        val format = selectedVideoGroup.mediaTrackGroup.getFormat(0)
        val mimeType = format.sampleMimeType ?: return

        val newDisabled = !videoCodecSupportsTunneledPlayback(mimeType)
        if (newDisabled != tunnelingDisabledForVideoCodec) {
            tunnelingDisabledForVideoCodec = newDisabled
            emitLog("info", "tunneling", "Video codec ${format.codecs} ($mimeType): tunneling ${if (newDisabled) "DISABLED (no tunneling support)" else "enabled"}")
        }
    }

    private fun updateTunnelingState(reason: String) {
        val selector = trackSelector ?: return
        val player = exoPlayer ?: return
        val shouldTunnel = tunnelingUserEnabled && (player.playbackParameters.speed == 1f) && !tunnelingDisabledForCodec
        if (shouldTunnel == currentTunneledPlayback) return
        currentTunneledPlayback = shouldTunnel
        emitLog("info", "tunneling", "Toggling tunneling=$shouldTunnel (reason=$reason, user=$tunnelingUserEnabled, speed=${player.playbackParameters.speed}, audioCodecDisabled=$tunnelingDisabledForAudioCodec, videoCodecDisabled=$tunnelingDisabledForVideoCodec)")
        selector.setParameters(
            selector.buildUponParameters().setTunnelingEnabled(shouldTunnel)
        )
    }

    private fun evaluateAudioCodecForTunneling() {
        val player = exoPlayer ?: return
        val selectedAudioGroup = player.currentTracks.groups.firstOrNull {
            it.type == C.TRACK_TYPE_AUDIO && it.isSelected
        } ?: return

        val format = selectedAudioGroup.mediaTrackGroup.getFormat(0)
        val mimeType = format.sampleMimeType ?: return

        val newDisabled = !hasHardwareAudioDecoder(mimeType)
        if (newDisabled != tunnelingDisabledForAudioCodec) {
            tunnelingDisabledForAudioCodec = newDisabled
            emitLog("info", "tunneling", "Audio codec ${format.codecs} ($mimeType): tunneling ${if (newDisabled) "DISABLED (no hw decoder)" else "enabled"}")
        }
    }

    private fun buildMediaItem(uri: String): MediaItem {
        val mediaItemBuilder = MediaItem.Builder()
            .setUri(uri)

        selectedExternalSubtitleIndex?.takeIf { it in externalSubtitles.indices }?.let { subtitleIndex ->
            mediaItemBuilder.setSubtitleConfigurations(listOf(externalSubtitles[subtitleIndex]))
        }

        return mediaItemBuilder.build()
    }

    // Decoder hang detection via AnalyticsListener:
    // Tracks the gap between onVideoDecoderInitialized and onRenderedFirstFrame.
    // If the decoder is initialized and fed input but never produces output, it's hung
    // (e.g. DV profile 7 on PowerVR GPUs that accept the format but never decode).

    private val decoderHangListener = object : AnalyticsListener {
        override fun onVideoDecoderInitialized(
            eventTime: AnalyticsListener.EventTime,
            decoderName: String,
            initializationDurationMs: Long
        ) {
            decoderInitName = decoderName
            firstFrameRendered = false
            emitLog("debug", "decoder-hang", "Decoder initialized: $decoderName (${initializationDurationMs}ms)")
            startDecoderHangCheck(decoderName)
        }

        override fun onAudioDecoderInitialized(
            eventTime: AnalyticsListener.EventTime,
            decoderName: String,
            initializationDurationMs: Long
        ) {
            audioDecoderInitName = decoderName
        }

        override fun onRenderedFirstFrame(
            eventTime: AnalyticsListener.EventTime,
            output: Any,
            renderTimeMs: Long
        ) {
            firstFrameRendered = true
            cancelDecoderHangCheck()
            emitLog("debug", "decoder-hang", "First frame rendered — decoder OK")
        }
    }

    private fun startDecoderHangCheck(decoderName: String) {
        cancelDecoderHangCheck()
        if (currentMediaUri == null) return
        decoderHangRunnable = Runnable {
            if (firstFrameRendered) return@Runnable
            val uri = currentMediaUri ?: return@Runnable
            val player = exoPlayer ?: return@Runnable

            // Confirm via DecoderCounters: input queued but no output produced
            val counters = player.videoDecoderCounters
            val inputQueued = counters?.queuedInputBufferCount ?: 0
            val outputTotal = (counters?.renderedOutputBufferCount ?: 0) +
                    (counters?.skippedOutputBufferCount ?: 0) +
                    (counters?.droppedBufferCount ?: 0)

            if (inputQueued > 0 && outputTotal == 0) {
                emitLog("warn", "fallback", "Decoder hang: $decoderName queued $inputQueued buffers, 0 output after ${DECODER_HANG_TIMEOUT_MS}ms")
                stopFrameWatchdog()
                cancelDecoderHangCheck()
                delegate?.onFormatUnsupported(
                    uri = uri,
                    headers = currentHeaders,
                    positionMs = lastPosition,
                    errorMessage = "Decoder hang: $decoderName accepted input but produced no output"
                )
            }
        }
        handler.postDelayed(decoderHangRunnable!!, DECODER_HANG_TIMEOUT_MS)
    }

    private fun cancelDecoderHangCheck() {
        decoderHangRunnable?.let { handler.removeCallbacks(it) }
        decoderHangRunnable = null
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
                val hasAnyVideoGroup = player.currentTracks.groups.any {
                    it.type == C.TRACK_TYPE_VIDEO
                }

                // Secondary safety net: video track exists but was deselected (unsupported codec)
                if (hasAnyVideoGroup && !hasVideoTrack) {
                    emitLog("warn", "watchdog", "Video track deselected — triggering fallback")
                    stopFrameWatchdog()
                    val uri = currentMediaUri ?: return
                    delegate?.onFormatUnsupported(
                        uri = uri,
                        headers = currentHeaders,
                        positionMs = player.currentPosition,
                        errorMessage = "Video track present but no decoder available"
                    )
                    return
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

        stopFrameWatchdog()
        cancelDecoderHangCheck()

        // Reset DV7 retry flag when opening a different file
        if (uri != currentMediaUri) {
            dv7RetryAttempted = false
        }

        decoderInitName = null
        audioDecoderInitName = null
        currentMediaUri = uri
        currentHeaders = headers
        currentMediaIsLive = isLive
        externalSubtitles.clear()
        selectedExternalSubtitleIndex = null
        selectedAudioTrackId = null
        selectedSubtitleTrackId = null
        tunnelingDisabledForAudioCodec = false
        tunnelingDisabledForVideoCodec = false
        currentTunneledPlayback = tunnelingUserEnabled
        pendingStartPositionMs = startPositionMs
        trackSelector?.setParameters(
            trackSelector!!.buildUponParameters().setTunnelingEnabled(tunnelingUserEnabled)
        )
        emitSeekable(false, force = true)

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

            emitLog("info", "media", "Opened live: ${redactUri(uri)}, startPosition: ${startPositionMs}ms, autoPlay: $autoPlay, sessionTunneling=$currentTunneledPlayback")
            return
        }

        val mediaItem = buildMediaItem(uri)

        exoPlayer?.apply {
            setMediaItem(mediaItem, startPositionMs)
            prepare()
            playWhenReady = autoPlay
        }

        emitLog("info", "media", "Opened: ${redactUri(uri)}, startPosition: ${startPositionMs}ms, autoPlay: $autoPlay, sessionTunneling=$currentTunneledPlayback, userTunneling=$tunnelingUserEnabled")
    }

    fun play() {
        exoPlayer?.play()
    }

    fun pause() {
        exoPlayer?.pause()
    }

    fun stop() {
        stopFrameWatchdog()
        cancelDecoderHangCheck()
        exoPlayer?.stop()
        emitSeekable(false, force = true)
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
        updateTunnelingState("speed changed")
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
            selector.parameters = selector.buildUponParameters()
                .setOverrideForType(TrackSelectionOverride(group.mediaTrackGroup, 0))
                .setTrackTypeDisabled(C.TRACK_TYPE_AUDIO, false)
                .build()

            selectedAudioTrackId = trackId
            delegate?.onPropertyChange("aid", trackId)
        }
    }

    fun selectSubtitleTrack(trackId: String?) {
        val player = exoPlayer ?: return
        val selector = trackSelector ?: return

        if (trackId == null || trackId == "no") {
            // Disable subtitles
            selectedExternalSubtitleIndex = null
            selectedSubtitleTrackId = "no"
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
                selectedExternalSubtitleIndex = index
                selectedSubtitleTrackId = trackId
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
            selectedExternalSubtitleIndex = null
            selectedSubtitleTrackId = trackId
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
        val shouldResume = player.playWhenReady
        selectedExternalSubtitleIndex = subtitleIndex
        selectedSubtitleTrackId = "ext_sub_$subtitleIndex"
        val mediaItem = buildMediaItem(uri)

        player.setMediaItem(mediaItem, currentPosition)
        player.prepare()
        player.playWhenReady = shouldResume

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
        if (disposing) return
        currentVisible = visible
        activity.runOnUiThread {
            if (disposing) return@runOnUiThread
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
        if (disposing) return
        activity.runOnUiThread {
            if (disposing) return@runOnUiThread
            // Force recalculation of surface size based on new container dimensions
            // Use a slight delay to allow the window to resize first
            handler.postDelayed({
                if (disposing) return@postDelayed
                val videoSize = exoPlayer?.videoSize
                if (videoSize != null && videoSize.width > 0 && videoSize.height > 0) {
                    updateSurfaceViewSize(videoSize.width, videoSize.height, videoSize.pixelWidthHeightRatio)
                }
            }, 100)
        }
    }

    // Audio Focus

    fun requestAudioFocus(): Boolean = audioFocusManager?.requestAudioFocus() ?: false

    fun abandonAudioFocus() { audioFocusManager?.abandonAudioFocus() }

    // Frame Rate Matching

    fun setVideoFrameRate(fps: Float, videoDurationMs: Long) {
        frameRateManager?.setVideoFrameRate(fps, videoDurationMs, surfaceView?.holder?.surface)
    }

    fun clearVideoFrameRate() {
        frameRateManager?.clearVideoFrameRate()
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
            "videoDecoderName" to (decoderInitName ?: videoDecoderInfo),
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
            "audioDecoderName" to audioDecoderInitName,
            // Tunneling
            "tunneledPlayback" to currentTunneledPlayback,
            "tunnelingStatus" to getTunnelingStatus(player),
            // Buffer metrics
            "bufferedPositionMs" to player.bufferedPosition,
            "currentPositionMs" to player.currentPosition,
            "totalBufferedDurationMs" to player.totalBufferedDuration,
            // Playback state
            "playbackSpeed" to player.playbackParameters.speed,
            "isPlaying" to player.isPlaying,
            "playbackState" to player.playbackState,
            // DV conversion (query extractor's track output, which is set during extraction)
            *(activeDoviMkvWrapper?.doviTrackOutput
                ?: activeDoviMp4Wrapper?.doviTrackOutput).let { dovi ->
                arrayOf(
                    "dvConversionActive" to (dovi?.conversionActive == true),
                    "dvConversionMode" to dvMode.name,
                    "dvStrippedNals" to (dovi?.strippedNalCount ?: 0L),
                    "dvConvertedRpus" to (dovi?.convertedRpuCount ?: 0L),
                )
            },
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

    private fun getTunnelingStatus(player: ExoPlayer): String {
        if (currentTunneledPlayback) return "Active"
        if (!tunnelingUserEnabled) return "Disabled by user"
        if (player.playbackParameters.speed != 1f) return "Off (speed ≠ 1×)"
        if (tunnelingDisabledForVideoCodec) return "Off (video codec unsupported)"
        if (tunnelingDisabledForAudioCodec) return "Off (no HW audio decoder)"
        return "Off"
    }

    // Cleanup

    fun dispose() {
        if (disposing) return
        disposing = true
        Log.d(TAG, "Disposing")

        stopFrameWatchdog()
        cancelDecoderHangCheck()
        stopPositionUpdates()
        handler.removeCallbacksAndMessages(null)
        frameRateManager?.clearVideoFrameRate()
        frameRateManager = null
        audioFocusManager?.release()
        audioFocusManager = null

        decoderInitName = null
        audioDecoderInitName = null
        tunnelingDisabledForAudioCodec = false
        tunnelingDisabledForVideoCodec = false
        currentTunneledPlayback = false
        pendingStartPositionMs = 0L
        currentMediaIsLive = false
        currentVisible = false
        emitSeekable(false, force = true)
        selectedAudioTrackId = null
        selectedSubtitleTrackId = null
        selectedExternalSubtitleIndex = null
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
            surfaceContainer = null
            surfaceView = null
            subtitleView = null
        }

        isInitialized = false
        Log.d(TAG, "Disposed")
    }
}
